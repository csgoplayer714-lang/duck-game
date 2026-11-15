-- Equipment, Shop, Skills, Quests/Achievements, Rebirth, Worlds, Daily, Settings, Leaderboards panels.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local Rarity = require(Shared.Rarity)
local WorldData = require(Shared.WorldData)
local RodModelBuilder = require(Shared.RodModelBuilder)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local new = UI.new

local M = {}
local player = Players.LocalPlayer

local function clear(f) for _, c in f:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end

local rodModels = {}
local function rodViewport(parent, rod)
	UI.Sunburst(parent, UDim2.fromOffset(130, 130), UDim2.fromOffset(60, 76), Color3.fromRGB(255, 250, 215), 24, 0.2)
	local vf = new("ViewportFrame", {Parent = parent, Size = UDim2.fromOffset(96, 96), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1, ZIndex = 25,
		Ambient = Color3.fromRGB(170, 170, 190), LightDirection = Vector3.new(-0.5, -1, -0.6)})
	-- build each net once, then reuse copies (rebuilding meshes on every shop open caused hitches)
	if not rodModels[rod.Id] then
		local base = RodModelBuilder.Build(rod, false)
		for _, d in base:GetDescendants() do if d:IsA("ParticleEmitter") or d:IsA("Light") then d:Destroy() end end
		rodModels[rod.Id] = base
	end
	local m = rodModels[rod.Id]:Clone()
	m:PivotTo(CFrame.Angles(math.rad(-35), math.rad(90), 0))
	m.Parent = vf
	local cam = new("Camera", {Parent = vf, FieldOfView = 40})
	vf.CurrentCamera = cam
	local cf, size = m:GetBoundingBox()
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, size.Magnitude * 1.1), cf.Position)
	return vf
end

local function rodStats(rod)
	local long = rod.Special == "steady" or rod.Special == "transcend"
	local parts = {
		string.format("\u{1F340} Luck x%.1f", rod.Luck),
		string.format("\u{1F945} Hoop %.1f", (1.7 + rod.Bar * 10) * 2),
		string.format("\u{1F4CF} Reach %d", math.floor(7 + 5 + (rod.Id - 1) * 0.4 + (if long then 2 else 0) + 0.5)),
		string.format("\u{23F1}\u{FE0F} Swing %.2fs", math.max(0.32, 1.15 * rod.Bite / 3.4)),
		string.format("\u{1F422} Ducks %d%% slower", math.floor((1 - rod.Hook) * 100 + 0.5)),
		"",
	}
	return table.concat(parts, "   ", 1, 3) .. "\n" .. table.concat(parts, "   ", 4, 6)
end

local function rodList(content, mode)
	local sf = Panels.Scroll(content, 8)
	local function refresh()
		local d = State.Data
		clear(sf)
		local jobs = {}
		for i, rod in Config.Rods do
			local owned = d.rods[tostring(i)]
			if mode == "equip" and not owned then continue end
			table.insert(jobs, function()
			-- gold "pack" card; the equipped net gets the green card
			local cardColor = if d.rod == i then Color3.fromRGB(70, 190, 45) else Color3.fromRGB(240, 170, 20)
			local card = Panels.Card(sf, {Size = UDim2.new(1, -16, 0, 132), LayoutOrder = i, BackgroundColor3 = cardColor})
			local _, title = UI.CardHeader(card, string.upper(rod.Name), 30, nil, 25)
			if rod.Id >= 8 then UI.RarityGradient(title, 10) elseif rod.Id >= 6 then UI.RarityGradient(title, 9) end
			if d.rod == i then
				UI.Label(card, "EQUIPPED!", UDim2.fromOffset(160, 24), UDim2.new(1, -172, 0, 3), {ZIndex = 26, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 255, 140), StrokeTh = 2.5})
			elseif not owned and rod.Rebirth > 0 then
				UI.Label(card, "Rebirth " .. rod.Rebirth .. "+", UDim2.fromOffset(160, 24), UDim2.new(1, -172, 0, 3), {ZIndex = 26, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 90, 90), StrokeTh = 2.5})
			end
			rodViewport(card, rod)
			UI.Label(card, rodStats(rod), UDim2.new(1, -350, 0, 46), UDim2.fromOffset(120, 40), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2})
			if rod.Special then
				UI.Label(card, "\u{2728} " .. Config.RodSpecials[rod.Special], UDim2.new(1, -350, 0, 22), UDim2.fromOffset(120, 94), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 250, 170), StrokeTh = 2})
			end
			local btn
			if d.rod == i then
				btn = UI.Button(card, {Text = "\u{2714} Equipped", Color = UI.C.Yellow, Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 1, -70), Z = 25, Radius = 8})
			elseif owned then
				btn = UI.Button(card, {Text = "Equip", Color = UI.C.Green, Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 1, -70), Z = 25, Radius = 8, OnClick = function()
					local r = State.Request("EquipRod", i); if not r.ok then UI.Toast(r.err or "Failed", "error") end
				end})
			elseif d.rebirths < rod.Rebirth then
				btn = UI.Button(card, {Text = "\u{1F512} Rebirth " .. rod.Rebirth, Color = Color3.fromRGB(120, 110, 105), Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 1, -70), Z = 25, Radius = 8})
			else
				local can = d.coins >= rod.Cost
				btn = UI.Button(card, {Text = "\u{1F4B0} " .. UI.Abbrev(rod.Cost), Color = if can then UI.C.Green else Color3.fromRGB(120, 110, 105), Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 1, -70), Z = 25, Radius = 8, OnClick = function()
					local r = State.Request("BuyRod", i)
					if r.ok then UI.Chime(4, 1); UI.Toast("Bought the " .. rod.Name .. "!", "good") else UI.Toast(r.err or "Failed", "error") end
				end})
			end
			end)
		end
		UI.BuildChunked("rods_" .. mode, jobs)
	end
	return refresh
end

function M.Register()
	---------------------------------------------------------------- Equipment
	local eqRefresh, teamInfo
	Panels.Register({Name = "Equipment", Keys = {"rods", "rod", "skills", "rebirths", "team", "ducks", "discovered"}, Title = "Equipment", Icon = "\u{1F3A3}", Color = UI.C.Blue, Size = UDim2.fromOffset(820, 540),
		Build = function(content)
			teamInfo = UI.Label(content, "", UDim2.new(1, 0, 0, 28), nil, {ZIndex = 24, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
			local holder = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 1, -36), Position = UDim2.fromOffset(0, 36), BackgroundTransparency = 1, ZIndex = 23})
			eqRefresh = rodList(holder, "equip")
		end,
		Refresh = function()
			local d = State.Data
			teamInfo.Text = string.format("Current luck x%.2f  |  Swing %.2fs  |  Reach %d  |  Team power \u{26A1}%s", Stats.Luck(d), Stats.Net(d).Cooldown, math.floor(Stats.Net(d).Reach), UI.Abbrev(Stats.TeamPower(d)))
			eqRefresh()
		end})
	---------------------------------------------------------------- Shop
	local shopRefresh
	Panels.Register({Name = "Shop", Keys = {"rods", "rod", "coins", "rebirths"}, Title = "Net Shop", Icon = "\u{1F6D2}", Color = UI.C.Pink, Size = UDim2.fromOffset(820, 540),
		Build = function(content) shopRefresh = rodList(content, "shop") end,
		Refresh = function() shopRefresh() end})
	for _, k in {"rods", "rod", "coins"} do
		State.On(k, function()
			local c = Panels.Current()
			if c == "Shop" then shopRefresh() elseif c == "Equipment" then Panels.Get("Equipment").Def.Refresh() end
		end)
	end

	---------------------------------------------------------------- Skills
	local skillCols, pointsLabel
	local function refreshSkills()
		local d = State.Data
		pointsLabel.Text = "\u{2B50} Skill Points: " .. d.skillPoints
		local jobs = {}
		for ti, tree in Config.SkillTrees do
			local col = skillCols[ti]
			clear(col.List)
			for si, s in tree.Skills do
				table.insert(jobs, function()
				local lvl = d.skills[s.Key] or 0
				local card = Panels.Card(col.List, {Size = UDim2.new(1, -8, 0, 74), LayoutOrder = si, BackgroundColor3 = UI.Darken(tree.Color, 0.6)})
				UI.Label(card, s.Name, UDim2.new(1, -70, 0, 22), UDim2.fromOffset(8, 4), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
				local pct = s.Per * (s.Scale or 100) * math.max(lvl, 1)
				local desc = string.format(s.Desc, math.floor(s.Per * 100 * (lvl > 0 and lvl or 1) + 0.5))
				UI.Label(card, (lvl > 0 and "" or "Next: ") .. desc, UDim2.new(1, -70, 0, 18), UDim2.fromOffset(8, 28), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Sub})
				-- pips
				local pips = new("Frame", {Parent = card, Size = UDim2.new(1, -76, 0, 10), Position = UDim2.fromOffset(8, 54), BackgroundTransparency = 1, ZIndex = 25})
				UI.List(pips, 3, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
				for p = 1, s.Max do
					local pip = new("Frame", {Parent = pips, Size = UDim2.new(1 / s.Max, -3, 1, 0), BackgroundColor3 = if p <= lvl then tree.Color else UI.C.Dark, LayoutOrder = p, ZIndex = 25})
					UI.Corner(pip, 4)
				end
				if lvl < s.Max then
					local cost = Config.SkillCost(lvl)
					UI.Button(card, {Text = "+" .. (cost > 1 and (" (" .. cost .. ")") or ""), Color = if d.skillPoints >= cost then tree.Color else UI.C.Dark, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -62, 0.5, -28), Z = 26, OnClick = function()
						local r = State.Request("UpgradeSkill", s.Key)
						if r.ok then UI.Chime(2, 1.2) else UI.Toast(r.err or "Failed", "error") end
					end})
				else
					UI.Label(card, "MAX", UDim2.fromOffset(56, 30), UDim2.new(1, -62, 0.5, -15), {ZIndex = 26, TextColor3 = UI.C.Gold})
				end
				end)
			end
		end
		UI.BuildChunked("skills", jobs)
	end
	Panels.Register({Name = "Skills", Keys = {"skills", "skillPoints"}, Title = "Skill Tree", Icon = "\u{2B50}", Color = UI.C.Green, Size = UDim2.fromOffset(900, 560),
		Build = function(content)
			pointsLabel = UI.Label(content, "", UDim2.fromOffset(300, 30), nil, {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
			UI.Button(content, {Text = "Reset (25 \u{1F48E})", Color = UI.C.Card, Size = UDim2.fromOffset(170, 32), Position = UDim2.new(1, -170, 0, 0), Z = 24, OnClick = function()
				local r = State.Request("ResetSkills"); UI.Toast(if r.ok then "Skill points refunded!" else (r.err or "Failed"), if r.ok then "good" else "error")
			end})
			skillCols = {}
			for ti, tree in Config.SkillTrees do
				local col = Panels.Card(content, {Size = UDim2.new(1 / 3, -8, 1, -40), Position = UDim2.new((ti - 1) / 3, 4, 0, 40), BackgroundColor3 = UI.Darken(tree.Color, 0.75)})
				UI.Label(col, tree.Key:upper(), UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 6), {ZIndex = 25, TextColor3 = UI.Lighten(tree.Color, 0.3)})
				local list = new("Frame", {Parent = col, Size = UDim2.new(1, -8, 1, -44), Position = UDim2.fromOffset(4, 40), BackgroundTransparency = 1, ZIndex = 24})
				UI.List(list, 6)
				skillCols[ti] = {List = list}
			end
		end,
		Refresh = refreshSkills})
	State.On("skills", function() if Panels.Current() == "Skills" then refreshSkills() end end)
	State.On("skillPoints", function() if Panels.Current() == "Skills" then refreshSkills() end end)

	---------------------------------------------------------------- Quests + Achievements
	local qBody, qTab = nil, "Quests"
	local function refreshQuests()
		local d = State.Data
		clear(qBody)
		if qTab == "Quests" then
			for i, q in d.quests do
				local t = Config.QuestTemplates[q.t]
				local done = q.prog >= q.goal
				local card = Panels.Card(qBody, {Size = UDim2.new(1, -12, 0, 96), LayoutOrder = i, BackgroundColor3 = if done then UI.Darken(UI.C.Green, 0.55) else UI.C.Card})
				UI.Label(card, string.format(t.Text, q.goal), UDim2.new(1, -230, 0, 30), UDim2.fromOffset(14, 10), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
				local bg = new("Frame", {Parent = card, Size = UDim2.new(1, -240, 0, 22), Position = UDim2.fromOffset(14, 48), BackgroundColor3 = UI.C.Dark, ZIndex = 25})
				UI.Corner(bg, 11)
				local fill = new("Frame", {Parent = bg, Size = UDim2.fromScale(math.clamp(q.prog / q.goal, 0, 1), 1), BackgroundColor3 = UI.C.Orange, ZIndex = 25})
				UI.Corner(fill, 11)
				UI.Label(bg, UI.Abbrev(q.prog) .. " / " .. UI.Abbrev(q.goal), UDim2.new(1, 0, 1, -4), UDim2.fromOffset(0, 2), {ZIndex = 26, Font = UI.Body})
				UI.Label(card, "\u{1F4B0} " .. UI.Abbrev(q.coins) .. "   \u{1F48E} " .. q.gems, UDim2.new(1, -240, 0, 18), UDim2.fromOffset(14, 74), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
				UI.Button(card, {Text = if done then "CLAIM" else "In progress", Color = if done then UI.C.Green else UI.C.Dark, Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 0.5, -28), Z = 26, OnClick = function()
					if not done then return end
					local r = State.Request("ClaimQuest", i)
					if r.ok then UI.Chime(4, 1); UI.Toast("+" .. UI.Abbrev(r.coins) .. " coins, +" .. r.gems .. " gems!", "good") else UI.Toast(r.err or "Failed", "error") end
				end})
			end
		else
			for i, a in Config.Achievements do
				local got = d.achievements[a.Key]
				local v = if a.Stat == "rebirths" then d.rebirths else (d.stats[a.Stat] or 0)
				local card = Panels.Card(qBody, {Size = UDim2.new(1, -12, 0, 60), LayoutOrder = i, BackgroundColor3 = if got then UI.Darken(UI.C.Gold, 0.6) else UI.C.Card})
				UI.Label(card, (if got then "\u{1F3C6} " else "\u{1F512} ") .. a.Name, UDim2.new(0.45, 0, 0, 26), UDim2.fromOffset(12, 6), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
				UI.Label(card, a.Desc, UDim2.new(0.45, 0, 0, 20), UDim2.fromOffset(12, 34), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Sub})
				local prog = if a.Stat == "best" then (if got then "Done" else "Not yet") else (UI.Abbrev(math.min(v, a.Goal)) .. " / " .. UI.Abbrev(a.Goal))
				UI.Label(card, prog, UDim2.new(0.25, 0, 0, 26), UDim2.new(0.5, 0, 0, 17), {ZIndex = 25})
				UI.Label(card, "\u{1F48E} " .. a.Gems, UDim2.new(0.2, -12, 0, 26), UDim2.new(0.8, 0, 0, 17), {ZIndex = 25, TextColor3 = UI.C.Gem, TextXAlignment = Enum.TextXAlignment.Right})
			end
		end
	end
	Panels.Register({Name = "Quests", Title = "Quests", Icon = "\u{1F4DC}", Color = UI.C.Orange, Size = UDim2.fromOffset(820, 540),
		Build = function(content)
			local holder = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1, ZIndex = 23})
			qBody = Panels.Scroll(holder, 8)
			local set = Panels.Tabs(content, {"Quests", "Achievements"}, UI.C.Orange, function(t) qTab = t; if State.Data then refreshQuests() end end)
			set("Quests")
		end,
		Refresh = refreshQuests})
	State.On("quests", function() if Panels.Current() == "Quests" then refreshQuests() end end)
	State.On("achievements", function() if Panels.Current() == "Quests" then refreshQuests() end end)

	---------------------------------------------------------------- Rebirth
	local rebBody
	local function refreshRebirth()
		local d = State.Data
		clear(rebBody)
		local req = Config.RebirthRequirement(d.rebirths)
		local now, nxt = Config.RebirthBonuses(d.rebirths), Config.RebirthBonuses(d.rebirths + 1)
		local reward = Config.RebirthReward(d.rebirths + 1)
		UI.Label(rebBody, "Rebirth " .. d.rebirths .. "  \u{27A1}\u{FE0F}  " .. (d.rebirths + 1), UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 0), {ZIndex = 24, TextColor3 = UI.Lighten(UI.C.Purple, 0.4)})
		local function row(y, text, ok)
			local f = Panels.Card(rebBody, {Size = UDim2.new(0.5, -10, 0, 40), Position = UDim2.fromOffset(0, y), BackgroundColor3 = if ok == nil then UI.C.Card elseif ok then UI.Darken(UI.C.Green, 0.5) else UI.Darken(UI.C.Red, 0.55)})
			UI.Label(f, text, UDim2.new(1, -16, 1, -10), UDim2.fromOffset(8, 5), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
		end
		UI.Label(rebBody, "REQUIREMENTS", UDim2.new(0.5, -10, 0, 24), UDim2.fromOffset(0, 52), {ZIndex = 24, TextColor3 = UI.C.Sub})
		row(80, "\u{1F4B0} " .. UI.Abbrev(d.coins) .. " / " .. UI.Abbrev(req.Coins) .. " coins", d.coins >= req.Coins)
		row(126, "\u{2B06}\u{FE0F} Level " .. d.level .. " / " .. req.Level, d.level >= req.Level)
		UI.Label(rebBody, "YOU WILL LOSE", UDim2.new(0.5, -10, 0, 24), UDim2.fromOffset(0, 176), {ZIndex = 24, TextColor3 = UI.C.Sub})
		row(204, "Coins, fishing sticks & unlocked worlds", nil)
		UI.Label(rebBody, "(You keep ducks, gems, levels and skills!)", UDim2.new(0.5, -10, 0, 20), UDim2.fromOffset(0, 250), {ZIndex = 24, Font = UI.Body, TextColor3 = UI.C.Green})
		-- bonuses
		local b = Panels.Card(rebBody, {Size = UDim2.new(0.5, -10, 0, 270), Position = UDim2.new(0.5, 10, 0, 52), BackgroundColor3 = UI.Darken(UI.C.Purple, 0.55)})
		UI.Label(b, "PERMANENT BONUSES", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 8), {ZIndex = 25})
		local lines = {
			string.format("\u{1F340} Luck  x%.2f \u{2192} x%.2f", now.Luck, nxt.Luck),
			string.format("\u{2694}\u{FE0F} Damage  x%.2f \u{2192} x%.2f", now.Damage, nxt.Damage),
			string.format("\u{1F3A3} Fishing speed  x%.2f \u{2192} x%.2f", now.FishSpeed, nxt.FishSpeed),
			string.format("\u{1F4B0} Coins  x%.2f \u{2192} x%.2f", now.Coins, nxt.Coins),
			string.format("\u{1F381} +%d gems, +%d skill points", reward.Gems, reward.SkillPoints),
		}
		for _, w in WorldData.List do if w.Rebirth == d.rebirths + 1 then table.insert(lines, "\u{1F30D} Unlocks " .. w.Name) end end
		for _, r in Config.Rods do if r.Rebirth == d.rebirths + 1 then table.insert(lines, "\u{1F3A3} Unlocks " .. r.Name) end end
		local DuckData = require(Shared.DuckData)
		for _, rd in DuckData.RebirthDucks do if rd.Req == d.rebirths + 1 then table.insert(lines, "\u{1F986} Unlocks " .. DuckData.List[rd.Id].Name) end end
		for i, l in lines do
			UI.Label(b, l, UDim2.new(1, -20, 0, 24), UDim2.fromOffset(12, 40 + (i - 1) * 30), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
		end
		local can = d.coins >= req.Coins and d.level >= req.Level
		UI.Button(rebBody, {Text = if can then "REBIRTH" else "Not ready yet", IconImage = "rebirth", Color = if can then UI.C.Purple else UI.C.Dark, Size = UDim2.fromOffset(300, 64), Position = UDim2.new(0.5, -150, 1, -70), Z = 25, OnClick = function()
			if not can then return end
			Panels.Open("Confirm", {Title = "Rebirth?", Text = "You'll lose your coins, fishing sticks and unlocked worlds, but gain permanent bonuses. Ducks are kept!", Color = UI.C.Purple,
				OnYes = function()
					local r = State.Request("Rebirth")
					if r.ok then Panels.Close() else UI.Toast(r.err or "Failed", "error") end
				end})
		end})
	end
	Panels.Register({Name = "Rebirth", Keys = {"coins", "rebirths", "level", "discovered"}, Title = "Rebirth", Icon = "\u{267B}\u{FE0F}", Color = UI.C.Purple, Size = UDim2.fromOffset(820, 500),
		Build = function(content) rebBody = content end, Refresh = refreshRebirth})

	-- generic confirm dialog
	local confirmData
	local cTitle, cText, cYes
	Panels.Register({Name = "Confirm", Title = "Are you sure?", Icon = "\u{2753}", Color = UI.C.Purple, Size = UDim2.fromOffset(520, 280),
		Build = function(content)
			cText = UI.Label(content, "", UDim2.new(1, -20, 0, 110), UDim2.fromOffset(10, 0), {ZIndex = 24, Font = UI.Body, TextWrapped = true})
			cYes = UI.Button(content, {Text = "YES", Color = UI.C.Green, Size = UDim2.fromOffset(180, 56), Position = UDim2.new(0.5, -190, 1, -64), Z = 24, OnClick = function()
				if confirmData and confirmData.OnYes then confirmData.OnYes() end
			end})
			UI.Button(content, {Text = "NO", Color = UI.C.Red, Size = UDim2.fromOffset(180, 56), Position = UDim2.new(0.5, 10, 1, -64), Z = 24, OnClick = function() Panels.Close() end})
		end,
		Refresh = function(_, panel, data)
			confirmData = data
			cText.Text = data.Text
		end})

	---------------------------------------------------------------- Worlds
	local wBody
	local function refreshWorlds()
		local d = State.Data
		clear(wBody)
		local here = player:GetAttribute("World") or 1
		local jobs = {}
		for i, w in WorldData.List do
			table.insert(jobs, function()
			local unlocked = d.worlds[tostring(i)]
			local card = Panels.Card(wBody, {LayoutOrder = i, BackgroundColor3 = UI.Darken(w.Accent, if unlocked then 0.45 else 0.75)})
			UI.Gradient(card, UI.Darken(w.Water, 0.3), UI.Darken(w.Ground, 0.6), 90)
			UI.Label(card, w.Name, UDim2.new(1, -16, 0, 30), UDim2.fromOffset(8, 10), {ZIndex = 25})
			local bosses = {}
			for _, bid in WorldData.BossesByWorld[i] do table.insert(bosses, Config.Bosses[bid].Name) end
			UI.Label(card, string.format("Rare odds x%.1f  |  Stats x%s", w.Boost, UI.Abbrev(w.StatMult)), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 44), {ZIndex = 25, Font = UI.Body, TextColor3 = UI.C.Sub})
			UI.Label(card, "Boss: " .. table.concat(bosses, ", "), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 66), {ZIndex = 25, Font = UI.Body, TextColor3 = UI.C.Sub})
			if unlocked then
				UI.Button(card, {Text = if here == i then "You are here" else "Travel", Color = if here == i then UI.C.Dark else UI.C.Teal, Size = UDim2.new(1, -24, 0, 48), Position = UDim2.new(0, 12, 1, -58), Z = 25, OnClick = function()
					if here == i then return end
					local r = State.Request("Travel", i)
					if r.ok then Panels.Close(); UI.Sound("swoosh", 0.8, 0.6) else UI.Toast(r.err or "Failed", "error") end
				end})
			elseif d.rebirths < w.Rebirth then
				UI.Button(card, {Text = "\u{1F512} Rebirth " .. w.Rebirth, Color = UI.C.Dark, Size = UDim2.new(1, -24, 0, 48), Position = UDim2.new(0, 12, 1, -58), Z = 25})
			else
				UI.Button(card, {Text = "\u{1F513} " .. UI.Abbrev(w.Cost), Color = if d.coins >= w.Cost then UI.C.Gold else UI.C.Dark, Size = UDim2.new(1, -24, 0, 48), Position = UDim2.new(0, 12, 1, -58), Z = 25, OnClick = function()
					local r = State.Request("UnlockWorld", i)
					if r.ok then UI.Chime(6, 0.9); UI.Toast(w.Name .. " unlocked!", "good") else UI.Toast(r.err or "Failed", "error") end
				end})
			end
			end)
		end
		UI.BuildChunked("worlds", jobs)
	end
	Panels.Register({Name = "Worlds", Title = "Worlds", Icon = "\u{1F30E}", Color = UI.C.Teal, Size = UDim2.fromOffset(900, 560),
		Build = function(content) wBody = Panels.Grid(content, UDim2.fromOffset(200, 200), 12) end, Refresh = refreshWorlds})
	State.On("worlds", function() if Panels.Current() == "Worlds" then refreshWorlds() end end)
	State.On("coins", function() if Panels.Current() == "Worlds" then refreshWorlds() elseif Panels.Current() == "Rebirth" then refreshRebirth() end end)

	---------------------------------------------------------------- Daily
	local dBody
	local function refreshDaily()
		local d = State.Data
		clear(dBody)
		local since = os.time() - d.daily.last
		local streak = if since > Config.DAILY_RESET then 0 else d.daily.streak
		local today = streak % #Config.Daily + 1
		local ready = since >= Config.DAILY_COOLDOWN
		local row = new("Frame", {Parent = dBody, Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, ZIndex = 23})
		UI.List(row, 8, Enum.FillDirection.Horizontal)
		for i, r in Config.Daily do
			local claimedDay = i < today or (i == today and not ready)
			local c = Panels.Card(row, {Size = UDim2.fromOffset(98, 160), LayoutOrder = i, BackgroundColor3 = if i == today and ready then UI.C.Gold elseif claimedDay then UI.C.Green else UI.C.Card})
			UI.Label(c, "Day " .. i, UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 8), {ZIndex = 25, StrokeTh = 2.5})
			UI.Sunburst(c, UDim2.fromOffset(110, 110), UDim2.fromOffset(49, 68), Color3.fromRGB(255, 250, 215), 24, 0.35)
			UI.Icon(c, if r.Gems then "gem" else "coins", UDim2.fromOffset(64, 64), UDim2.fromOffset(49, 68), {AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 25})
			local txt = {}
			if r.Coins then table.insert(txt, UI.Abbrev(r.Coins * (1 + d.rebirths * 0.5) * d.world) .. " coins") end
			if r.Gems then table.insert(txt, r.Gems .. " gems") end
			UI.Label(c, table.concat(txt, "\n"), UDim2.new(1, -8, 0, 40), UDim2.fromOffset(4, 100), {ZIndex = 25, Font = UI.Body})
			if claimedDay then UI.Label(c, "\u{2714}", UDim2.fromOffset(26, 26), UDim2.new(1, -28, 0, 4), {ZIndex = 26, TextColor3 = Color3.fromRGB(150, 255, 120), StrokeTh = 2.5}) end
		end
		local waitText = ""
		if not ready then
			local left = Config.DAILY_COOLDOWN - since
			waitText = string.format("Next reward in %dh %dm", left // 3600, (left % 3600) // 60)
		end
		UI.Label(dBody, "Streak: " .. streak .. " days   " .. waitText, UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 182), {ZIndex = 24, Font = UI.Body})
		UI.Button(dBody, {Text = if ready then "CLAIM DAY " .. today else "Claimed!", IconImage = "gift", Color = if ready then UI.C.Green else UI.C.Dark, Size = UDim2.fromOffset(280, 60), Position = UDim2.new(0.5, -140, 0, 224), Z = 25, OnClick = function()
			if not ready then return end
			local r = State.Request("ClaimDaily")
			if r.ok then UI.Chime(6, 1); UI.Toast("Day " .. r.day .. " reward claimed!", "good") else UI.Toast(r.err or "Failed", "error") end
		end})
	end
	Panels.Register({Name = "Daily", Title = "Daily Rewards", Icon = "\u{1F381}", Color = UI.C.Gold, Size = UDim2.fromOffset(780, 380),
		Build = function(content) dBody = content end, Refresh = refreshDaily})
	State.On("daily", function() if Panels.Current() == "Daily" then refreshDaily() end end)

	---------------------------------------------------------------- Settings
	local sBody
	local function refreshSettings()
		local d = State.Data
		clear(sBody)
		local function toggle(order, label, key, onChange)
			local c = Panels.Card(sBody, {Size = UDim2.new(1, -12, 0, 56), LayoutOrder = order})
			UI.Label(c, label, UDim2.new(1, -200, 1, -16), UDim2.fromOffset(14, 8), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
			local on = d.settings[key]
			UI.Button(c, {Text = if on then "ON" else "OFF", Color = if on then UI.C.Green else UI.C.Red, Size = UDim2.fromOffset(120, 42), Position = UDim2.new(1, -134, 0.5, -21), Z = 26, OnClick = function()
				d.settings[key] = not on
				State.Request("SetSetting", key, not on)
				if onChange then onChange(not on) end
				refreshSettings()
			end})
		end
		toggle(1, "\u{1F50A} Sound effects", "sfx", function(v) UI.SfxEnabled = v end)
		toggle(2, "\u{1F3B5} Music", "music", function(v) if M.OnMusic then M.OnMusic(v) end end)
		toggle(3, "\u{1F4A8} Low effects (better performance)", "lowFx", function(v) if M.OnLowFx then M.OnLowFx(v) end end)
		-- titles
		local c = Panels.Card(sBody, {Size = UDim2.new(1, -12, 0, 56), LayoutOrder = 4})
		UI.Label(c, "\u{1F3F7}\u{FE0F} Title: " .. (if d.title ~= "" then d.title else "None"), UDim2.new(1, -200, 1, -16), UDim2.fromOffset(14, 8), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
		UI.Button(c, {Text = "Change", Color = UI.C.Pink, Size = UDim2.fromOffset(120, 42), Position = UDim2.new(1, -134, 0.5, -21), Z = 26, OnClick = function()
			local titles = d.pvp.titles
			if #titles == 0 then UI.Toast("Win ranked PvP battles to earn titles!", "info") return end
			local idx = (table.find(titles, d.title) or 0) + 1
			local t = titles[idx] or ""
			local r = State.Request("SetTitle", t)
			if r.ok then d.title = t; refreshSettings() end
		end})
		if State.MemoryOnly then
			local w = Panels.Card(sBody, {Size = UDim2.new(1, -12, 0, 50), LayoutOrder = 5, BackgroundColor3 = UI.Darken(UI.C.Orange, 0.5)})
			UI.Label(w, "\u{26A0}\u{FE0F} Saving is off in this Studio session (enable API access to test saving)", UDim2.new(1, -20, 1, -14), UDim2.fromOffset(10, 7), {ZIndex = 25, Font = UI.Body})
		end
	end
	Panels.Register({Name = "Settings", Title = "Settings", Icon = "\u{2699}\u{FE0F}", Color = UI.C.Card, Size = UDim2.fromOffset(640, 420),
		Build = function(content) sBody = Panels.Scroll(content, 8) end, Refresh = refreshSettings})

	---------------------------------------------------------------- Leaderboards
	local lbBody
	Panels.Register({Name = "Leaderboards", Title = "Leaderboards", Icon = "\u{1F3C6}", Color = UI.C.Orange, Size = UDim2.fromOffset(900, 520),
		Build = function(content) lbBody = content end,
		Refresh = function()
			clear(lbBody)
			local r = State.Request("GetLeaderboards")
			local boards = r.ok and r.boards or {}
			for i, info in {{"Rebirths", "\u{267B}\u{FE0F} Rebirths", UI.C.Purple}, {"Caught", "\u{1F986} Ducks Caught", UI.C.Yellow}, {"PvP", "\u{2694}\u{FE0F} PvP Rating", UI.C.Red}} do
				local col = Panels.Card(lbBody, {Size = UDim2.new(1 / 3, -10, 1, 0), Position = UDim2.new((i - 1) / 3, 5, 0, 0), BackgroundColor3 = UI.Darken(info[3], 0.65)})
				UI.Label(col, info[2], UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 8), {ZIndex = 25})
				local rows = boards[info[1]] or {}
				for j = 1, 10 do
					local row = rows[j]
					UI.Label(col, string.format("#%d  %s", j, row and row.name or "---"), UDim2.new(0.7, -10, 0, 30), UDim2.fromOffset(10, 44 + (j - 1) * 38), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = if j == 1 then UI.C.Gold elseif j == 2 then Color3.fromRGB(220, 225, 235) elseif j == 3 then Color3.fromRGB(230, 150, 80) else UI.C.Text})
					UI.Label(col, row and UI.Abbrev(row.value) or "", UDim2.new(0.3, -10, 0, 30), UDim2.new(0.7, 0, 0, 44 + (j - 1) * 38), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Right})
				end
			end
		end})
end

return M
