-- Boss battles: interactive turn-based fights against the 10 bosses. All resolution happens here.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local DuckData = require(Shared.DuckData)
local Stats = require(Shared.Stats)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.ProgressService)
local Inventory = require(script.Parent.InventoryService)
local Shop = require(script.Parent.ShopService)
local Engine = require(script.Parent.BattleEngine)

local Boss = {}
local battles = {} -- [player] = {id, engine, bossId, last}
local cooldown = {}

function Boss.TeamUnits(d, side, controlled)
	local units = {}
	for i, uid in d.team do
		local rec = d.ducks[uid]
		if rec then
			local duck = DuckData.List[rec.id]
			local s = Stats.DuckBattle(d, rec)
			table.insert(units, {
				Id = side .. i, Name = duck.Name, Side = side, Attack = s.Attack, Health = s.Health, Defense = s.Defense,
				Speed = s.Speed, Crit = s.Crit, Element = duck.Element, Ability = duck.Ability, SpecialMult = s.SpecialMult,
				Controlled = controlled, DuckId = duck.Id, Level = rec.l, Stars = rec.s,
			})
		end
	end
	return units
end

local function endBattle(player, b, won)
	battles[player] = nil
	player:SetAttribute("InBattle", nil)
	local d = DataService.Get(player)
	if not d then return nil end
	local boss = Config.Bosses[b.bossId]
	if not won then
		local c = math.floor(boss.Coins * 0.1)
		Progress.AddCoins(player, c)
		DataService.Push(player, "coins")
		return {won = false, coins = c}
	end
	local key = tostring(boss.Id)
	local first = (d.bossesBeaten[key] or 0) == 0
	d.bossesBeaten[key] = (d.bossesBeaten[key] or 0) + 1
	d.stats.bosses += 1
	if boss.Id == 10 then d.stats.king += 1 end
	local mult = Stats.RewardMult(d)
	local coins = math.floor(boss.Coins * mult)
	local xp = math.floor(boss.XP * (1 + Stats.Skill(d, "rewards")))
	Progress.AddCoins(player, coins)
	Progress.AddGems(player, boss.Gems)
	Progress.AddXP(player, xp)
	d.essence += boss.Essence
	local reward = {won = true, coins = coins, gems = boss.Gems, xp = xp, essence = boss.Essence, first = first}
	-- exclusive duck drop (guaranteed on first clear)
	local drops = DuckData.BossDrops[boss.Id]
	if drops and #drops > 0 then
		local chance = boss.DropChance * (1 + Stats.Skill(d, "bossDrop"))
		if first or math.random() < chance then
			local id = drops[math.random(1, #drops)]
			local uid = Inventory.Grant(player, id)
			reward.duckId = id
			reward.uid = uid
		end
	end
	if first and boss.RodReward then
		if Shop.GrantRod(player, boss.RodReward) then reward.rodId = boss.RodReward end
	end
	Progress.Event(player, "boss")
	Progress.CheckAchievements(player)
	DataService.Push(player, "coins", "gems", "xp", "level", "skillPoints", "essence", "ducks", "team", "discovered", "stats", "bossesBeaten", "quests")
	return reward
end

local function startBoss(player, bossId)
	local d = DataService.Get(player)
	bossId = Net.Int(bossId, 1, #Config.Bosses)
	if not d or not bossId then return {ok = false} end
	local boss = Config.Bosses[bossId]
	if battles[player] or player:GetAttribute("InBattle") then return {ok = false, err = "Already in a battle"} end
	if not d.worlds[tostring(boss.World)] then return {ok = false, err = "Unlock " .. boss.Name .. "'s world first"} end
	-- bosses unlock in order
	if bossId > 1 and (d.bossesBeaten[tostring(bossId - 1)] or 0) == 0 then
		return {ok = false, err = "Defeat " .. Config.Bosses[bossId - 1].Name .. " first"}
	end
	if #d.team == 0 then return {ok = false, err = "Equip at least one duck in your team"} end
	local cd = cooldown[player]
	if cd and os.clock() - cd < Config.BOSS_COOLDOWN then
		return {ok = false, err = "Boss is recovering (" .. math.ceil(Config.BOSS_COOLDOWN - (os.clock() - cd)) .. "s)"}
	end
	cooldown[player] = os.clock()
	local units = Boss.TeamUnits(d, "A", true)
	table.insert(units, {Id = "B1", Name = boss.Name, Side = "B", Attack = boss.Atk, Health = boss.HP, Defense = boss.Def,
		Speed = boss.Spd, Crit = 0.08, Element = boss.Element, IsBoss = true, Attacks = boss.Attacks, BossId = boss.Id})
	local engine = Engine.new(units, {MaxRounds = 40})
	engine.TimeoutWinner = "B"
	local ev = {}
	engine:Advance(ev)
	local id = HttpService:GenerateGUID(false)
	local b = {id = id, engine = engine, bossId = bossId, last = os.clock()}
	battles[player] = b
	player:SetAttribute("InBattle", true)
	local result
	if engine.Over then result = endBattle(player, b, engine.Winner == "A") end
	return {ok = true, battleId = id, bossId = bossId, units = engine:Snapshot(), events = ev,
		waiting = engine.Waiting and engine.Waiting.Id, over = engine.Over, result = result}
end

local function action(player, battleId, act, targetId)
	local b = battles[player]
	if not b or b.id ~= battleId then return {ok = false, err = "No battle"} end
	if act ~= "attack" and act ~= "special" and act ~= "auto" then return {ok = false} end
	if targetId ~= nil and typeof(targetId) ~= "string" then return {ok = false} end
	local engine = b.engine
	local ev, err
	if act == "auto" then
		local u = engine.Waiting
		if not u then return {ok = false} end
		local useSpecial = u.Ability and u.Cd == 0
		ev, err = engine:Act(if useSpecial then "special" else "attack", nil)
	else
		ev, err = engine:Act(act, targetId)
	end
	if not ev then return {ok = false, err = err} end
	b.last = os.clock()
	local result
	if engine.Over then result = endBattle(player, b, engine.Winner == "A") end
	local cds = {}
	for _, u in engine.Units do cds[u.Id] = u.Cd end
	return {ok = true, events = ev, waiting = engine.Waiting and engine.Waiting.Id, over = engine.Over, result = result, cds = cds}
end

local function forfeit(player, battleId)
	local b = battles[player]
	if not b or b.id ~= battleId then return {ok = false} end
	local result = endBattle(player, b, false)
	return {ok = true, result = result}
end

function Boss.Init()
	Net.On("StartBoss", 0.5, 2, startBoss)
	Net.On("BattleAction", 4, 8, action)
	Net.On("Forfeit", 1, 2, forfeit)
	Players.PlayerRemoving:Connect(function(p) battles[p] = nil; cooldown[p] = nil end)
	-- abandon idle battles
	task.spawn(function()
		while true do
			task.wait(15)
			for player, b in battles do
				if os.clock() - b.last > 120 then
					endBattle(player, b, false)
					Net.Fire(player, "BattleAbandoned", {})
				end
			end
		end
	end)
end

return Boss
