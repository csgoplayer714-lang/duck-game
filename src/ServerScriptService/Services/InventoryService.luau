-- Duck inventory: granting (server only), team, training, evolution, releasing, locking.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.ProgressService)

local Inventory = {}

local function countDucks(d)
	local n = 0
	for _ in d.ducks do n += 1 end
	return n
end
Inventory.Count = countDucks

-- Only called by trusted server code (fishing, boss drops). Returns uid or nil if inventory full.
function Inventory.Grant(player, duckId: number)
	local d = DataService.Get(player)
	local duck = DuckData.List[duckId]
	if not d or not duck then return nil end
	local key = tostring(duckId)
	local isNew = d.discovered[key] == nil
	d.discovered[key] = (d.discovered[key] or 0) + 1
	if isNew then
		local before = Stats.CompletedWorlds(d)
		d.stats.species += 1
		d.discovered[key] = nil
		local was = Stats.CompletedWorlds(d)
		d.discovered[key] = 1
		if Stats.CompletedWorlds(d) > was then
			Progress.Notify(player, "\u{1F4D6} " .. require(RS.Shared.WorldData).List[duck.World].Name .. " index complete! Permanent +10% luck!", "good")
		end
	end
	d.stats.best = math.max(d.stats.best, duck.Rarity)
	if countDucks(d) >= Config.MAX_DUCKS then
		Progress.AddCoins(player, duck.SellValue)
		Progress.Notify(player, "Inventory full! " .. duck.Name .. " was sold for " .. duck.SellValue .. " coins.", "warn")
		return nil, isNew
	end
	local uid = "d" .. d.nextUid
	d.nextUid += 1
	d.ducks[uid] = {id = duckId, l = 1, s = 0, lock = duck.Rarity >= 5}
	-- auto-fill empty team slots
	if #d.team < Config.TEAM_SIZE then table.insert(d.team, uid) end
	return uid, isNew
end

local function inCoop(d, uid)
	for _, u in (d.coop and d.coop.ducks or {}) do if u == uid then return true end end
	return false
end

local function inTeam(d, uid)
	return table.find(d.team, uid) ~= nil
end

local function setTeam(player, uids)
	local d = DataService.Get(player)
	if not d or typeof(uids) ~= "table" then return {ok = false} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "Can't change team mid-battle"} end
	local team, seen = {}, {}
	for i = 1, math.min(#uids, Config.TEAM_SIZE) do
		local uid = uids[i]
		if typeof(uid) ~= "string" or not d.ducks[uid] or seen[uid] then return {ok = false, err = "Invalid team"} end
		seen[uid] = true
		table.insert(team, uid)
	end
	d.team = team
	DataService.Push(player, "team")
	return {ok = true}
end

local function toggleTeam(player, uid)
	local d = DataService.Get(player)
	if not d or typeof(uid) ~= "string" or not d.ducks[uid] then return {ok = false} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "Can't change team mid-battle"} end
	local i = table.find(d.team, uid)
	if i then
		table.remove(d.team, i)
	else
		if #d.team >= Config.TEAM_SIZE then return {ok = false, err = "Team is full (3 ducks)"} end
		table.insert(d.team, uid)
	end
	DataService.Push(player, "team")
	return {ok = true}
end

local function autoTeam(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "Can't change team mid-battle"} end
	local list = {}
	for uid, rec in d.ducks do table.insert(list, {uid = uid, p = Stats.DuckPower(d, rec)}) end
	table.sort(list, function(a, b) return a.p > b.p end)
	d.team = {}
	for i = 1, math.min(Config.TEAM_SIZE, #list) do table.insert(d.team, list[i].uid) end
	DataService.Push(player, "team")
	return {ok = true}
end

local function train(player, uid, times)
	local d = DataService.Get(player)
	times = Net.Int(times or 1, 1, 50) or 1
	if not d or typeof(uid) ~= "string" or not d.ducks[uid] then return {ok = false} end
	local rec = d.ducks[uid]
	local duck = DuckData.List[rec.id]
	local done = 0
	for _ = 1, times do
		if rec.l >= DuckData.MAX_LEVEL then break end
		local cost = DuckData.LevelCost(duck, rec.l)
		if d.coins < cost then break end
		d.coins -= cost
		rec.l += 1
		done += 1
		Progress.Event(player, "levelUp")
	end
	if done == 0 then
		return {ok = false, err = if rec.l >= DuckData.MAX_LEVEL then "Max level!" else "Not enough coins"}
	end
	DataService.Push(player, "ducks", "coins", "quests")
	return {ok = true, levels = done}
end

local function evolve(player, uid)
	local d = DataService.Get(player)
	if not d or typeof(uid) ~= "string" or not d.ducks[uid] then return {ok = false} end
	local rec = d.ducks[uid]
	if rec.s >= Config.MAX_STARS then return {ok = false, err = "Already max stars"} end
	local essence = Config.EVOLVE_ESSENCE[rec.s + 1]
	if d.essence < essence then return {ok = false, err = "Need " .. essence .. " Duck Essence (from bosses)"} end
	-- find spare copies: same species, not locked, not in team, not the target
	local spares = {}
	for other, orec in d.ducks do
		if other ~= uid and orec.id == rec.id and not orec.lock and not inTeam(d, other) and not inCoop(d, other) then
			table.insert(spares, other)
			if #spares >= Config.EVOLVE_COPIES then break end
		end
	end
	if #spares < Config.EVOLVE_COPIES then
		return {ok = false, err = "Need " .. Config.EVOLVE_COPIES .. " unlocked spare copies of this duck"}
	end
	for _, s in spares do d.ducks[s] = nil end
	d.essence -= essence
	rec.s += 1
	DataService.Push(player, "ducks", "essence", "team")
	return {ok = true, stars = rec.s}
end

local function release(player, uids)
	local d = DataService.Get(player)
	if not d or typeof(uids) ~= "table" or #uids > 200 then return {ok = false} end
	local total, n = 0, 0
	local seen = {}
	for _, uid in uids do
		local rec = typeof(uid) == "string" and d.ducks[uid]
		if rec and not seen[uid] and not rec.lock and not inTeam(d, uid) and not inCoop(d, uid) then
			seen[uid] = true
			local duck = DuckData.List[rec.id]
			total += math.floor(duck.SellValue * (1 + (rec.l - 1) * 0.1) * (1 + rec.s))
			d.ducks[uid] = nil
			n += 1
		end
	end
	if n == 0 then return {ok = false, err = "Nothing to release (locked, in team or in your coop)"} end
	Progress.AddCoins(player, total)
	DataService.Push(player, "ducks", "coins", "quests")
	return {ok = true, coins = total, count = n}
end

local function setLock(player, uid, locked)
	local d = DataService.Get(player)
	if not d or typeof(uid) ~= "string" or not d.ducks[uid] or typeof(locked) ~= "boolean" then return {ok = false} end
	d.ducks[uid].lock = locked
	DataService.Push(player, "ducks")
	return {ok = true}
end

function Inventory.Init()
	Net.On("SetTeam", 3, 6, setTeam)
	Net.On("ToggleTeam", 6, 10, toggleTeam)
	Net.On("AutoTeam", 1, 3, autoTeam)
	Net.On("Train", 6, 12, train)
	Net.On("Evolve", 2, 4, evolve)
	Net.On("Release", 2, 4, release)
	Net.On("SetLock", 6, 12, setLock)
end

return Inventory
