-- Server-authoritative duck netting with SHARED ponds and a PERSONAL Mom.
-- * Each world's pond holds one set of ducks that every player in that world sees and races for.
--   Spawns are rolled with the luck of a random player who is in that world (more players = more ducks).
-- * Paths are deterministic (Shared.PoolSim), so the server knows exactly where each duck is at any moment.
-- * You wade in and scoop ONE duck; rare ducks can dodge. The moment you grab one, YOUR Mom comes for you.
--   Get out of the water to keep it; if she catches you the duck goes back into the pond for everyone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)
local DuckData = require(Shared.DuckData)
local Stats = require(Shared.Stats)
local PoolSim = require(Shared.PoolSim)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.ProgressService)
local Inventory = require(script.Parent.InventoryService)

local Fishing = {}
local ponds = {} -- [world] = {ducks = {[u] = rec}, respawnAt = {}}
local states = {} -- [player] = {world, lastSwing, lastCatch, carry, mom}
local streaks = {}
local rng = Random.new()
local uidCounter = 0
Fishing.Announce = nil -- set by AnnounceService

local BASE_COUNT = 14
local PER_PLAYER = 4
local MAX_COUNT = 34
local RESPAWN_DELAY = {1.2, 2.6}
local STREAK_TIMEOUT = 40
local LAG_WINDOW = 0.45
local WADE_SLACK = 2.5
local MOM_RATE = 1 / 12
local DODGE_DASH = 0.4

local function now() return workspace:GetServerTimeNow() end

local function public(rec)
	return {u = rec.u, id = rec.id, t0 = rec.t0, life = rec.life, seed = rec.seed, sp = rec.sp, th0 = rec.th0, rn0 = rec.rn0, dir = rec.dir}
end

local function playersIn(world)
	local list = {}
	for p, st in states do
		if st.world == world and p.Parent then table.insert(list, p) end
	end
	return list
end

local function fireWorld(world, ev, payload, except)
	for _, p in playersIn(world) do
		if p ~= except then Net.Fire(p, ev, payload) end
	end
end

local function wanted(world)
	local list = playersIn(world)
	if #list == 0 then return 0 end
	local n = BASE_COUNT + (#list - 1) * PER_PLAYER + (if world == 1 then 2 else 0)
	for _, p in list do
		local d = DataService.Get(p)
		if d then n += Stats.Net(d).Extra end
	end
	return math.min(n, MAX_COUNT)
end

local function pond(world)
	local p = ponds[world]
	if not p then p = {ducks = {}, respawnAt = {}}; ponds[world] = p end
	return p
end

local function newRec(duckId, t, life)
	uidCounter += 1
	return {u = uidCounter, id = duckId, t0 = t, life = life, seed = rng:NextInteger(1, 2 ^ 30), sp = 1}
end

local function spawnDuck(world, t, initial)
	local list = playersIn(world)
	if #list == 0 then return end
	local roller = list[rng:NextInteger(1, #list)]
	local d = DataService.Get(roller)
	if not d then return end
	local tierIndex = Rarity.Roll(rng, Stats.Luck(d), Stats.WorldBoost(d, world), Stats.HighBoost(d))
	local duckId = DuckData.Pick(rng, world, tierIndex, d.rebirths)
	local duck = DuckData.List[duckId]
	local life = PoolSim.LIFE[duck.Rarity] * rng:NextNumber(0.85, 1.15)
	if initial then life *= rng:NextNumber(0.35, 1) end
	local rec = newRec(duckId, t, life)
	pond(world).ducks[rec.u] = rec
	if not initial then
		fireWorld(world, "PoolAdd", public(rec))
		if duck.Rarity >= 9 and Fishing.Announce then Fishing.Announce(roller, duck, "spawn") end
	end
	return rec
end

local function momState(st)
	local m = st.mom
	return {m = m.mode, p = m.pos, t0 = m.t0, from = m.from}
end

local function pondList(world)
	local list = {}
	for _, rec in pond(world).ducks do table.insert(list, public(rec)) end
	return list
end

----------------------------------------------------------------- hunt & pounce: ducks hear you and flee
local function wrapAngle(a)
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- continue a duck's swim from exactly where it is, with a new heading/speed
local function repath(world, rec, t, sp, dir)
	local th, rn = PoolSim.Polar(rec, world, t)
	rec.life = math.max(rec.t0 + rec.life - t, 6)
	rec.t0 = t
	rec.seed = rng:NextInteger(1, 2 ^ 30)
	rec.th0 = th; rec.rn0 = rn; rec.dir = dir; rec.sp = sp
	PoolSim.Forget(rec)
end

local function panic(world, rec, from, t)
	if rec.panicUntil and t < rec.panicUntil then return end
	local duck = DuckData.List[rec.id]
	local r = duck and duck.Rarity or 1
	local th = PoolSim.Polar(rec, world, t)
	local c = PoolSim.Center(world)
	local pth = math.atan2(from.Z - c.Z, from.X - c.X)
	-- swim the other way around the pond from the player
	local dir = if wrapAngle(pth - th) > 0 then -1 else 1
	repath(world, rec, t, PoolSim.PANIC_SPEED[r], dir)
	rec.panicUntil = t + PoolSim.PANIC_TIME
	rec.calmAt = t + PoolSim.PANIC_TIME
	fireWorld(world, "PoolRepath", {rec = public(rec), panic = true})
end
Fishing.Panic = panic

local function listen(t)
	for player, st in states do
		if st.carry or st.fight then continue end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		local world = st.world
		if PoolSim.EdgeDistance(world, hrp.Position) < -3 then continue end
		local v = hrp.AssemblyLinearVelocity
		local loud = Vector3.new(v.X, 0, v.Z).Magnitude > PoolSim.LOUD_SPEED
		local me = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
		for _, rec in pond(world).ducks do
			if rec.panicUntil and t < rec.panicUntil then continue end
			local duck = DuckData.List[rec.id]
			local r = duck and duck.Rarity or 1
			local radius = if loud then PoolSim.FEAR[r] else PoolSim.SNEAK[r]
			if radius <= 0 then continue end
			local p = PoolSim.Pos(rec, world, t)
			if (Vector3.new(p.X, 0, p.Z) - me).Magnitude < radius then panic(world, rec, hrp.Position, t) end
		end
	end
end

----------------------------------------------------------------- net fight (timing ring) for Rare+ ducks
local function fightRound(st, t)
	local f = st.fight
	local r = f.rarity
	f.period = PoolSim.FightPeriod(r)
	f.zone = PoolSim.FIGHT_ZONE[r]
	f.center = rng:NextNumber(110, 320)
	f.start = t + 0.45
	f.deadline = f.start + f.period * 2 + 0.3
	return {round = f.round, rounds = f.rounds, start = f.start, period = f.period, zone = f.zone, center = f.center, duckId = f.id}
end

local function inZone(f, ct)
	for k = 0, 1 do
		local a = f.start + (f.center - f.zone / 2) / 360 * f.period + k * f.period
		local b = f.start + (f.center + f.zone / 2) / 360 * f.period + k * f.period
		if ct >= a - 0.1 and ct <= b + 0.1 then return true end
	end
	return false
end

-- the duck wriggles free right where you stand and bolts
local function fightLost(player, st)
	local f = st.fight
	st.fight = nil
	local t = now()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local world = f.world
	local c = PoolSim.Center(world)
	local rec = newRec(f.id, t, math.max(f.lifeLeft, 15))
	if hrp then
		local dx, dz = hrp.Position.X - c.X, hrp.Position.Z - c.Z
		local th = math.atan2(dz, dx)
		rec.th0 = th
		rec.rn0 = math.clamp(math.sqrt(dx * dx + dz * dz) / math.max(PoolSim.EdgeR(world, th), 1), 0.15, 0.85)
	end
	rec.dir = if rng:NextNumber() < 0.5 then -1 else 1
	rec.sp = PoolSim.PANIC_SPEED[f.rarity]
	rec.panicUntil = t + PoolSim.PANIC_TIME; rec.calmAt = t + PoolSim.PANIC_TIME
	pond(world).ducks[rec.u] = rec
	fireWorld(world, "PoolAdd", public(rec))
	fireWorld(world, "PoolRepath", {rec = public(rec), panic = true})
	st.lastSwing = t
end

local function startCarry(st, f, t)
	st.carry = {id = f.id, u = f.u, t = t, rarity = f.rarity, world = f.world, lifeLeft = f.lifeLeft}
end

local function struggle(player, clickT)
	local st = states[player]
	local f = st and st.fight
	if not f then return {ok = false, err = "Nothing in your net"} end
	local t = now()
	if typeof(clickT) ~= "number" or clickT ~= clickT then return {ok = false} end
	clickT = math.clamp(clickT, t - 0.4, t)
	if clickT < f.start - 0.05 or not inZone(f, clickT) then
		fightLost(player, st)
		return {ok = true, lost = true, duckId = f.id}
	end
	if f.round >= f.rounds then
		st.fight = nil
		startCarry(st, f, t)
		return {ok = true, carry = true, duckId = f.id, momIn = PoolSim.MOM_REACT}
	end
	f.round += 1
	return {ok = true, next = fightRound(st, t)}
end

----------------------------------------------------------------- mom (per player)
local function momPos(st, t)
	local m = st.mom
	if m.mode == "patrol" then return PoolSim.MomPatrol(st.world, t) end
	if m.mode == "return" then
		local p, done = PoolSim.MomReturning(st.world, m.from, m.t0, t)
		if done then m.mode = "patrol" end
		return p
	end
	return m.pos
end

local function momReturn(player, st, t)
	local m = st.mom
	m.from = momPos(st, t)
	m.mode = "return"; m.t0 = t; m.pos = nil
	Net.Fire(player, "MomMode", momState(st))
end

-- the carried duck goes back into its pond (fresh path, same duck) for everyone to see
local function releaseCarry(player, st, why)
	local c = st.carry
	if not c then return end
	st.carry = nil
	local t = now()
	local rec = newRec(c.id, t, math.max(c.lifeLeft, 15))
	pond(c.world).ducks[rec.u] = rec
	fireWorld(c.world, "PoolAdd", public(rec))
	Net.Fire(player, "CarryEnd", {kept = false, why = why, duckId = c.id})
	if st.mom.mode == "chase" then momReturn(player, st, t) end
end

local function enterWorld(player, world)
	local old = states[player]
	if old and old.fight then
		local f = old.fight; old.fight = nil
		local rec = newRec(f.id, now(), math.max(f.lifeLeft, 15))
		pond(f.world).ducks[rec.u] = rec
		fireWorld(f.world, "PoolAdd", public(rec))
	end
	if old and old.carry then releaseCarry(player, old, "world") end
	local st = {world = world, lastSwing = 0, lastCatch = old and old.lastCatch or now(), carry = nil, mom = {mode = "patrol"}}
	states[player] = st
	-- top the pond up immediately for the newcomer
	local p = pond(world)
	local alive = 0
	for _ in p.ducks do alive += 1 end
	local t = now()
	local fresh = {}
	for _ = alive + 1, wanted(world) do
		local rec = spawnDuck(world, t, true)
		if rec then table.insert(fresh, rec) end
	end
	Net.Fire(player, "PoolSet", {world = world, ducks = pondList(world), mom = momState(st)})
	-- players already here just get the extra ducks
	for _, rec in fresh do fireWorld(world, "PoolAdd", public(rec), player) end
	return st
end

local function sync(player)
	local d = DataService.Get(player)
	if not d then return {ok = false, err = "Loading"} end
	local world = player:GetAttribute("World") or 1
	local st = states[player]
	if not st or st.world ~= world then st = enterWorld(player, world) end
	return {ok = true, world = st.world, ducks = pondList(st.world), mom = momState(st),
		carry = st.carry and {duckId = st.carry.id} or nil}
end

----------------------------------------------------------------- rewards (only once you're safely out of the water)
local function grant(player, st, d, c)
	local world = c.world
	local duck = DuckData.List[c.id]
	local tier = Rarity.List[duck.Rarity]
	local rod = Stats.Rod(d)
	local worldMult = 1 + (world - 1) * 0.6
	local streak = (streaks[player] or 0) + 1
	streaks[player] = streak
	st.lastCatch = now()
	local streakBonus = math.min(streak - 1, 25) * 2
	local coins = math.floor(tier.Coins * worldMult * Stats.RewardMult(d) * (if rod.Special == "midas" then 1.25 else 1) * (1 + streakBonus / 100))
	local xp = math.floor(tier.XP * (1 + (world - 1) * 0.3) * (1 + Stats.Skill(d, "rewards")))
	local uid, isNew = Inventory.Grant(player, duck.Id)
	d.stats.caught += 1
	d.stats.escapes = (d.stats.escapes or 0) + 1
	Progress.AddCoins(player, coins)
	Progress.AddXP(player, xp)
	Progress.Event(player, "catch", duck.Rarity)
	Progress.CheckAchievements(player)
	DataService.UpdateLeaderstats(player)
	DataService.Push(player, "ducks", "team", "coins", "xp", "level", "skillPoints", "discovered", "stats", "quests")
	if tier.Announce and Fishing.Announce then Fishing.Announce(player, duck, "catch") end
	Net.Fire(player, "CarryEnd", {kept = true, duckId = duck.Id, uid = uid, coins = coins, xp = xp, isNew = isNew, streak = streak, streakBonus = streakBonus})
end

----------------------------------------------------------------- maintenance loop
local acc = 0
local function maintain(t)
	-- follow world changes
	for _, player in Players:GetPlayers() do
		local d = DataService.Get(player)
		if not d then continue end
		local world = player:GetAttribute("World") or 1
		local st = states[player]
		if (not st or st.world ~= world) and d.worlds[tostring(world)] then enterWorld(player, world) end
		st = states[player]
		if st and (streaks[player] or 0) > 0 and t - st.lastCatch > STREAK_TIMEOUT then
			streaks[player] = 0
			Net.Fire(player, "StreakReset", {})
		end
	end
	-- each pond: expire, respawn, top up; empty worlds are cleared
	for world, p in ponds do
		local want = wanted(world)
		if want == 0 then
			table.clear(p.ducks); table.clear(p.respawnAt)
			continue
		end
		for u, rec in p.ducks do
			if t >= rec.t0 + rec.life then
				p.ducks[u] = nil
				fireWorld(world, "PoolRemove", {u = u, why = "left"})
				table.insert(p.respawnAt, t + rng:NextNumber(RESPAWN_DELAY[1], RESPAWN_DELAY[2]))
			end
		end
		local alive = 0
		for _ in p.ducks do alive += 1 end
		for i = #p.respawnAt, 1, -1 do
			if t >= p.respawnAt[i] then
				table.remove(p.respawnAt, i)
				if alive < want then spawnDuck(world, t, false); alive += 1 end
			end
		end
		local carried = 0
		for _, st in states do if st.carry and st.carry.world == world then carried += 1 end end
		if alive + #p.respawnAt + carried < want then table.insert(p.respawnAt, t + 1) end
	end
end

-- each player's mom: chase + escape check, every frame
local function chase(dt, t)
	for player, st in states do
		local c = st.carry
		if not c then continue end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 or player:GetAttribute("InBattle") then
			releaseCarry(player, st, "lost")
			continue
		end
		local world = st.world
		local edge = PoolSim.EdgeDistance(world, hrp.Position)
		if edge < -40 then
			releaseCarry(player, st, "lost") -- teleported away, not a real escape
			continue
		end
		if edge < -PoolSim.ESCAPE_MARGIN then
			st.carry = nil
			local d = DataService.Get(player)
			if d then grant(player, st, d, c) end
			if st.mom.mode == "chase" then momReturn(player, st, t) end
			continue
		end
		local m = st.mom
		if m.mode ~= "chase" then
			if t - c.t >= PoolSim.MOM_REACT then
				m.pos = momPos(st, t)
				m.mode = "chase"; m.t0 = t; m.from = nil; m.sent = 0
				Net.Fire(player, "MomMode", momState(st))
			end
			continue
		end
		local me = Vector3.new(hrp.Position.X, m.pos.Y, hrp.Position.Z)
		local to = me - m.pos
		local dist = to.Magnitude
		local speed = PoolSim.MomSpeed(c.rarity) * (if dist < 6 then 1.12 else 1)
		if dist > 1e-3 then
			m.pos = PoolSim.Clamp(world, m.pos + to.Unit * math.min(dist, speed * dt), 1.5)
		end
		dist = (me - m.pos).Magnitude
		if dist <= PoolSim.MOM_CATCH and edge > -0.5 then
			local away = (me - m.pos) * Vector3.new(1, 0, 1)
			away = if away.Magnitude > 1e-3 then away.Unit else Vector3.new(0, 0, 1)
			Net.Fire(player, "MomCaught", {from = m.pos, dir = away, duckId = c.id})
			streaks[player] = 0
			releaseCarry(player, st, "mom")
			continue
		end
		if t - (m.sent or 0) >= MOM_RATE then
			m.sent = t
			Net.Fire(player, "MomPos", {p = m.pos, t = t})
		end
	end
end

local listenAcc = 0
local function step(dt)
	local t = now()
	chase(dt, t)
	listenAcc += dt
	if listenAcc >= 0.1 then
		listenAcc = 0
		listen(t)
		for player, st in states do
			if st.fight and t > st.fight.deadline then
				fightLost(player, st)
				Net.Fire(player, "FightLost", {})
			end
		end
		for world, p in ponds do
			for _, rec in p.ducks do
				if rec.calmAt and t >= rec.calmAt then
					rec.calmAt = nil
					repath(world, rec, t, 1, rec.dir)
					fireWorld(world, "PoolRepath", {rec = public(rec)})
				end
			end
		end
	end
	acc += dt
	if acc >= 0.25 then acc = 0; maintain(t) end
end

----------------------------------------------------------------- swinging
local function vec(v)
	return typeof(v) == "Vector3" and v == v and v.Magnitude < 1e6
end

local function swing(player, aim, swingTime)
	local d = DataService.Get(player)
	local st = states[player]
	if not d or not st then return {ok = false} end
	if not vec(aim) or typeof(swingTime) ~= "number" or swingTime ~= swingTime then return {ok = false, err = "Invalid"} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "You're in a battle!"} end
	if st.carry then return {ok = false, err = "You're holding a duck - get out of the water!"} end
	if st.fight then return {ok = false, err = "fighting"} end
	local net = Stats.Net(d)
	local t = now()
	if t - st.lastSwing < net.Cooldown * 0.75 then return {ok = false, err = "cooldown"} end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return {ok = false} end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("RodId") ~= d.rod then return {ok = false, err = "Equip your net first!"} end
	local world = st.world
	local center = PoolSim.Center(world)
	if PoolSim.EdgeDistance(world, hrp.Position) < -WADE_SLACK or math.abs(hrp.Position.Y - center.Y) > 12 then
		return {ok = false, err = "Wade into the pond to catch ducks!"}
	end
	local flatAim = Vector3.new(aim.X, center.Y, aim.Z)
	local flatMe = Vector3.new(hrp.Position.X, center.Y, hrp.Position.Z)
	if (flatAim - flatMe).Magnitude > net.Reach + PoolSim.LUNGE + 3.5 then
		return {ok = false, err = "Too far! Get closer to the ducks."}
	end
	if not PoolSim.InPool(world, flatAim, 0.5) then return {ok = false, err = "Aim at the water!"} end
	st.lastSwing = t
	local ts = math.clamp(swingTime, t - LAG_WINDOW, t)
	-- Calm Waters / slow-duck perks now widen your grab instead of slowing the shared ducks
	local grab = net.Grab * (2 - math.clamp(net.Calm or 1, 0.5, 1)) + 0.7
	local best, bestDist
	for _, rec in pond(world).ducks do
		if PoolSim.Alive(rec, ts) and not (rec.dashUntil and ts < rec.dashUntil) then
			local dist = math.huge
			for _, dt in {-0.08, 0, 0.08} do
				local p = PoolSim.Pos(rec, world, ts + dt)
				dist = math.min(dist, (Vector3.new(p.X, 0, p.Z) - Vector3.new(aim.X, 0, aim.Z)).Magnitude)
			end
			if dist <= grab and (not bestDist or dist < bestDist) then best, bestDist = rec, dist end
		end
	end
	if not best then
		st.lastSwing = t - (net.Cooldown - net.MissCooldown)
		for _, rec in pond(world).ducks do
			local p = PoolSim.Pos(rec, world, t)
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(aim.X, 0, aim.Z)).Magnitude < 7 then panic(world, rec, aim, t) end
		end
		return {ok = true, hit = false}
	end
	local duck = DuckData.List[best.id]
	if rng:NextNumber() < (PoolSim.DODGE[duck.Rarity] or 0) then
		local from = PoolSim.Pos(best, world, t)
		best.seed = rng:NextInteger(1, 2 ^ 30)
		best.life = math.max(best.t0 + best.life - t, 10)
		best.t0 = t
		best.dashUntil = t + DODGE_DASH
		PoolSim.Forget(best)
		fireWorld(world, "PoolDodge", {rec = public(best), from = from})
		st.lastSwing = t - (net.Cooldown - net.MissCooldown)
		return {ok = true, hit = false, dodged = true, duckId = duck.Id}
	end
	local p = pond(world)
	p.ducks[best.u] = nil
	Net.Fire(player, "PoolRemove", {u = best.u, why = "caught"})
	fireWorld(world, "PoolRemove", {u = best.u, why = "taken", by = player.UserId}, player)
	table.insert(p.respawnAt, t + rng:NextNumber(RESPAWN_DELAY[1], RESPAWN_DELAY[2]))
	local f = {id = best.id, u = best.u, rarity = duck.Rarity, world = world, lifeLeft = best.t0 + best.life - t, round = 1, rounds = PoolSim.FIGHT_ROUNDS[duck.Rarity] or 0}
	if f.rounds > 0 then
		st.fight = f
		return {ok = true, hit = true, u = best.u, duckId = duck.Id, fight = fightRound(st, t)}
	end
	startCarry(st, f, t)
	return {ok = true, hit = true, carry = true, u = best.u, duckId = duck.Id, momIn = PoolSim.MOM_REACT}
end

function Fishing.Init()
	Net.On("Swing", 6, 6, swing)
	Net.On("PoolSync", 1, 4, sync)
	Net.On("Struggle", 6, 8, struggle)
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(p)
		local st = states[p]
		if st and st.carry then
			-- the duck swims back for everyone else
			local c = st.carry
			local rec = newRec(c.id, now(), math.max(c.lifeLeft, 15))
			pond(c.world).ducks[rec.u] = rec
			states[p] = nil
			fireWorld(c.world, "PoolAdd", public(rec))
		end
		states[p] = nil; streaks[p] = nil
	end)
end

function Fishing.IsCarrying(player)
	local st = states[player]
	return st ~= nil and st.carry ~= nil
end

Fishing._ponds = ponds
Fishing._states = states
return Fishing
