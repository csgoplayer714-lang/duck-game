-- Coop panel (put ducks in, collect Feathers, buy slots) and Style panel (cosmetics shop / wardrobe).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)
local DuckData = require(Shared.DuckData)
local CoopData = require(Shared.CoopData)
local Cosmetics = require(Shared.Cosmetics)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local new = UI.new

local M = {}
local player = Players.LocalPlayer
local GREY = Color3.fromRGB(120, 110, 105)
local PINK = Color3.fromRGB(255, 190, 210)

local function clear(f) for _, c in f:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end

local function inCoop(d, uid)
	for _, u in d.coop.ducks do if u == uid then return true end end
	return false
end

local function rateOf(rec)
	local duck = DuckData.List[rec.id]
	return duck and CoopData.DuckRate(duck.Rarity, rec.l) or 0
end
local function coinRateOf(rec)
	local duck = DuckData.List[rec.id]
	return duck and CoopData.CoinRate(duck, rec.l) or 0
end
local function r1(n) return UI.Abbrev(math.floor(n * 10 + 0.5) / 10) end
local COIN = "<font color=\"#FFD84A\">\u{1F4B0}"
-- "+2/min  +0.4 coins" style line for one duck
local function perMin(rec)
	return "\u{1FAB6}+" .. r1(rateOf(rec)) .. "  " .. COIN .. "+" .. r1(coinRateOf(rec)) .. "</font> /min"
end

local function duckTile(parent, rec, size, pos)
	local duck = DuckData.List[rec.id]
	local tier = Rarity.List[duck.Rarity]
	local tile = new("Frame", {Parent = parent, Size = size, Position = pos or UDim2.new(), BackgroundColor3 = UI.Darken(tier.Color, 0.15), ZIndex = 25})
	UI.Corner(tile, 8); UI.Stroke(tile, UI.C.Outline, 2.5)
	UI.Sunburst(tile, UDim2.fromScale(1.2, 1.2), nil, UI.Lighten(tier.Color, 0.5), 25, 0.25)
	UI.Viewport(tile, rec.id, {Z = 26})
	return tile
end

---------------------------------------------------------------- Coop panel
local coopUI = {}
local function refreshCoop()
	local d = State.Data
	if not d or not coopUI.slots then return end
	local rate, crate = 0, 0
	for _, uid in d.coop.ducks do local rec = d.ducks[uid]; if rec then rate += rateOf(rec); crate += coinRateOf(rec) end end
	coopUI.rate.Text = "+" .. r1(rate) .. " Feathers  " .. COIN .. "+" .. r1(crate) .. " Coins</font> / min"
	coopUI.feathers.Text = UI.Abbrev(d.feathers)
	coopUI.slotsLbl.Text = string.format("Slots %d / %d", #d.coop.ducks, d.coop.slots)
	local nxt = CoopData.SlotCost[d.coop.slots + 1]
	if nxt then
		coopUI.upgrade.Label.Text = "+1 Slot  \u{1F4B0} " .. UI.Abbrev(nxt)
		UI.SetColor(coopUI.upgrade, if d.coins >= nxt then UI.C.Blue else GREY)
	else
		coopUI.upgrade.Label.Text = "MAX SLOTS"
		UI.SetColor(coopUI.upgrade, GREY)
	end
	-- coop slots
	clear(coopUI.slots)
	local jobs = {}
	for k = 1, d.coop.slots do
		local uid = d.coop.ducks[k]
		local rec = uid and d.ducks[uid]
		table.insert(jobs, function()
			local card = Panels.Card(coopUI.slots, {Size = UDim2.fromOffset(118, 150), LayoutOrder = k, BackgroundColor3 = if rec then Color3.fromRGB(240, 170, 20) else UI.C.Card})
			if rec then
				local duck = DuckData.List[rec.id]
				duckTile(card, rec, UDim2.fromOffset(78, 70), UDim2.fromOffset(20, 6))
				local nm = UI.Label(card, duck.Name, UDim2.new(1, -8, 0, 18), UDim2.fromOffset(4, 78), {ZIndex = 26, StrokeTh = 2})
				UI.RarityGradient(nm, duck.Rarity)
				UI.Label(card, perMin(rec), UDim2.new(1, -8, 0, 16), UDim2.fromOffset(4, 96), {ZIndex = 26, Font = UI.Body, TextColor3 = PINK})
				UI.Button(card, {Text = "Remove", Color = UI.C.Red, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 1, -34), Z = 26, Radius = 6, OnClick = function()
					local r = State.Request("CoopRemove", uid); if not r.ok then UI.Toast(r.err or "Failed", "error") end
				end})
			else
				UI.Icon(card, "coop", UDim2.fromOffset(70, 70), UDim2.fromOffset(24, 18), {ZIndex = 25, ImageTransparency = 0.55})
				UI.Label(card, "Empty nest", UDim2.new(1, -8, 0, 20), UDim2.fromOffset(4, 98), {ZIndex = 26, Font = UI.Body, TextColor3 = UI.C.Sub})
			end
		end)
	end
	-- your ducks, best feather makers first
	clear(coopUI.list)
	local list = {}
	for uid, rec in d.ducks do
		if not inCoop(d, uid) then table.insert(list, {uid = uid, rec = rec, r = rateOf(rec)}) end
	end
	table.sort(list, function(a, b) return a.r > b.r end)
	for n = 1, math.min(#list, 60) do
		local e = list[n]
		table.insert(jobs, function()
			local duck = DuckData.List[e.rec.id]
			local row = Panels.Card(coopUI.list, {Size = UDim2.new(1, -14, 0, 64), LayoutOrder = n, BackgroundColor3 = UI.C.Card})
			duckTile(row, e.rec, UDim2.fromOffset(52, 52), UDim2.fromOffset(6, 6))
			local nm = UI.Label(row, duck.Name .. "  Lv" .. e.rec.l, UDim2.new(1, -190, 0, 22), UDim2.fromOffset(64, 6), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2})
			UI.RarityGradient(nm, duck.Rarity)
			UI.Label(row, Rarity.List[duck.Rarity].Name .. "   " .. perMin(e.rec), UDim2.new(1, -190, 0, 18), UDim2.fromOffset(64, 34), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PINK})
			local full = #d.coop.ducks >= d.coop.slots
			UI.Button(row, {Text = "Add", Color = if full then GREY else UI.C.Green, Size = UDim2.fromOffset(100, 44), Position = UDim2.new(1, -110, 0.5, -22), Z = 26, Radius = 8, OnClick = function()
				local r = State.Request("CoopAdd", e.uid)
				if r.ok then UI.Sound("quack", 1.1, 0.5); UI.Chime(2, 1.1) else UI.Toast(r.err or "Failed", "error") end
			end})
		end)
	end
	if #list == 0 then
		UI.Label(coopUI.list, "Catch more ducks to fill your coop!", UDim2.new(1, -14, 0, 40), nil, {ZIndex = 25, Font = UI.Body, TextColor3 = UI.C.Sub})
	end
	UI.BuildChunked("coop", jobs)
end

local function refreshBank()
	if coopUI.bank then
		coopUI.bank.Text = "\u{1FAB6}" .. UI.Abbrev(player:GetAttribute("FeatherBank") or 0) .. "  " .. COIN .. UI.Abbrev(player:GetAttribute("CoinBank") or 0) .. "</font>"
	end
end

---------------------------------------------------------------- Style panel
local styleUI = {tab = "All"}
local modelCache = {}
local function cosmeticModel(item)
	if modelCache[item.Id] then return modelCache[item.Id]:Clone() end
	local lib = RS.Assets.Meshes:FindFirstChild("Cosmetics")
	lib = lib and lib:FindFirstChild(item.Id)
	if not lib then return nil end
	local m = Instance.new("Model")
	for _, src in lib:GetChildren() do
		local p = src:Clone()
		p.Anchored = true
		local st = Cosmetics.Style[src:GetAttribute("Slot")]
		if st then p.Color = st[1]; p.Material = Enum.Material[st[2]] end
		if p.Material == Enum.Material.Neon then p.Material = Enum.Material.SmoothPlastic end -- neon renders flat in viewports
		p.Parent = m
	end
	modelCache[item.Id] = m
	return m:Clone()
end

local function preview(parent, item)
	if item.Slot == "Trail" then
		local bar = new("Frame", {Parent = parent, Size = UDim2.new(1, -30, 0, 26), Position = UDim2.new(0, 15, 0.5, -13), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 26})
		UI.Corner(bar, 13)
		new("UIGradient", {Parent = bar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 90)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 180, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255))})})
		return
	end
	local m = cosmeticModel(item)
	if not m then return end
	local vf = new("ViewportFrame", {Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 26,
		Ambient = Color3.fromRGB(170, 170, 185), LightDirection = Vector3.new(-0.4, -1, -0.6)})
	m:PivotTo(CFrame.Angles(math.rad(-12), math.rad(if item.Slot == "Back" then 160 else 25), 0))
	m.Parent = vf
	local cam = new("Camera", {Parent = vf, FieldOfView = 35})
	vf.CurrentCamera = cam
	local cf, size = m:GetBoundingBox()
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Magnitude * 0.25, -size.Magnitude * 1.45), cf.Position)
end

local function refreshStyle()
	local d = State.Data
	if not d or not styleUI.grid then return end
	styleUI.feathers.Text = UI.Abbrev(d.feathers)
	clear(styleUI.grid)
	local jobs = {}
	for _, item in Cosmetics.List do
		if styleUI.tab ~= "All" and item.Slot ~= styleUI.tab then continue end
		table.insert(jobs, function()
			local tier = Rarity.List[item.Rarity]
			local owned = d.cosmetics.owned[item.Id]
			local worn = d.cosmetics.equipped[item.Slot] == item.Id
			local card = Panels.Card(styleUI.grid, {Size = UDim2.fromOffset(190, 250), LayoutOrder = item.Order, BackgroundColor3 = if worn then Color3.fromRGB(70, 190, 45) else UI.Darken(tier.Color, 0.25)})
			local stage = new("Frame", {Parent = card, Size = UDim2.new(1, -16, 0, 116), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = UI.Darken(tier.Color, 0.55), ZIndex = 25})
			UI.Corner(stage, 8); UI.Stroke(stage, UI.C.Outline, 2.5)
			UI.Sunburst(stage, UDim2.fromScale(1.1, 1.6), nil, UI.Lighten(tier.Color, 0.4), 25, 0.3)
			preview(stage, item)
			local nm = UI.Label(card, item.Name, UDim2.new(1, -12, 0, 24), UDim2.fromOffset(6, 128), {ZIndex = 26, StrokeTh = 2.5})
			UI.RarityGradient(nm, item.Rarity)
			UI.Label(card, tier.Name .. "  \u{2022}  " .. item.Slot, UDim2.new(1, -12, 0, 16), UDim2.fromOffset(6, 152), {ZIndex = 26, Font = UI.Body, TextColor3 = UI.C.Sub})
			UI.Label(card, item.Desc, UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 168), {ZIndex = 26, Font = UI.Body, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), StrokeTh = 1.5})
			local pos, size = UDim2.new(0, 8, 1, -46), UDim2.new(1, -16, 0, 38)
			if worn then
				UI.Button(card, {Text = "\u{2714} Wearing", Color = UI.C.Yellow, Size = size, Position = pos, Z = 26, Radius = 8, OnClick = function()
					State.Request("CosEquip", item.Id)
				end})
			elseif owned then
				UI.Button(card, {Text = "Wear", Color = UI.C.Green, Size = size, Position = pos, Z = 26, Radius = 8, OnClick = function()
					local r = State.Request("CosEquip", item.Id); if r.ok then UI.Chime(2, 1.2) end
				end})
			else
				local can = d.feathers >= item.Price
				local b = UI.Button(card, {IconImage = "feather", Text = UI.Abbrev(item.Price), Color = if can then UI.C.Green else GREY, Size = size, Position = pos, Z = 26, Radius = 8, OnClick = function()
					local r = State.Request("CosBuy", item.Id)
					if r.ok then UI.Sound("fanfare", 1, 0.5); UI.Toast("You got the " .. item.Name .. "! It's on you now.", "good")
					else UI.Toast(r.err or "Failed", "error") end
				end})
			end
		end)
	end
	UI.BuildChunked("style", jobs)
end

function M.Register()
	Panels.Register({Name = "Coop", Keys = {"coop", "ducks", "feathers", "coins"}, Title = "Duck Coop", IconImage = "coop", Color = UI.C.Orange, Size = UDim2.fromOffset(900, 560),
		Build = function(content)
			-- info bar
			local bar = Panels.Card(content, {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Color3.fromRGB(240, 170, 20)})
			UI.Icon(bar, "feather", UDim2.fromOffset(56, 56), UDim2.fromOffset(6, 4), {ZIndex = 26})
			coopUI.feathers = UI.Label(bar, "0", UDim2.fromOffset(140, 30), UDim2.fromOffset(64, 4), {ZIndex = 26, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1)})
			coopUI.rate = UI.Label(bar, "", UDim2.fromOffset(250, 22), UDim2.fromOffset(64, 36), {ZIndex = 26, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 250, 220)})
			coopUI.bank = UI.Label(bar, "0", UDim2.fromOffset(104, 30), UDim2.fromOffset(316, 17), {ZIndex = 26, TextColor3 = PINK})
			UI.Button(bar, {Text = "Collect", Color = UI.C.Green, Size = UDim2.fromOffset(120, 46), Position = UDim2.fromOffset(424, 9), Z = 26, Radius = 8, OnClick = function()
				local r = State.Request("CoopCollect")
				if r.ok then UI.Sound("coins", 1, 0.7); UI.Chime(5, 1.1); UI.Toast("+" .. UI.Abbrev(r.amount) .. " Feathers & +" .. UI.Abbrev(r.coins or 0) .. " Coins!", "good") else UI.Toast(r.err or "Failed", "warn") end
			end})
			coopUI.slotsLbl = UI.Label(bar, "", UDim2.fromOffset(110, 22), UDim2.fromOffset(554, 4), {ZIndex = 26, Font = UI.Body})
			UI.Button(bar, {Text = "Auto-fill", Color = UI.C.Purple, Size = UDim2.fromOffset(110, 30), Position = UDim2.fromOffset(554, 28), Z = 26, Radius = 6, OnClick = function()
				local r = State.Request("CoopAuto"); if r.ok then UI.Toast("Filled your coop with your best feather makers!", "good") end
			end})
			coopUI.upgrade = UI.Button(bar, {Text = "+1 Slot", Color = UI.C.Blue, Size = UDim2.fromOffset(186, 46), Position = UDim2.new(1, -196, 0, 9), Z = 26, Radius = 8, OnClick = function()
				local r = State.Request("CoopUpgrade")
				if r.ok then UI.Chime(4, 1); UI.Toast("Your coop now has " .. r.slots .. " nests!", "good") else UI.Toast(r.err or "Failed", "error") end
			end})
			-- left: nests, right: your ducks
			UI.Label(content, "IN YOUR COOP", UDim2.fromOffset(300, 24), UDim2.fromOffset(4, 72), {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
			local left = new("Frame", {Parent = content, Size = UDim2.new(0.56, -8, 1, -102), Position = UDim2.fromOffset(0, 100), BackgroundTransparency = 1, ZIndex = 23})
			coopUI.slots = Panels.Grid(left, UDim2.fromOffset(118, 150), 8)
			UI.Label(content, "YOUR DUCKS", UDim2.fromOffset(300, 24), UDim2.new(0.56, 4, 0, 72), {ZIndex = 24, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
			local right = new("Frame", {Parent = content, Size = UDim2.new(0.44, 0, 1, -102), Position = UDim2.new(0.56, 0, 0, 100), BackgroundTransparency = 1, ZIndex = 23})
			coopUI.list = Panels.Scroll(right, 6)
		end,
		Refresh = function() refreshCoop(); refreshBank() end})
	Panels.Register({Name = "Style", Keys = {"cosmetics", "feathers"}, Title = "Style Shop", IconImage = "style", Color = UI.C.Pink, Size = UDim2.fromOffset(900, 560),
		Build = function(content)
			local top = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, ZIndex = 23})
			local tabs = {"All", "Hat", "Face", "Back", "Waist", "Trail"}
			local setTab, tabBar = Panels.Tabs(top, tabs, UI.C.Pink, function(name) styleUI.tab = name; refreshStyle() end)
			for _, b in tabBar:GetChildren() do if b:IsA("GuiButton") then b.Size = UDim2.fromOffset(92, 40) end end
			local pill = new("Frame", {Parent = top, Size = UDim2.fromOffset(190, 40), Position = UDim2.new(1, -190, 0, 0), BackgroundColor3 = UI.C.Dark, ZIndex = 24})
			UI.Corner(pill, 10); UI.Stroke(pill, UI.C.Outline, 3)
			UI.Icon(pill, "feather", UDim2.fromOffset(44, 44), UDim2.fromOffset(-6, -2), {ZIndex = 25})
			styleUI.feathers = UI.Label(pill, "0", UDim2.new(1, -50, 1, -8), UDim2.fromOffset(42, 4), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PINK})
			local holder = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1, ZIndex = 23})
			styleUI.grid = Panels.Grid(holder, UDim2.fromOffset(190, 250), 10)
			setTab("All")
		end,
		Refresh = function() refreshStyle() end})
	for _, k in {"coop", "ducks", "feathers", "coins", "cosmetics"} do
		State.On(k, function()
			local c = Panels.Current()
			if c == "Coop" then refreshCoop(); Panels.MarkFresh("Coop")
			elseif c == "Style" then refreshStyle(); Panels.MarkFresh("Style") end
		end)
	end
	player:GetAttributeChangedSignal("FeatherBank"):Connect(refreshBank)
	player:GetAttributeChangedSignal("CoinBank"):Connect(refreshBank)
end

return M
