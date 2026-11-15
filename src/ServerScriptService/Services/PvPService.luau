-- PvP: 1v1 challenges (ranked/casual), simulated entirely on the server.
-- Balance: team power gaps are compressed (ratio r -> sqrt(r)) so collection matters but isn't absolute.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.ProgressService)
local Engine = require(script.Parent.BattleEngine)
local Boss = require(script.Parent.BossService)

local PvP = {}
local invites = {} -- [target] = {[challengerUserId] = {mode, t}}
local pairCooldown = {} -- ["a:b"] = time

local function pairKey(a, b)
	local x, y = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	return x .. ":" .. y
end

local function awardTitles(player, d)
	local t = Config.PvPTitle(d.pvp.rating)
	if not table.find(d.pvp.titles, t.Name) and t.Min > 0 then
		table.insert(d.pvp.titles, t.Name)
		Progress.Notify(player, "New PvP title unlocked: " .. t.Name .. "!", "title")
	end
end

local function checkSeason(player, d)
	local season = Config.SeasonId()
	if d.pvp.season ~= season then
		local gems = Config.SeasonReward(d.pvp.peak)
		if gems > 0 then
			d.gems += gems
			local t = Config.PvPTitle(d.pvp.peak)
			local title = "Season " .. d.pvp.season .. " " .. t.Name
			if t.Min >= 1250 and not table.find(d.pvp.titles, title) then table.insert(d.pvp.titles, title) end
			task.delay(5, function() Progress.Notify(player, "Season rewards: +" .. gems .. " gems for your peak rating!", "title") end)
		end
		d.pvp.rating = math.floor(Config.PVP_START_RATING + (d.pvp.rating - Config.PVP_START_RATING) / 2)
		d.pvp.peak = d.pvp.rating
		d.pvp.season = season
	end
end

local function challenge(player, targetUserId, mode)
	local d = DataService.Get(player)
	targetUserId = Net.Int(targetUserId, 1, 2 ^ 53)
	if mode ~= "ranked" and mode ~= "casual" then return {ok = false} end
	local target = targetUserId and Players:GetPlayerByUserId(targetUserId)
	if not d or not target or target == player then return {ok = false, err = "Player not found"} end
	local td = DataService.Get(target)
	if not td then return {ok = false} end
	if #d.team == 0 then return {ok = false, err = "Equip a team first"} end
	if player:GetAttribute("InBattle") or target:GetAttribute("InBattle") then return {ok = false, err = "Someone is already battling"} end
	if mode == "ranked" then
		local last = pairCooldown[pairKey(player, target)]
		if last and os.clock() - last < 180 then return {ok = false, err = "Ranked rematch available in " .. math.ceil(180 - (os.clock() - last)) .. "s" } end
	end
	invites[target] = invites[target] or {}
	invites[target][player.UserId] = {mode = mode, t = os.clock()}
	Net.Fire(target, "PvPInvite", {From = player.DisplayName, UserId = player.UserId, Mode = mode,
		Rating = d.pvp.rating, Power = Stats.TeamPower(d)})
	return {ok = true}
end

local function buildTeam(d, side, scale)
	local units = Boss.TeamUnits(d, side, false)
	for _, u in units do
		u.Attack = math.max(1, math.floor(u.Attack * scale))
		u.Health = math.max(1, math.floor(u.Health * scale))
		u.Defense = math.floor(u.Defense * scale)
	end
	return units
end

local function runBattle(a, b, mode)
	local da, db = DataService.Get(a), DataService.Get(b)
	if not da or not db or #da.team == 0 or #db.team == 0 then return end
	a:SetAttribute("InBattle", true); b:SetAttribute("InBattle", true)
	local pa, pb = math.max(1, Stats.TeamPower(da)), math.max(1, Stats.TeamPower(db))
	local geo = math.sqrt(pa * pb)
	local units = buildTeam(da, "A", (geo / pa) ^ 0.5)
	for _, u in buildTeam(db, "B", (geo / pb) ^ 0.5) do table.insert(units, u) end
	local engine = Engine.new(units, {MaxRounds = 30})
	local snapshot = engine:Snapshot()
	local ev = engine:RunAuto()
	local aWon = engine.Winner == "A"
	local changeA, changeB = 0, 0
	if mode == "ranked" then
		pairCooldown[pairKey(a, b)] = os.clock()
		local ra, rb = da.pvp.rating, db.pvp.rating
		local ea = 1 / (1 + 10 ^ ((rb - ra) / 400))
		local sa = if aWon then 1 else 0
		changeA = math.floor(32 * (sa - ea) + 0.5)
		changeB = -changeA
		da.pvp.rating = math.max(0, ra + changeA)
		db.pvp.rating = math.max(0, rb + changeB)
		da.pvp.peak = math.max(da.pvp.peak, da.pvp.rating)
		db.pvp.peak = math.max(db.pvp.peak, db.pvp.rating)
	end
	local winner, loser = if aWon then a else b, if aWon then b else a
	local dw, dl = DataService.Get(winner), DataService.Get(loser)
	dw.stats.pvpWins += 1
	dl.stats.pvpLosses += 1
	dw.pvp.streak += 1
	dw.pvp.bestStreak = math.max(dw.pvp.bestStreak, dw.pvp.streak)
	dl.pvp.streak = 0
	local winCoins = math.floor(150 * (1 + (dw.world - 1) * 0.8) * (if mode == "ranked" then 2 else 1) * (1 + math.min(dw.pvp.streak, 10) * 0.1))
	Progress.AddCoins(winner, winCoins)
	Progress.Event(winner, "pvpWin")
	for _, p in {a, b} do
		local pd = DataService.Get(p)
		awardTitles(p, pd)
		Progress.CheckAchievements(p)
		p:SetAttribute("InBattle", nil)
		DataService.Push(p, "pvp", "stats", "coins", "quests")
	end
	local function payload(side, me, opp, change)
		return {Units = snapshot, Events = ev, Side = side, Mode = mode, Opponent = opp.DisplayName,
			Won = (side == "A") == aWon, RatingChange = change, Rating = DataService.Get(me).pvp.rating,
			Coins = if winner == me then winCoins else 0, Streak = DataService.Get(me).pvp.streak}
	end
	Net.Fire(a, "PvPResult", payload("A", a, b, changeA))
	Net.Fire(b, "PvPResult", payload("B", b, a, changeB))
end

local function respond(player, challengerUserId, accept)
	challengerUserId = Net.Int(challengerUserId, 1, 2 ^ 53)
	local list = invites[player]
	local inv = list and challengerUserId and list[challengerUserId]
	if not inv then return {ok = false, err = "Invite expired"} end
	list[challengerUserId] = nil
	local challenger = Players:GetPlayerByUserId(challengerUserId)
	if not challenger then return {ok = false, err = "Player left"} end
	if os.clock() - inv.t > 30 then return {ok = false, err = "Invite expired"} end
	if accept ~= true then
		Progress.Notify(challenger, player.DisplayName .. " declined your duel.", "warn")
		return {ok = true}
	end
	if challenger:GetAttribute("InBattle") or player:GetAttribute("InBattle") then return {ok = false, err = "Someone is already battling"} end
	task.spawn(runBattle, challenger, player, inv.mode)
	return {ok = true}
end

local function listPlayers(player)
	local out = {}
	for _, p in Players:GetPlayers() do
		local pd = DataService.Get(p)
		if p ~= player and pd then
			table.insert(out, {UserId = p.UserId, Name = p.DisplayName, Rating = pd.pvp.rating, Power = Stats.TeamPower(pd),
				Title = Config.PvPTitle(pd.pvp.rating).Name, Busy = p:GetAttribute("InBattle") == true})
		end
	end
	return {ok = true, players = out}
end

function PvP.Init()
	Net.On("Challenge", 0.5, 2, challenge)
	Net.On("RespondPvP", 1, 3, respond)
	Net.On("ListPvP", 1, 3, listPlayers)
	DataService.Loaded.Event:Connect(function(player, d) checkSeason(player, d) end)
	Players.PlayerRemoving:Connect(function(p) invites[p] = nil end)
end

PvP._runBattle = runBattle
return PvP
