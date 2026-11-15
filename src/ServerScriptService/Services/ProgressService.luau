-- XP & levels, skill tree, quests, achievements, daily rewards and rebirth.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local WorldData = require(Shared.WorldData)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)

local Progress = {}

local function notify(player, text, kind)
	Net.Fire(player, "Notify", {Text = text, Kind = kind or "info"})
end
Progress.Notify = notify

---------------------------------------------------------------- currency
function Progress.AddCoins(player, amount: number, fromEarning: boolean?)
	local d = DataService.Get(player)
	if not d or amount ~= amount then return end
	amount = math.floor(amount)
	d.coins = math.max(0, d.coins + amount)
	if amount > 0 and fromEarning ~= false then
		d.stats.coinsEarned += amount
		Progress.Event(player, "coins", amount)
	end
end
function Progress.AddGems(player, amount: number)
	local d = DataService.Get(player)
	if not d then return end
	d.gems = math.max(0, d.gems + math.floor(amount))
end

---------------------------------------------------------------- XP
function Progress.AddXP(player, amount: number)
	local d = DataService.Get(player)
	if not d then return end
	d.xp += math.floor(amount)
	local leveled = 0
	while d.level < Config.MAX_LEVEL and d.xp >= Config.XPForLevel(d.level) do
		d.xp -= Config.XPForLevel(d.level)
		d.level += 1
		d.skillPoints += 1
		leveled += 1
	end
	if leveled > 0 then
		Net.Fire(player, "LevelUp", {Level = d.level, Points = leveled})
	end
end

---------------------------------------------------------------- quests
local function newQuest(d, exclude)
	local rng = Random.new()
	local idx
	for _ = 1, 20 do
		idx = rng:NextInteger(1, #Config.QuestTemplates)
		if not exclude[idx] then break end
	end
	local t = Config.QuestTemplates[idx]
	local scale = 1 + math.floor(d.level / 10) * 0.5 + d.rebirths * 0.25
	local goal = t.Base
	if t.Type == "catch" or t.Type == "coins" or t.Type == "levelUp" then goal = math.floor(t.Base * scale) end
	if t.Type == "coins" then goal = math.floor(goal * (1 + d.rebirths) * (d.world ^ 1.5)) end
	return {t = idx, goal = goal, prog = 0,
		coins = math.floor(t.Coins * scale * (1 + (d.world - 1) * 0.8)), gems = t.Gems}
end

function Progress.EnsureQuests(d)
	local active = {}
	for _, q in d.quests do if typeof(q) == "table" and Config.QuestTemplates[q.t] then table.insert(active, q) end end
	d.quests = active
	while #d.quests < Config.ACTIVE_QUESTS do
		local ex = {}
		for _, q in d.quests do ex[q.t] = true end
		table.insert(d.quests, newQuest(d, ex))
	end
end

-- Events: catch(rarity), boss, pvpWin, levelUp, coins(amount)
function Progress.Event(player, kind: string, value)
	local d = DataService.Get(player)
	if not d then return end
	local changed = false
	for _, q in d.quests do
		local t = Config.QuestTemplates[q.t]
		if q.prog < q.goal then
			local add = 0
			if t.Type == kind then
				if kind == "coins" then add = value else add = 1 end
			elseif t.Type == "catchRarity" and kind == "catch" and value >= t.Min then
				add = 1
			end
			if add > 0 then
				q.prog = math.min(q.goal, q.prog + add)
				changed = true
				if q.prog >= q.goal then notify(player, "Quest complete! Claim your reward.", "quest") end
			end
		end
	end
	if changed and kind ~= "coins" then DataService.Push(player, "quests") end
end

local function claimQuest(player, index)
	local d = DataService.Get(player)
	index = Net.Int(index, 1, Config.ACTIVE_QUESTS)
	if not d or not index then return {ok = false} end
	local q = d.quests[index]
	if not q or q.prog < q.goal then return {ok = false, err = "Quest not finished"} end
	Progress.AddCoins(player, q.coins, false)
	Progress.AddGems(player, q.gems)
	local ex = {}
	for i, other in d.quests do if i ~= index then ex[other.t] = true end end
	ex[q.t] = true
	d.quests[index] = newQuest(d, ex)
	DataService.Push(player, "quests", "coins", "gems")
	return {ok = true, coins = q.coins, gems = q.gems}
end

---------------------------------------------------------------- achievements
function Progress.CheckAchievements(player)
	local d = DataService.Get(player)
	if not d then return end
	local got = false
	for _, a in Config.Achievements do
		if not d.achievements[a.Key] then
			local v = if a.Stat == "rebirths" then d.rebirths else (d.stats[a.Stat] or 0)
			if v >= a.Goal then
				d.achievements[a.Key] = true
				d.gems += a.Gems
				got = true
				Net.Fire(player, "Achievement", {Name = a.Name, Desc = a.Desc, Gems = a.Gems})
			end
		end
	end
	if got then DataService.Push(player, "achievements", "gems") end
end

---------------------------------------------------------------- skills
local function upgradeSkill(player, key)
	local d = DataService.Get(player)
	key = Net.Str(key, 32)
	local s = key and Config.SkillByKey[key]
	if not d or not s then return {ok = false} end
	local lvl = d.skills[key] or 0
	if lvl >= s.Max then return {ok = false, err = "Max level"} end
	local cost = Config.SkillCost(lvl)
	if d.skillPoints < cost then return {ok = false, err = "Not enough skill points"} end
	d.skillPoints -= cost
	d.skills[key] = lvl + 1
	DataService.Push(player, "skills", "skillPoints")
	return {ok = true}
end

local function resetSkills(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local cost = 25
	if d.gems < cost then return {ok = false, err = "Needs 25 gems"} end
	local refund = 0
	for key, lvl in d.skills do
		for i = 0, lvl - 1 do refund += Config.SkillCost(i) end
	end
	d.gems -= cost
	d.skills = {}
	d.skillPoints += refund
	DataService.Push(player, "skills", "skillPoints", "gems")
	return {ok = true}
end

---------------------------------------------------------------- daily
local function claimDaily(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local now = os.time()
	local since = now - d.daily.last
	if since < Config.DAILY_COOLDOWN then
		return {ok = false, err = "Come back later!", wait = Config.DAILY_COOLDOWN - since}
	end
	if since > Config.DAILY_RESET then d.daily.streak = 0 end
	local day = d.daily.streak % #Config.Daily + 1
	local r = Config.Daily[day]
	local mult = 1 + d.rebirths * 0.5
	if r.Coins then Progress.AddCoins(player, r.Coins * mult * (1 + (d.world - 1)), false) end
	if r.Gems then Progress.AddGems(player, r.Gems) end
	d.daily.streak += 1
	d.daily.last = now
	DataService.Push(player, "daily", "coins", "gems")
	return {ok = true, day = day}
end

---------------------------------------------------------------- rebirth
local function rebirth(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "Finish your battle first"} end
	local req = Config.RebirthRequirement(d.rebirths)
	if d.coins < req.Coins or d.level < req.Level then
		return {ok = false, err = "Requirements not met"}
	end
	local reward = Config.RebirthReward(d.rebirths + 1)
	d.rebirths += 1
	d.stats.rebirths = d.rebirths
	d.coins = 0
	d.rods = {["1"] = true}
	d.rod = 1
	d.worlds = {["1"] = true}
	d.world = 1
	d.gems += reward.Gems
	d.skillPoints += reward.SkillPoints
	-- move to hub
	local char = player.Character
	local hub = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("World_1")
	if char and hub and hub:FindFirstChild("Arrival") then
		char:PivotTo(hub.Arrival.CFrame + Vector3.new(0, 3, 0))
	end
	player:SetAttribute("World", 1)
	DataService.PushAll(player)
	DataService.UpdateLeaderstats(player)
	Progress.CheckAchievements(player)
	Net.FireAll("RebirthFx", {Name = player.DisplayName, Rebirths = d.rebirths, UserId = player.UserId})
	if Progress.OnRebirth then Progress.OnRebirth(player) end
	return {ok = true, rebirths = d.rebirths, gems = reward.Gems}
end

function Progress.Init()
	Net.On("ClaimQuest", 2, 4, claimQuest)
	Net.On("UpgradeSkill", 6, 10, upgradeSkill)
	Net.On("ResetSkills", 0.5, 1, resetSkills)
	Net.On("ClaimDaily", 1, 2, claimDaily)
	Net.On("Rebirth", 0.3, 1, rebirth)
	Net.On("SetSetting", 4, 8, function(player, key, value)
		local d = DataService.Get(player)
		if d and typeof(key) == "string" and typeof(d.settings[key]) == "boolean" and typeof(value) == "boolean" then
			d.settings[key] = value
		end
	end)
	Net.On("SetTitle", 1, 3, function(player, title)
		local d = DataService.Get(player)
		title = Net.Str(title, 60)
		if not d or not title then return {ok = false} end
		if title ~= "" and not table.find(d.pvp.titles, title) then return {ok = false} end
		d.title = title
		player:SetAttribute("Title", title)
		return {ok = true}
	end)
	DataService.Loaded.Event:Connect(function(player, d)
		Progress.EnsureQuests(d)
		player:SetAttribute("Title", d.title)
	end)
end

return Progress
