-- Main heads-up display: currencies, level/XP, luck, menu buttons, bottom fishing bar and team slots.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local WorldData = require(Shared.WorldData)
local DuckData = require(Shared.DuckData)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local new = UI.new

local HUD = {}
HUD.Buttons = {} -- label -> button (the tutorial points at these)
local player = Players.LocalPlayer

local function pill(parent, icon, color, order, width)
	local f = new("Frame", {Parent = parent, Size = UDim2.fromOffset(width or 170, 44), BackgroundColor3 = UI.C.Bg, LayoutOrder = order, ZIndex = 5})
	UI.Corner(f, 10)
	UI.Studs(f, UI.Darken(UI.C.Bg, 0.45), 0.4, 16, 10)
	UI.Stroke(f, UI.C.Outline, 3.5)
	local ic = new("Frame", {Parent = f, Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(-8, -1), BackgroundColor3 = color, ZIndex = 6})
	UI.Corner(ic, 10)
	ic.BackgroundTransparency = 1
	ic.Rotation = -6
	UI.Icon(ic, icon, UDim2.fromScale(1.15, 1.15), UDim2.fromScale(0.5, 0.5), {AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7})
	local t = UI.Label(f, "0", UDim2.new(1, -56, 0, 30), UDim2.fromOffset(48, 7), {ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2})
	return f, t
end

local function bigButton(parent, icon, label, color, order, onClick)
	local holder = new("Frame", {Parent = parent, Size = UDim2.fromOffset(84, 92), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 5})
	-- soft gold glow behind the button while its menu is open
	local glow = new("Frame", {Parent = holder, Name = "ActiveGlow", Size = UDim2.fromOffset(90, 90), Position = UDim2.fromOffset(42, 38), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 225, 90), BackgroundTransparency = 1, ZIndex = 4})
	UI.Corner(glow, 18)
	HUD.Glows = HUD.Glows or {}
	HUD.Glows[label] = glow
	local b = UI.Button(holder, {Icon = "", Text = "", Color = color, Size = UDim2.fromOffset(76, 76), Position = UDim2.fromOffset(4, 0), Radius = 12, StrokeTh = 3.5, Z = 5, OnClick = onClick})
	UI.Sunburst(b, UDim2.fromScale(1.15, 1.15), nil, Color3.new(1, 1, 1), 5, 0.6)
	UI.Icon(b, icon, UDim2.fromScale(1.05, 1.05), UDim2.fromScale(0.5, 0.46), {AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7})
	UI.Label(holder, label, UDim2.new(1, 8, 0, 22), UDim2.new(0, -4, 1, -22), {ZIndex = 8, StrokeTh = 2.5})
	local badge = new("Frame", {Parent = b, Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -16, 0, -8), BackgroundColor3 = UI.C.Red, Visible = false, ZIndex = 9})
	UI.Corner(badge, 12)
	UI.Stroke(badge, Color3.new(1, 1, 1), 2)
	local bl = UI.Label(badge, "!", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1), {ZIndex = 10})
	HUD.Buttons[label] = b
	return b, badge, bl
end

function HUD.Build(screen)
	local root = new("Frame", {Parent = screen, Name = "HUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
	HUD.Root = root

	-- TOP BAR
	local top = new("Frame", {Parent = root, Name = "Top", Size = UDim2.fromOffset(984, 50), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1})
	UI.List(top, 14, Enum.FillDirection.Horizontal)
	local _, coins = pill(top, "coins", UI.C.Gold, 1)
	local _, gems = pill(top, "gem", UI.C.Gem, 2, 130)
	-- level + xp
	local lvl = new("Frame", {Parent = top, Size = UDim2.fromOffset(250, 44), BackgroundColor3 = UI.C.Bg, LayoutOrder = 3, ZIndex = 5})
	UI.Corner(lvl, 10); UI.Studs(lvl, UI.Darken(UI.C.Bg, 0.45), 0.4, 16, 10); UI.Stroke(lvl, UI.C.Outline, 3.5)
	local badge = new("Frame", {Parent = lvl, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(-10, -4), BackgroundColor3 = UI.C.Green, ZIndex = 7})
	UI.Corner(badge, 12); UI.Gradient(badge, UI.Lighten(UI.C.Green, 0.3), UI.Darken(UI.C.Green, 0.15)); UI.Stroke(badge, UI.C.Outline, 3)
	badge.Rotation = -6
	local lvlText = UI.Label(badge, "1", UDim2.fromScale(0.8, 0.6), UDim2.fromScale(0.1, 0.2), {ZIndex = 8, StrokeTh = 2})
	local barBg = new("Frame", {Parent = lvl, Size = UDim2.new(1, -62, 0, 22), Position = UDim2.fromOffset(52, 11), BackgroundColor3 = UI.C.Dark, ZIndex = 6})
	UI.Corner(barBg, 8); UI.Stroke(barBg, UI.C.Outline, 2)
	local bar = new("Frame", {Parent = barBg, Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.C.Green, ZIndex = 6})
	UI.Corner(bar, 8); UI.Gradient(bar, UI.Lighten(UI.C.Green, 0.4), UI.C.Green)
	local xpText = UI.Label(barBg, "0 / 0 XP", UDim2.new(1, -8, 1, -4), UDim2.fromOffset(4, 2), {ZIndex = 7, Font = UI.Body, StrokeTh = 1.5})
	local _, luck = pill(top, "potion", UI.C.Green, 4, 150)
	local _, feathers = pill(top, "feather", UI.C.Pink, 5, 150)

	-- world banner (top-left)
	local worldF = new("Frame", {Parent = root, Size = UDim2.fromOffset(250, 34), Position = UDim2.fromOffset(16, 66), BackgroundColor3 = UI.C.Gold})
	UI.Corner(worldF, 8)
	UI.Gradient(worldF, Color3.fromRGB(255, 236, 120), Color3.fromRGB(242, 160, 18), 90)
	UI.Studs(worldF, Color3.fromRGB(214, 130, 0), 0.4, 16, 8)
	UI.Stroke(worldF, UI.C.Outline, 3)
	UI.Icon(worldF, "portal", UDim2.fromOffset(44, 44), UDim2.new(0, -10, 0.5, 0), {AnchorPoint = Vector2.new(0, 0.5), ZIndex = 3})
	local worldText = UI.Label(worldF, "Carnival Island", UDim2.new(1, -48, 1, -8), UDim2.fromOffset(38, 4), {TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2.5})

	-- SIDE MENUS: five big buttons on each side, hugging the screen edges (mirror images of each other)
	local left = new("Frame", {Parent = root, Name = "Left", Size = UDim2.fromOffset(90, 500), Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1})
	UI.List(left, 8)
	local _, colBadge = bigButton(left, "duck", "Ducks", UI.C.Yellow, 1, function() Panels.Toggle("Collection") end)
	bigButton(left, "net", "Equipment", UI.C.Blue, 2, function() Panels.Toggle("Equipment") end)
	local _, skillBadge, skillBadgeText = bigButton(left, "star", "Skills", UI.C.Green, 3, function() Panels.Toggle("Skills") end)
	local _, questBadge = bigButton(left, "quests", "Quests", UI.C.Orange, 4, function() Panels.Toggle("Quests") end)
	local _, coopBadge = bigButton(left, "coop", "Coop", Color3.fromRGB(230, 150, 70), 5, function()
		-- at the Coop Field this opens your coop; anywhere else it takes you there
		if player:GetAttribute("AtCoop") then Panels.Toggle("Coop") else
			local r = State.Request("GoCoop")
			if not r.ok then UI.Toast(r.err or "Can't go there now", "warn") else UI.Sound("swoosh", 0.8, 0.6) end
		end
	end)
	HUD.CoopBadge = coopBadge

	local right = new("Frame", {Parent = root, Name = "Right", Size = UDim2.fromOffset(90, 500), Position = UDim2.new(1, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1})
	UI.List(right, 8)
	bigButton(right, "basket", "Shop", UI.C.Pink, 1, function() Panels.Toggle("Shop") end)
	bigButton(right, "style", "Style", Color3.fromRGB(255, 120, 200), 2, function() Panels.Toggle("Style") end)
	local _, rebBadge = bigButton(right, "rebirth", "Rebirth", UI.C.Purple, 3, function() Panels.Toggle("Rebirth") end)
	bigButton(right, "swords", "Battle", UI.C.Red, 4, function() Panels.Toggle("Battle") end)
	bigButton(right, "portal", "Worlds", UI.C.Teal, 5, function() Panels.Toggle("Worlds") end)

	-- small top-right buttons
	local tr = new("Frame", {Parent = root, Size = UDim2.fromOffset(200, 50), Position = UDim2.new(1, -16, 0, 10), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1})
	UI.List(tr, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
	local dailyBtn = UI.Button(tr, {IconImage = "gift", Color = UI.C.Gold, Size = UDim2.fromOffset(48, 48), Order = 1, OnClick = function() Panels.Toggle("Daily") end})
	local dailyBadge = new("Frame", {Parent = dailyBtn, Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -12, 0, -6), BackgroundColor3 = UI.C.Red, Visible = false, ZIndex = 9})
	UI.Corner(dailyBadge, 9)
	UI.Button(tr, {IconImage = "trophy", Color = UI.C.Orange, Size = UDim2.fromOffset(48, 48), Order = 2, OnClick = function() Panels.Toggle("Leaderboards") end})
	UI.Button(tr, {IconImage = "gear_blue", Color = UI.C.Card, Size = UDim2.fromOffset(48, 48), Order = 3, OnClick = function() Panels.Toggle("Settings") end})

	-- BOTTOM: team (bottom-left corner) | SWING (centre) | quick buttons (bottom-right corner).
	-- Both corner groups use the same tiles as the side menus so the screen reads as one mirrored layout.
	local bottom = new("Frame", {Parent = root, Name = "Bottom", Size = UDim2.new(1, -16, 0, 124), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1})
	local TILE = 80
	local GROUP_W = 3 * (TILE + 8) + 2 * 6
	local function tile(parent, order, label, color, onClick, iconImage)
		local holder = new("Frame", {Parent = parent, Size = UDim2.fromOffset(TILE + 8, TILE + 24), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 5})
		local b = UI.Button(holder, {IconImage = iconImage, Text = "", Color = color, Size = UDim2.fromOffset(TILE, TILE), Position = UDim2.fromOffset(4, 0), Radius = 12, StrokeTh = 3.5, Z = 5, OnClick = onClick})
		UI.Sunburst(b, UDim2.fromScale(1.15, 1.15), nil, Color3.new(1, 1, 1), 5, 0.6)
		local l = UI.Label(holder, label, UDim2.new(1, 8, 0, 22), UDim2.new(0, -4, 1, -22), {ZIndex = 8, StrokeTh = 2.5})
		HUD.Buttons[label] = b
		return b, l, holder
	end
	local function group(name, anchorX, tagText)
		local g = new("Frame", {Parent = bottom, Name = name, Size = UDim2.fromOffset(GROUP_W, TILE + 40), Position = UDim2.new(anchorX, 0, 1, 0), AnchorPoint = Vector2.new(anchorX, 1), BackgroundTransparency = 1})
		local row = new("Frame", {Parent = g, Name = "Row", Size = UDim2.new(1, 0, 0, TILE + 24), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1})
		UI.List(row, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center)
		-- gold ribbon over the group, like the panel headers
		local tag = new("Frame", {Parent = g, Size = UDim2.fromOffset(124, 26), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Gold, ZIndex = 9})
		UI.Corner(tag, 8); UI.Gradient(tag, Color3.fromRGB(255, 236, 120), Color3.fromRGB(242, 160, 18), 90); UI.Stroke(tag, UI.C.Outline, 2.5)
		UI.Studs(tag, Color3.fromRGB(214, 130, 0), 0.45, 14, 8)
		UI.Label(tag, tagText, UDim2.new(1, -8, 1, -4), UDim2.fromOffset(4, 2), {ZIndex = 10, StrokeTh = 2})
		new("UIScale", {Parent = g})
		return g, row
	end
	local teamF, teamRow = group("Team", 0, "YOUR TEAM")
	local slots = {}
	for k = 1, 3 do
		local b, l = tile(teamRow, k, "Empty", UI.C.Card, function() Panels.Open("Collection", "My Ducks") end, nil)
		local plus = UI.Label(b, "+", UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.2, 0.18), {Name = "Plus", ZIndex = 7, TextColor3 = UI.C.Sub, StrokeTh = 3})
		slots[k] = {Frame = b, Label = l, Plus = plus}
	end
	HUD.TeamFrame = teamF
	-- cast button
	local cast = UI.Button(bottom, {IconImage = "net", Text = "SWING", Color = UI.C.Green, Size = UDim2.fromOffset(220, 80), Position = UDim2.new(0.5, 0, 1, -16), Anchor = Vector2.new(0.5, 1), Radius = 14, StrokeTh = 4})
	cast.Name = "CastButton"
	HUD.CastButton = cast
	local castHint = UI.Label(bottom, "Walk to the pond & grab your net", UDim2.fromOffset(320, 22), UDim2.new(0.5, -160, 0, 0), {Font = UI.Body, StrokeTh = 2.5})
	HUD.CastHint = castHint
	-- quick buttons (mirror of the team group)
	local sc, scRow = group("Quick", 1, "QUICK")
	local rodBtn = tile(scRow, 1, "Net", UI.C.Blue, function() HUD.ToggleRod() end, "net")
	HUD.RodButton = rodBtn
	tile(scRow, 2, "My Ducks", UI.C.Yellow, function() Panels.Open("Collection", "My Ducks") end, "duck")
	tile(scRow, 3, "Auto Team", UI.C.Purple, function()
		local r = State.Request("AutoTeam")
		UI.Toast(if r.ok then "Equipped your strongest ducks!" else (r.err or "Couldn't auto-equip"), if r.ok then "good" else "error")
	end, "team")

	-- toasts
	local toasts = new("Frame", {Parent = screen, Name = "Toasts", Size = UDim2.fromOffset(460, 340), Position = UDim2.new(0.5, 0, 0, 74), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, ZIndex = 40})
	UI.List(toasts, 6)
	UI.SetToastHolder(toasts)

	---------------------------------------------------------------- updates
	local function refreshTop()
		local d = State.Data
		UI.CountTo(coins, d.coins)
		UI.CountTo(gems, d.gems)
		lvlText.Text = tostring(d.level)
		local need = Config.XPForLevel(d.level)
		UI.Tween(bar, 0.3, {Size = UDim2.fromScale(math.clamp(d.xp / need, 0, 1), 1)})
		xpText.Text = UI.Abbrev(d.xp) .. " / " .. UI.Abbrev(need) .. " XP"
		luck.Text = string.format("x%.2f", Stats.Luck(d))
		UI.CountTo(feathers, d.feathers or 0)
		skillBadge.Visible = d.skillPoints > 0
		skillBadgeText.Text = tostring(math.min(d.skillPoints, 99))
		local req = Config.RebirthRequirement(d.rebirths)
		rebBadge.Visible = d.coins >= req.Coins and d.level >= req.Level
		local qdone = false
		for _, q in d.quests do if q.prog >= q.goal then qdone = true end end
		questBadge.Visible = qdone
		dailyBadge.Visible = os.time() - d.daily.last >= Config.DAILY_COOLDOWN
		if HUD.CoopBadge then HUD.CoopBadge.Visible = (player:GetAttribute("FeatherBank") or 0) >= 50 end
	end
	local last = {}
	local function bump(lbl, key, value)
		if last[key] and value > last[key] then
			local sc2 = lbl:FindFirstChildOfClass("UIScale") or new("UIScale", {Parent = lbl})
			sc2.Scale = 1.3
			UI.Tween(sc2, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
			-- floating "+X" popup under the pill
			local pill = lbl.Parent
			local pop = UI.Label(root, "+" .. UI.Abbrev(value - last[key]), UDim2.fromOffset(160, 30),
				UDim2.new(), {ZIndex = 45, TextColor3 = if key == "gems" then UI.C.Gem else UI.C.Gold, StrokeTh = 2.5})
			-- position relative to the pill in root space
			local rs = root.AbsoluteSize
			local rel = (pill.AbsolutePosition - root.AbsolutePosition) / Vector2.new(math.max(rs.X, 1), math.max(rs.Y, 1))
			pop.Position = UDim2.new(rel.X, 20, rel.Y, 46)
			local ps = new("UIScale", {Parent = pop, Scale = 0.4})
			UI.Tween(ps, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
			UI.Tween(pop, 1.1, {Position = pop.Position + UDim2.fromOffset(0, 34)}, Enum.EasingStyle.Quint)
			task.delay(0.7, function() UI.Tween(pop, 0.4, {TextTransparency = 1}) local s = pop:FindFirstChildOfClass("UIStroke") if s then UI.Tween(s, 0.4, {Transparency = 1}) end end)
			task.delay(1.15, function() pop:Destroy() end)
		end
		last[key] = value
	end
	last.coins = State.Data.coins
	last.gems = State.Data.gems
	-- one catch updates ~10 data keys at once: redraw the top bar once per frame, not once per key
	local topQueued = false
	local function queueTop()
		if topQueued then return end
		topQueued = true
		task.defer(function() topQueued = false; refreshTop() end)
	end
	for _, k in {"coins", "gems", "xp", "level", "skillPoints", "quests", "rod", "skills", "rebirths", "daily", "feathers"} do
		State.On(k, function()
			queueTop()
			if k == "coins" then bump(coins, k, State.Data.coins) end
			if k == "gems" then bump(gems, k, State.Data.gems) end
		end)
	end

	local slotSig = {}
	local function refreshTeam()
		local d = State.Data
		for i, s in slots do
			local uid = d.team[i]
			local rec = uid and d.ducks[uid]
			-- only rebuild a slot when its duck actually changed
			local sig = if rec then (uid .. ":" .. rec.id .. ":" .. rec.l) else "empty"
			if slotSig[i] == sig then continue end
			slotSig[i] = sig
			for _, c in s.Frame:GetChildren() do if c:IsA("ViewportFrame") then c:Destroy() end end
			if rec then
				local duck = DuckData.List[rec.id]
				UI.SetColor(s.Frame, UI.Darken(UI.RarityColor(duck.Rarity), 0.1))
				UI.Viewport(s.Frame, rec.id, {Zoom = 1.2, Z = 7})
				s.Plus.Visible = false
				s.Label.Text = "Lv " .. rec.l
				s.Label.TextColor3 = UI.Lighten(UI.RarityColor(duck.Rarity), 0.4)
			else
				UI.SetColor(s.Frame, UI.C.Card)
				s.Plus.Visible = true
				s.Label.Text = "Empty"
				s.Label.TextColor3 = UI.C.Sub
			end
		end
	end
	local teamQueued = false
	local function queueTeam()
		if teamQueued then return end
		teamQueued = true
		task.defer(function() teamQueued = false; refreshTeam() end)
	end
	State.On("team", queueTeam)
	State.On("ducks", queueTeam)

	local function refreshWorld()
		local w = WorldData.List[player:GetAttribute("World") or 1]
		worldText.Text = w.Name
		refreshTop()
	end
	player:GetAttributeChangedSignal("World"):Connect(refreshWorld)
	refreshTop()
	refreshTeam()
	refreshWorld()

	---------------------------------------------------------------- luck event banner
	local ev = new("Frame", {Parent = root, Name = "LuckEvent", Size = UDim2.fromOffset(330, 40), Position = UDim2.new(0.5, 0, 0, 66), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Green, Visible = false})
	UI.Corner(ev, 20)
	local evGrad = UI.Gradient(ev, ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 180, 80)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 255, 140)), ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 80))}), nil, 0)
	UI.Stroke(ev, Color3.fromRGB(20, 80, 30), 3)
	local evText = UI.Label(ev, "", UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), {StrokeTh = 2.5})
	UI.AnimateGradient(evGrad, 0.6)
	---------------------------------------------------------------- catch streak meter
	local streakF = new("Frame", {Parent = bottom, Name = "Streak", Size = UDim2.fromOffset(190, 26), Position = UDim2.new(0.5, 0, 0, -24), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Orange, Visible = false})
	UI.Corner(streakF, 13); UI.Gradient(streakF, UI.Lighten(UI.C.Orange, 0.2), UI.C.Red, 0); UI.Stroke(streakF, UI.Darken(UI.C.Red, 0.5), 2)
	local streakText = UI.Label(streakF, "", UDim2.new(1, -10, 1, -6), UDim2.fromOffset(5, 3), {StrokeTh = 2})
	local streakScale = new("UIScale", {Parent = streakF})
	function HUD.SetStreak(n, bonus)
		if not n or n < 2 then streakF.Visible = false return end
		streakF.Visible = true
		streakText.Text = string.format("\u{1F525} %d streak  +%d%% coins", n, bonus or 0)
		streakScale.Scale = 1.3
		UI.Tween(streakScale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	end
	task.spawn(function()
		while root.Parent do
			local mult = workspace:GetAttribute("LuckEventMult") or 1
			local ends = workspace:GetAttribute("LuckEventEnd") or 0
			local left = ends - workspace:GetServerTimeNow()
			if mult > 1 and left > 0 then
				if not ev.Visible then
					ev.Visible = true
					local s = ev:FindFirstChildOfClass("UIScale") or new("UIScale", {Parent = ev})
					s.Scale = 0.3; UI.Tween(s, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
				end
				evText.Text = string.format("\u{1F340} x%d LUCK EVENT  %d:%02d", mult, left // 60, math.floor(left % 60))
			else
				ev.Visible = false
			end
			luck.Text = string.format("x%.2f", Stats.Luck(State.Data))
			task.wait(0.5)
		end
	end)
	-- pulsing notification badges
	task.spawn(function()
		local badges = {colBadge, skillBadge, questBadge, rebBadge, dailyBadge}
		local scales = {}
		for i, bd in badges do scales[i] = new("UIScale", {Parent = bd}) end
		while root.Parent do
			for i, bd in badges do if bd.Visible then UI.Tween(scales[i], 0.45, {Scale = 1.25}, Enum.EasingStyle.Sine) end end
			task.wait(0.5)
			for i, bd in badges do if bd.Visible then UI.Tween(scales[i], 0.45, {Scale = 1}, Enum.EasingStyle.Sine) end end
			task.wait(0.6)
		end
	end)
	---------------------------------------------------------------- responsive layout (phones / tablets / small windows)
	-- Keeps the HUD clear of Roblox's top-left buttons, the notch, the thumbstick and the jump button.
	local GuiService = game:GetService("GuiService")
	local UIS = game:GetService("UserInputService")
	local gui = screen:FindFirstAncestorOfClass("ScreenGui")
	local topScale = new("UIScale", {Parent = top})
	local leftScale = new("UIScale", {Parent = left})
	local rightScale = new("UIScale", {Parent = right})
	local castScale = new("UIScale", {Parent = cast})
	local rodHome = {Parent = rodBtn.Parent, Size = rodBtn.Size}
	local teamScale = teamF:FindFirstChildOfClass("UIScale")
	local scScale = sc:FindFirstChildOfClass("UIScale")
	local castHome = {Size = cast.Size, Position = cast.Position, Anchor = cast.AnchorPoint}
	HUD.TopY = 66
	-- side menus: one tall column on PC, a compact 2x2 grid on phones (bigger buttons in less height)
	local grids = {}
	for _, col in {left, right} do
		local list = col:FindFirstChildOfClass("UIListLayout")
		local grid = new("UIGridLayout", {Parent = nil, CellSize = UDim2.fromOffset(84, 92), CellPadding = UDim2.fromOffset(8, 8),
			FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = if col == left then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right})
		grids[col] = {list = list, grid = grid}
	end
	local function setGrid(col, on)
		local g = grids[col]
		if on then
			if g.list then g.list.Parent = nil end
			g.grid.Parent = col
			col.Size = UDim2.fromOffset(180, 300)
		else
			g.grid.Parent = nil
			if g.list then g.list.Parent = col end
			col.Size = UDim2.fromOffset(90, 500)
		end
	end
	local function jumpRect(s)
		-- the mobile jump button in OUR logical coordinates (falls back to Roblox's default placement)
		local pg = player:FindFirstChild("PlayerGui")
		local tg = pg and pg:FindFirstChild("TouchGui")
		local jb = tg and tg:FindFirstChild("JumpButton", true)
		local origin = screen.AbsolutePosition
		if jb and jb.AbsoluteSize.X > 0 then
			return (jb.AbsolutePosition - origin) / s, jb.AbsoluteSize / s
		end
		local vp = screen.AbsoluteSize
		local small = math.min(vp.X, vp.Y) <= 500
		local size = if small then 70 else 120
		local pos = if small then Vector2.new(vp.X - 95, vp.Y - 90) else Vector2.new(vp.X - 170, vp.Y - 210)
		return pos / s, Vector2.new(size, size) / s
	end
	function HUD.Layout()
		local sc0 = screen:FindFirstChildOfClass("UIScale")
		local s = if sc0 then sc0.Scale else 1
		local size = screen.AbsoluteSize / s
		if size.X < 10 then return end
		local touch = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or player:GetAttribute("ForceTouchLayout") == true
		-- Roblox top bar: height + where its free space starts on the left
		local tbH, tbL = 58, 130
		pcall(function()
			local r = GuiService.TopbarInset
			if r.Height > 0 then tbH = r.Max.Y; tbL = r.Min.X end
		end)
		-- TopbarInset is in screen space; AbsolutePosition is in inset space (y=0 below the Roblox bar)
		local insetY = 0
		pcall(function() insetY = GuiService:GetGuiInset().Y end)
		local origin = screen.AbsolutePosition + Vector2.new(0, insetY)
		local topL = math.max(0, tbH - origin.Y) / s
		local leftL = math.max(0, tbL - origin.X) / s
		-- top currency bar: centred, shrunk so it never runs into the Roblox buttons or our top-right buttons
		local reserve = math.max(leftL + 12, 190)
		topScale.Scale = math.clamp((size.X - reserve * 2) / 984, 0.5, 1)
		HUD.TopY = math.max(66, topL + 8)
		worldF.Position = UDim2.fromOffset(16, HUD.TopY)
		ev.Position = UDim2.new(0.5, 0, 0, HUD.TopY)
		toasts.Position = UDim2.new(0.5, 0, 0, HUD.TopY + 48)
		local ts = toasts:FindFirstChildOfClass("UIScale") or new("UIScale", {Parent = toasts})
		ts.Scale = if touch then 1.3 else 1
		if touch then
			local jp, js = jumpRect(s)
			-- big SWING button just left of the jump button, net toggle above it (right thumb does everything)
			cast.Parent = root
			cast.AnchorPoint = Vector2.new(1, 1)
			cast.Size = UDim2.fromOffset(230, 100)
			cast.Position = UDim2.fromOffset(jp.X - 14, jp.Y + js.Y)
			rodBtn.Parent = root
			rodBtn.AnchorPoint = Vector2.new(0.5, 1)
			rodBtn.Size = UDim2.fromOffset(84, 84)
			rodBtn.Position = UDim2.fromOffset(jp.X + js.X / 2, jp.Y - 12)
			-- menu columns: shrink to fit between the top bar and the jump button
			setGrid(left, true); setGrid(right, true)
			local availH = (jp.Y - 110) - (HUD.TopY + 46)
			local colScale = math.clamp(availH / 300, 0.6, 1.1)
			leftScale.Scale = colScale; rightScale.Scale = colScale
			left.AnchorPoint = Vector2.new(0, 0); right.AnchorPoint = Vector2.new(1, 0)
			left.Position = UDim2.fromOffset(8, HUD.TopY + 50)
			right.Position = UDim2.new(1, -8, 0, HUD.TopY + 50)
			-- bottom bar: just the team (quick buttons live elsewhere on phones), kept clear of the swing button
			sc.Visible = false
			local tw = teamF.Size.X.Offset
			bottom.Size = UDim2.fromOffset(tw, 124)
			local maxRight = (jp.X - 14 - 230 - 16)
			local cx = math.min(size.X / 2, maxRight - tw / 2)
			bottom.AnchorPoint = Vector2.new(0.5, 1)
			bottom.Position = UDim2.new(0, cx, 1, -10)
			teamScale.Scale = math.clamp((maxRight - 20) / tw, 0.7, 1)
			castHint.Parent = root
			castHint.Position = UDim2.fromOffset(jp.X - 14 - 230 / 2 - 160, jp.Y + js.Y - 100 - 28)
		else
			cast.Parent = bottom
			cast.AnchorPoint = castHome.Anchor; cast.Size = castHome.Size; cast.Position = castHome.Position
			rodBtn.Parent = rodHome.Parent; rodBtn.Size = rodHome.Size; rodBtn.AnchorPoint = Vector2.zero; rodBtn.Position = UDim2.fromOffset(4, 0)
			castHint.Parent = bottom; castHint.Position = UDim2.new(0.5, -160, 0, 0)
			sc.Visible = true
			bottom.Size = UDim2.new(1, -16, 0, 124); bottom.AnchorPoint = Vector2.new(0.5, 1); bottom.Position = UDim2.new(0.5, 0, 1, -8)
			-- corner groups shrink together on narrow windows so they never touch the SWING button
			local gs = math.clamp((size.X - 16 - 250) / (2 * teamF.Size.X.Offset), 0.6, 1)
			teamScale.Scale = gs; scScale.Scale = gs
			-- side columns: centred in the space between the top bar and the corner groups, flush to the edges
			setGrid(left, false); setGrid(right, false)
			local top0, bot0 = HUD.TopY + 46, size.Y - 8 - 124 * gs - 8
			local colScale = math.clamp((bot0 - top0) / 500, 0.5, 1)
			leftScale.Scale = colScale; rightScale.Scale = colScale
			left.AnchorPoint = Vector2.new(0, 0.5); right.AnchorPoint = Vector2.new(1, 0.5)
			local cy = (top0 + bot0) / 2
			left.Position = UDim2.new(0, 8, 0, cy); right.Position = UDim2.new(1, -8, 0, cy)
		end
	end
	HUD.Layout()
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() task.defer(HUD.Layout) end)
	UIS.LastInputTypeChanged:Connect(function() task.defer(HUD.Layout) end)
	player:GetAttributeChangedSignal("ForceTouchLayout"):Connect(HUD.Layout) -- Studio: preview the phone layout
	-- the TouchGui appears a moment after spawn; re-place the swing button next to the real jump button
	task.delay(2, HUD.Layout)
	player.CharacterAdded:Connect(function() task.delay(1.5, HUD.Layout) end)

	---------------------------------------------------------------- active-menu highlight
	local PANEL_BUTTON = {Collection = "Ducks", Equipment = "Equipment", Skills = "Skills", Quests = "Quests", Coop = "Coop",
		Shop = "Shop", Style = "Style", Rebirth = "Rebirth", Battle = "Battle", Worlds = "Worlds"}
	Panels.OnChange(function(name)
		local want = name and PANEL_BUTTON[name]
		for label, g in HUD.Glows or {} do
			local on = label == want
			UI.Tween(g, 0.25, {BackgroundTransparency = if on then 0.35 else 1, Size = if on then UDim2.fromOffset(94, 94) else UDim2.fromOffset(80, 80)}, Enum.EasingStyle.Quint)
		end
	end)

	---------------------------------------------------------------- entrance animation
	local function slideIn(frame, from: UDim2, delayT)
		local goal = frame.Position
		frame.Position = goal + from
		task.delay(delayT, function() UI.Tween(frame, 0.7, {Position = goal}, Enum.EasingStyle.Quint) end)
	end
	slideIn(top, UDim2.fromOffset(0, -90), 0.1)
	slideIn(left, UDim2.fromOffset(-140, 0), 0.2)
	slideIn(right, UDim2.fromOffset(140, 0), 0.2)
	slideIn(bottom, UDim2.fromOffset(0, 160), 0.3)
	slideIn(worldF, UDim2.fromOffset(-300, 0), 0.35)
	task.spawn(function()
		while root.Parent do task.wait(30); refreshTop() end
	end)
end

function HUD.ToggleRod()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local equipped = char:FindFirstChildOfClass("Tool")
	if equipped then
		hum:UnequipTools()
	else
		local tool = player.Backpack:FindFirstChildOfClass("Tool")
		if tool then hum:EquipTool(tool) end
	end
end

return HUD
