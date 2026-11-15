-- Duck Collection (owned ducks + species index) and Duck Info panels.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local Rarity = require(Shared.Rarity)
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local WorldData = require(Shared.WorldData)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local new = UI.new

local M = {}
local PAGE = 24

-- Builds a list of UI items a few at a time (about 5 ms per frame) so big grids never freeze the game.
-- Starting a new build cancels the previous one.
local buildToken = 0
local function buildChunked(jobs)
	buildToken += 1
	local my = buildToken
	local RunService = game:GetService("RunService")
	task.spawn(function()
		local i = 1
		while i <= #jobs do
			if my ~= buildToken then return end
			local t0 = os.clock()
			while i <= #jobs and os.clock() - t0 < 0.005 do
				jobs[i]()
				i += 1
			end
			if i <= #jobs then RunService.RenderStepped:Wait() end
		end
	end)
end

local function duckCard(parent, duckId, opts)
	local duck = DuckData.List[duckId]
	local color = Rarity.List[duck.Rarity].Color
	-- rarity-coloured studded tile with a light burst behind the duck (simulator shop style)
	local base = if opts.Hidden then UI.C.Card else UI.Darken(color, 0.12)
	local card = new("TextButton", {Parent = parent, Text = "", AutoButtonColor = false, BackgroundColor3 = base, LayoutOrder = opts.Order or 0, ZIndex = 24})
	UI.Corner(card, 10)
	local g = UI.Gradient(card, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 175)), nil, 90)
	UI.Studs(card, UI.Darken(base, 0.3), 0.5, 18, 10)
	local stroke = UI.Stroke(card, if opts.InTeam then Color3.fromRGB(255, 240, 120) else UI.C.Outline, if opts.InTeam then 4 else 3)
	if not opts.Hidden then UI.Sunburst(card, UDim2.fromScale(1.05, 0.9), UDim2.fromScale(0.5, 0.36), UI.Lighten(color, 0.6), 24, 0.2) end
	if opts.Hidden then
		UI.Viewport(card, duckId, {Size = UDim2.new(1, -8, 0.7, 0), Position = UDim2.fromOffset(4, 4), Silhouette = true, Z = 25})
		UI.Label(card, "???", UDim2.new(1, -8, 0.16, 0), UDim2.new(0, 4, 0.72, 0), {ZIndex = 26, TextColor3 = UI.C.Sub})
	else
		UI.Viewport(card, duckId, {Size = UDim2.new(1, -8, 0.68, 0), Position = UDim2.fromOffset(4, 4), Z = 25})
		UI.Label(card, duck.Name, UDim2.new(1, -8, 0.15, 0), UDim2.new(0, 4, 0.68, 0), {ZIndex = 26, Font = UI.Body})
	end
	local rl = UI.Label(card, duck.RarityName, UDim2.new(1, -8, 0.13, 0), UDim2.new(0, 4, 0.84, 0), {ZIndex = 26, TextColor3 = Color3.new(1, 1, 1), StrokeTh = 2})
	if duck.Rarity >= 7 then UI.RarityGradient(rl, duck.Rarity) end
	if opts.Level then
		UI.Label(card, "Lv" .. opts.Level, UDim2.fromOffset(46, 18), UDim2.fromOffset(6, 4), {ZIndex = 27, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
	end
	if opts.Stars and opts.Stars > 0 then
		UI.Label(card, string.rep("\u{2605}", opts.Stars), UDim2.fromOffset(60, 18), UDim2.new(1, -64, 0, 4), {ZIndex = 27, TextColor3 = UI.C.Gold, TextXAlignment = Enum.TextXAlignment.Right})
	end
	if opts.Locked then UI.Label(card, "\u{1F512}", UDim2.fromOffset(18, 18), UDim2.new(1, -22, 0, 22), {ZIndex = 27, NoStroke = true}) end
	if opts.Count and opts.Count > 0 then
		UI.Label(card, "x" .. opts.Count, UDim2.fromOffset(40, 18), UDim2.new(1, -44, 0, 4), {ZIndex = 27, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Right})
	end
	local sc = new("UIScale", {Parent = card})
	card.MouseEnter:Connect(function() UI.Tween(sc, 0.1, {Scale = 1.05}) end)
	card.MouseLeave:Connect(function() UI.Tween(sc, 0.1, {Scale = 1}) end)
	if opts.OnClick then card.Activated:Connect(function() UI.Sound("click", 1.2, 0.3); opts.OnClick() end) end
	return card
end
M.DuckCard = duckCard

---------------------------------------------------------------- Collection panel
function M.Register()
	local tab = "My Ducks"
	local page = 1
	local indexWorld = 1
	local sortMode = "Rarity"
	local grid, info, pager, controls
	local refresh

	Panels.Register({
		Name = "Collection", Keys = {"ducks", "team", "discovered", "essence"}, Title = "Duck Collection", Icon = "\u{1F986}", Color = UI.C.Yellow, Size = UDim2.fromOffset(860, 560),
		Build = function(content)
			local setTab = Panels.Tabs(content, {"My Ducks", "Index"}, UI.C.Yellow, function(t) tab = t; page = 1; if refresh then refresh() end end)
			info = UI.Label(content, "", UDim2.fromOffset(330, 26), UDim2.new(1, -330, 0, 6), {Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 24})
			controls = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 0, 38), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, ZIndex = 23})
			UI.List(controls, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
			local holder = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 1, -136), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, ZIndex = 23})
			grid = Panels.Grid(holder, UDim2.fromOffset(122, 150), 10)
			pager = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -40), BackgroundTransparency = 1, ZIndex = 23})
			UI.List(pager, 10, Enum.FillDirection.Horizontal)
			M.SetCollectionTab = setTab
		end,
		Refresh = function(_, _, wantTab)
			if wantTab and wantTab ~= tab and M.SetCollectionTab then M.SetCollectionTab(wantTab) return end
			if refresh then refresh() end
		end,
	})
	M.SetCollectionTab("My Ducks")

	local function clear(f) for _, c in f:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end
	local function pagerButtons(total)
		clear(pager)
		local pages = math.max(1, math.ceil(total / PAGE))
		page = math.clamp(page, 1, pages)
		UI.Button(pager, {Text = "<", Color = UI.C.Card, Size = UDim2.fromOffset(48, 36), Order = 1, Z = 24, OnClick = function() page = math.max(1, page - 1); refresh() end})
		UI.Label(pager, page .. " / " .. pages, UDim2.fromOffset(100, 30), nil, {LayoutOrder = 2, ZIndex = 24})
		UI.Button(pager, {Text = ">", Color = UI.C.Card, Size = UDim2.fromOffset(48, 36), Order = 3, Z = 24, OnClick = function() page = math.min(pages, page + 1); refresh() end})
	end

	refresh = function()
		local d = State.Data
		if not d or not grid then return end
		clear(grid); clear(controls)
		if tab == "My Ducks" then
			local list = {}
			for uid, rec in d.ducks do
				table.insert(list, {uid = uid, rec = rec, duck = DuckData.List[rec.id], power = Stats.DuckPower(d, rec)})
			end
			table.sort(list, function(a, b)
				local ta, tb = table.find(d.team, a.uid) ~= nil, table.find(d.team, b.uid) ~= nil
				if ta ~= tb then return ta end
				if sortMode == "Power" then return a.power > b.power end
				if a.duck.Rarity ~= b.duck.Rarity then return a.duck.Rarity > b.duck.Rarity end
				return a.power > b.power
			end)
			info.Text = #list .. " / " .. Config.MAX_DUCKS .. " ducks  |  \u{2728} " .. d.essence .. " Essence"
			UI.Button(controls, {Text = "Sort: " .. sortMode, Color = UI.C.Card, Size = UDim2.fromOffset(150, 34), Order = 1, Z = 24, OnClick = function()
				sortMode = if sortMode == "Rarity" then "Power" else "Rarity"; refresh() end})
			UI.Button(controls, {Text = "Equip Best", IconImage = "team", Color = UI.C.Green, Size = UDim2.fromOffset(150, 34), Order = 2, Z = 24, OnClick = function()
				local r = State.Request("AutoTeam"); if r.ok then UI.Toast("Equipped your strongest ducks!", "good") end end})
			UI.Button(controls, {Text = "Release Commons", Color = UI.C.Red, Size = UDim2.fromOffset(190, 34), Order = 3, Z = 24, OnClick = function()
				local uids = {}
				for uid, rec in d.ducks do
					if DuckData.List[rec.id].Rarity <= 2 and not rec.lock and not table.find(d.team, uid) and #uids < 200 then table.insert(uids, uid) end
				end
				if #uids == 0 then UI.Toast("No unlocked Common/Uncommon ducks to release", "warn") return end
				local r = State.Request("Release", uids)
				if r.ok then UI.Toast("Released " .. r.count .. " ducks for " .. UI.Abbrev(r.coins) .. " coins", "good") else UI.Toast(r.err or "Failed", "error") end
			end})
			pagerButtons(#list)
			local jobs = {}
			for i = (page - 1) * PAGE + 1, math.min(#list, page * PAGE) do
				local e = list[i]
				table.insert(jobs, function()
					duckCard(grid, e.rec.id, {Order = i, Level = e.rec.l, Stars = e.rec.s, Locked = e.rec.lock, InTeam = table.find(d.team, e.uid) ~= nil,
						OnClick = function() Panels.Open("DuckInfo", e.uid) end})
				end)
			end
			buildChunked(jobs)
			if #list == 0 then UI.Label(grid, "No ducks yet - go catch some with your net!", UDim2.fromOffset(300, 40), nil, {ZIndex = 24}) end
		else
			-- Index: per world + exclusives
			local found = 0
			for k in d.discovered do found += 1 end
			info.Text = "Discovered " .. found .. " / " .. DuckData.TOTAL
			for w = 1, #WorldData.List + 1 do
				local label = if w <= #WorldData.List then tostring(w) else "\u{2B50}"
				UI.Button(controls, {Text = label, Color = if indexWorld == w then UI.C.Yellow else UI.C.Card, Size = UDim2.fromOffset(44, 34), Order = w, Z = 24,
					OnClick = function() indexWorld = w; refresh() end})
			end
			local ids = {}
			if indexWorld <= #WorldData.List then
				for r = 1, #Rarity.List do for _, id in DuckData.Pools[indexWorld][r] do table.insert(ids, id) end end
				local have = 0
				for _, id in ids do if d.discovered[tostring(id)] then have += 1 end end
				local done = have >= #ids
				UI.Label(controls, WorldData.List[indexWorld].Name .. "  " .. have .. "/" .. #ids .. (if done then "  \u{2705} +10% luck" else "  (complete: +10% luck)"),
					UDim2.fromOffset(360, 30), nil, {LayoutOrder = 20, ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = if done then UI.C.Green else UI.C.Text})
			else
				for id = DuckData.FISHABLE_COUNT + 1, DuckData.TOTAL do table.insert(ids, id) end
				UI.Label(controls, "Boss & Rebirth Exclusives", UDim2.fromOffset(260, 30), nil, {LayoutOrder = 20, ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left})
			end
			clear(pager)
			local jobs = {}
			for i, id in ids do
				local count = d.discovered[tostring(id)]
				table.insert(jobs, function()
					duckCard(grid, id, {Order = i, Hidden = count == nil, Count = count, OnClick = function()
						if count then Panels.Open("DuckInfo", nil, id) else UI.Toast("Catch this duck to reveal it!", "info") end
					end})
				end)
			end
			buildChunked(jobs)
		end
	end
	-- catching while the panel is open changes ducks+team together: rebuild the grid at most every 0.5s
	local pending = false
	local function queueRefresh()
		if pending or Panels.Current() ~= "Collection" then return end
		pending = true
		task.delay(0.5, function()
			pending = false
			if Panels.Current() == "Collection" then refresh(); Panels.MarkFresh("Collection") end
		end)
	end
	State.On("ducks", queueRefresh)
	State.On("team", queueRefresh)

	---------------------------------------------------------------- Duck info panel
	local infoUid, infoId
	local left, right
	local refreshInfo
	Panels.Register({
		Name = "DuckInfo", Title = "Duck Info", Icon = "\u{1F50E}", Color = UI.C.Yellow, Size = UDim2.fromOffset(820, 520),
		Build = function(content)
			left = Panels.Card(content, {Size = UDim2.new(0, 300, 1, 0)})
			right = new("Frame", {Parent = content, Size = UDim2.new(1, -316, 1, 0), Position = UDim2.fromOffset(316, 0), BackgroundTransparency = 1, ZIndex = 23})
		end,
		Refresh = function(_, _, uid, id)
			infoUid, infoId = uid, id
			refreshInfo()
		end,
	})

	local function statRow(parent, order, icon, name, value, color)
		local f = new("Frame", {Parent = parent, Size = UDim2.new(0.5, -6, 0, 30), BackgroundColor3 = UI.C.Card, LayoutOrder = order, ZIndex = 24})
		UI.Corner(f, 8)
		UI.Label(f, icon .. " " .. name, UDim2.new(0.55, 0, 1, -8), UDim2.fromOffset(8, 4), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color or UI.C.Sub})
		UI.Label(f, value, UDim2.new(0.45, -12, 1, -8), UDim2.new(0.55, 0, 0, 4), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Right})
	end

	refreshInfo = function()
		local d = State.Data
		local rec = infoUid and d.ducks[infoUid]
		if infoUid and not rec then Panels.Open("Collection") return end
		local id = if rec then rec.id else infoId
		local duck = DuckData.List[id]
		if not duck then return end
		local tier = Rarity.List[duck.Rarity]
		for _, c in left:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		for _, c in right:GetChildren() do if c:IsA("GuiObject") or c:IsA("UIListLayout") then c:Destroy() end end
		-- left: viewport with rarity backdrop
		local back = new("Frame", {Parent = left, Size = UDim2.new(1, -16, 0, 300), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = tier.Color, ZIndex = 24})
		UI.Corner(back, 12)
		UI.Gradient(back, UI.Darken(tier.Color, 0.2), UI.Darken(tier.Color, 0.75), 90)
		UI.Viewport(back, id, {Spin = 0.6, Zoom = 1.35, Z = 25})
		local nm = UI.Label(left, duck.Name, UDim2.new(1, -16, 0, 34), UDim2.fromOffset(8, 314), {ZIndex = 25})
		local rl = UI.Label(left, tier.Name .. "  \u{2022}  " .. duck.Element, UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 348), {ZIndex = 25, TextColor3 = UI.Lighten(tier.Color, 0.25)})
		if duck.Rarity >= 9 then local g = UI.RarityGradient(rl, duck.Rarity); UI.AnimateGradient(g) end
		UI.Label(left, duck.Description, UDim2.new(1, -20, 0, 70), UDim2.fromOffset(10, 378), {ZIndex = 25, Font = UI.Body, TextColor3 = UI.C.Sub, TextWrapped = true, NoStroke = true})
		local src = if duck.Source == "boss" then ("Drop: " .. Config.Bosses[duck.SourceReq].Name) elseif duck.Source == "rebirth" then ("Unlocks at Rebirth " .. duck.SourceReq) else ("Found in " .. WorldData.List[duck.World].Name)
		UI.Label(left, src .. "  |  #" .. duck.Id, UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 452), {ZIndex = 25, Font = UI.Body, TextColor3 = UI.C.Sub})

		-- right: stats
		UI.List(right, 8)
		local header = new("Frame", {Parent = right, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 23})
		local s
		if rec then
			s = Stats.DuckBattle(d, rec)
			UI.Label(header, "Level " .. rec.l .. " / " .. DuckData.MAX_LEVEL .. "   " .. string.rep("\u{2605}", rec.s) .. string.rep("\u{2606}", Config.MAX_STARS - rec.s),
				UDim2.new(0.7, 0, 1, 0), nil, {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
			UI.Label(header, "\u{26A1} " .. UI.Abbrev(Stats.DuckPower(d, rec)), UDim2.new(0.3, 0, 1, 0), UDim2.fromScale(0.7, 0), {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Right})
		else
			s = DuckData.StatsAt(duck, 1)
			s.SpecialMult = 1
			UI.Label(header, "Base stats (Level 1)", UDim2.fromScale(1, 1), nil, {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left})
		end
		local grid2 = new("Frame", {Parent = right, Size = UDim2.new(1, 0, 0, 104), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 23})
		new("UIGridLayout", {Parent = grid2, CellSize = UDim2.new(0.5, -5, 0, 30), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder})
		statRow(grid2, 1, "\u{2694}\u{FE0F}", "Attack", UI.Abbrev(s.Attack), UI.C.Red)
		statRow(grid2, 2, "\u{2764}\u{FE0F}", "Health", UI.Abbrev(s.Health), UI.C.Green)
		statRow(grid2, 3, "\u{1F6E1}\u{FE0F}", "Defense", UI.Abbrev(s.Defense), UI.C.Blue)
		statRow(grid2, 4, "\u{1F4A8}", "Speed", tostring(s.Speed), UI.C.Teal)
		statRow(grid2, 5, "\u{1F4A5}", "Crit", string.format("%d%%", math.floor(s.Crit * 100 + 0.5)), UI.C.Orange)
		statRow(grid2, 6, "\u{1F3A3}", "Catch Diff.", string.format("%.1f", duck.CatchDifficulty), UI.C.Purple)
		-- ability
		local ab = Panels.Card(right, {Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 3, BackgroundColor3 = UI.Darken(DuckData.ElementColors[duck.Element], 0.6)})
		UI.Label(ab, "\u{2728} " .. duck.Ability.Name, UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 6), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Lighten(DuckData.ElementColors[duck.Element], 0.3)})
		UI.Label(ab, duck.Ability.Desc .. "  (Cooldown: " .. duck.Ability.Cooldown .. " turns)", UDim2.new(1, -16, 0, 40), UDim2.fromOffset(8, 36), {ZIndex = 25, Font = UI.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, NoStroke = true})
		if not rec then return end
		-- actions
		local row1 = new("Frame", {Parent = right, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 4, ZIndex = 23})
		UI.List(row1, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
		local inTeam = table.find(d.team, infoUid) ~= nil
		UI.Button(row1, {Text = if inTeam then "Unequip" else "Equip", IconImage = "team", Color = if inTeam then UI.C.Orange else UI.C.Green, Size = UDim2.fromOffset(150, 44), Order = 1, Z = 24, OnClick = function()
			local r = State.Request("ToggleTeam", infoUid)
			if not r.ok then UI.Toast(r.err or "Failed", "error") end
		end})
		UI.Button(row1, {Text = if rec.lock then "Unlock" else "Lock", Icon = if rec.lock then "\u{1F513}" else "\u{1F512}", Color = UI.C.Card, Size = UDim2.fromOffset(130, 44), Order = 2, Z = 24, OnClick = function()
			State.Request("SetLock", infoUid, not rec.lock)
		end})
		local sell = math.floor(duck.SellValue * (1 + (rec.l - 1) * 0.1) * (1 + rec.s))
		UI.Button(row1, {Text = "Release (" .. UI.Abbrev(sell) .. ")", Color = UI.C.Red, Size = UDim2.fromOffset(200, 44), Order = 3, Z = 24, OnClick = function()
			if rec.lock then UI.Toast("Unlock this duck first", "warn") return end
			local r = State.Request("Release", {infoUid})
			if r.ok then UI.Toast("Released for " .. UI.Abbrev(r.coins) .. " coins", "good"); Panels.Open("Collection") else UI.Toast(r.err or "Failed", "error") end
		end})
		local row2 = new("Frame", {Parent = right, Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 5, ZIndex = 23})
		UI.List(row2, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
		if rec.l < DuckData.MAX_LEVEL then
			local cost = DuckData.LevelCost(duck, rec.l)
			UI.Button(row2, {Text = "Train +1  \u{1F4B0}" .. UI.Abbrev(cost), Color = UI.C.Blue, Size = UDim2.fromOffset(230, 48), Order = 1, Z = 24, OnClick = function()
				local r = State.Request("Train", infoUid, 1)
				if r.ok then UI.Sound("jump", 1.3, 0.4) else UI.Toast(r.err or "Failed", "error") end
			end})
			UI.Button(row2, {Text = "Train x10", Color = UI.Darken(UI.C.Blue, 0.15), Size = UDim2.fromOffset(130, 48), Order = 2, Z = 24, OnClick = function()
				local r = State.Request("Train", infoUid, 10)
				if r.ok then UI.Toast("+" .. r.levels .. " levels!", "good") else UI.Toast(r.err or "Failed", "error") end
			end})
		end
		if rec.s < Config.MAX_STARS then
			local ess = Config.EVOLVE_ESSENCE[rec.s + 1]
			UI.Button(row2, {Text = "Evolve \u{2B50} (" .. ess .. " \u{2728} + " .. Config.EVOLVE_COPIES .. " copies)", Color = UI.C.Purple, Size = UDim2.fromOffset(300, 48), Order = 3, Z = 24, OnClick = function()
				local r = State.Request("Evolve", infoUid)
				if r.ok then UI.Chime(5, 1); UI.Toast("Evolved to " .. r.stars .. " stars! +25% stats", "good") else UI.Toast(r.err or "Failed", "error") end
			end})
		end
	end
	for _, k in {"ducks", "team", "coins", "essence"} do
		State.On(k, function() if Panels.Current() == "DuckInfo" then refreshInfo() end end)
	end
end

return M
