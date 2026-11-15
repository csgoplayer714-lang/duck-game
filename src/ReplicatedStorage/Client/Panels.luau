-- Panel framework: one modal panel at a time with pop-in animation, backdrop and close button.
local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local new = UI.new

-- def.Keys = data keys a panel shows; reopening skips the rebuild when none of them changed
local function signature(def)
	if not def.Keys then return nil end
	local parts = {}
	for _, k in def.Keys do table.insert(parts, State.KeyVersion[k] or 0) end
	return table.concat(parts, ",")
end

local Lighting = game:GetService("Lighting")
local Panels = {}
local blur
local function getBlur()
	if not blur or not blur.Parent then
		blur = Lighting:FindFirstChild("MenuBlur") or Instance.new("BlurEffect")
		blur.Name = "MenuBlur"
		blur.Size = 0
		blur.Enabled = false
		blur.Parent = Lighting
	end
	return blur
end
local QUINT = Enum.EasingStyle.Quint
local registry = {}
local current
local host, backdrop

function Panels.Init(screen)
	backdrop = new("TextButton", {Parent = screen, Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20})
	backdrop.Activated:Connect(function() Panels.Close() end)
	host = new("Frame", {Parent = screen, Name = "PanelHost", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 21})
	UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.Escape and current then Panels.Close() end
	end)
end

-- def: {Name, Title, Icon, Color, Size (UDim2), Build(content, panel), Refresh(content, panel)}
function Panels.Register(def)
	local color = def.Color or UI.C.Blue
	-- body: dark brown with an embossed stud pattern and a thick near-black outline
	local frame = new("Frame", {Parent = host, Name = def.Name, Size = def.Size or UDim2.fromOffset(760, 500), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = UI.C.Bg, Visible = false, ZIndex = 22})
	UI.Corner(frame, 14)
	UI.Studs(frame, UI.Darken(UI.C.Bg, 0.45), 0.35, 26, 14)
	UI.Stroke(frame, UI.C.Outline, 5)
	local scale = new("UIScale", {Parent = frame})
	local glow = new("Frame", {Parent = host, Name = def.Name .. "_Glow", Size = (def.Size or UDim2.fromOffset(760, 500)) + UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = color, BackgroundTransparency = 1, Visible = false, ZIndex = 21})
	UI.Corner(glow, 30)
	local glowScale = new("UIScale", {Parent = glow})
	-- header: shiny studded gold bar with a big icon breaking out of the corner and a red close square
	local gold = Color3.fromRGB(255, 196, 30)
	local header = new("Frame", {Parent = frame, Name = "Header", Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = gold, ZIndex = 23})
	UI.Corner(header, 14)
	UI.Gradient(header, ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 160, 18))}), nil, 90)
	new("Frame", {Parent = header, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundColor3 = Color3.fromRGB(242, 160, 18), BorderSizePixel = 0, ZIndex = 23})
	UI.Studs(header, Color3.fromRGB(214, 130, 0), 0.35, 22, 14)
	new("Frame", {Parent = header, Name = "Edge", Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = UI.C.Outline, BorderSizePixel = 0, ZIndex = 24})
	local iconHolder = new("Frame", {Parent = header, Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(-14, -16), BackgroundTransparency = 1, ZIndex = 25})
	UI.Sunburst(iconHolder, UDim2.fromScale(1.5, 1.5), nil, Color3.fromRGB(255, 250, 210), 25, 0.25)
	local PANEL_ICONS = {Collection = "duck", DuckInfo = "duck", Equipment = "net", Skills = "star", Quests = "quests", Shop = "basket",
		Rebirth = "rebirth", Battle = "swords", Worlds = "portal", Daily = "gift", Leaderboards = "trophy", Settings = "gear_blue", Confirm = "chat"}
	local iconName = def.IconImage or PANEL_ICONS[def.Name]
	local icon
	if iconName then
		icon = UI.Icon(iconHolder, iconName, UDim2.fromScale(1, 1), nil, {ZIndex = 26})
	else
		icon = UI.Label(iconHolder, def.Icon or "", UDim2.fromScale(0.85, 0.85), UDim2.fromScale(0.075, 0.075), {ZIndex = 26, NoStroke = true})
	end
	icon.Rotation = -10
	UI.Label(header, def.Title .. (if string.sub(def.Title, -1) == "?" then "" else "!"), UDim2.new(1, -170, 0, 42), UDim2.fromOffset(72, 10),
		{TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 25, StrokeTh = 3.5})
	local close = UI.Button(header, {Text = "X", Color = UI.C.Red, Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 7), Z = 25, Radius = 8, StrokeTh = 3, OnClick = function() Panels.Close() end})
	close.Name = "Close"
	local content = new("Frame", {Parent = frame, Name = "Content", Size = UDim2.new(1, -28, 1, -84), Position = UDim2.fromOffset(14, 76), BackgroundTransparency = 1, ZIndex = 23})
	local panel = {Def = def, Frame = frame, Content = content, Scale = scale, Header = header, Glow = glow, GlowScale = glowScale}
	registry[def.Name] = panel
	if def.Build then def.Build(content, panel) end
	return panel
end

function Panels.Get(name) return registry[name] end
function Panels.Current() return current and current.Def.Name end

function Panels.Open(name: string, ...)
	local panel = registry[name]
	if not panel then return end
	if current == panel then
		if panel.Def.Refresh then panel.Def.Refresh(panel.Content, panel, ...) end
		return
	end
	if current then current.Frame.Visible = false; current.Glow.Visible = false end
	current = panel
	backdrop.Visible = true
	UI.Tween(backdrop, 0.3, {BackgroundTransparency = 0.5}, QUINT)
	-- (no world blur: a full-screen blur pass re-renders the 3D scene every frame; the dark backdrop is enough)
	panel.Frame.Visible = true
	panel.Glow.Visible = true
	-- slide + fade only: scaling a panel full of auto-sized text re-lays out every label each frame (stutter)
	-- fit the panel to the screen (phones): measured once per open, not animated
	local hs = host.AbsoluteSize
	local ps = panel.Frame.Size
	local uis = host.Parent and host.Parent:FindFirstChildOfClass("UIScale")
	local k = if uis then uis.Scale else 1
	local fit = 1
	-- keep clear of Roblox's top bar buttons (they sit over our GUI on phones)
	local topRes = 0
	pcall(function()
		local gs = game:GetService("GuiService")
		topRes = math.max(0, gs.TopbarInset.Max.Y - (host.AbsolutePosition.Y + gs:GetGuiInset().Y)) / k
	end)
	if hs.X > 10 then
		fit = math.min(1, (hs.Y / k - topRes - 24) / (ps.Y.Offset + 30), (hs.X / k - 30) / (ps.X.Offset + 30))
	end
	panel.YOff = topRes / 2
	panel.Scale.Scale = fit
	panel.GlowScale.Scale = fit
	panel.Frame.Position = UDim2.new(0.5, 0, 0.5, (panel.YOff or 0) + 40)
	panel.Glow.Position = UDim2.new(0.5, 0, 0.5, (panel.YOff or 0) + 40)
	panel.Glow.BackgroundTransparency = 1
	UI.Tween(panel.Frame, 0.32, {Position = UDim2.new(0.5, 0, 0.5, panel.YOff or 0)}, Enum.EasingStyle.Back)
	UI.Tween(panel.Glow, 0.32, {Position = UDim2.new(0.5, 0, 0.5, panel.YOff or 0), BackgroundTransparency = 1}, Enum.EasingStyle.Back)
	UI.Sound("swoosh", 1.2, 0.3)
	if panel.Def.Refresh then
		local sig = signature(panel.Def)
		local hasArgs = false
		for i = 1, select("#", ...) do if select(i, ...) ~= nil then hasArgs = true end end
		if hasArgs or sig == nil or sig ~= panel.LastSig then
			panel.LastSig = sig
			panel.Def.Refresh(panel.Content, panel, ...)
		end
	end
end

-- call after a panel rebuilt itself outside Open (e.g. a live data update) so the next open can skip it
function Panels.MarkFresh(name)
	local p = registry[name]
	if p then p.LastSig = signature(p.Def) end
end

function Panels.Close()
	if not current then return end
	local panel = current
	current = nil
	UI.Tween(panel.Frame, 0.18, {Position = UDim2.new(0.5, 0, 0.5, (panel.YOff or 0) + 30)}, QUINT)
	UI.Tween(panel.Glow, 0.18, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, (panel.YOff or 0) + 30)}, QUINT)
	UI.Tween(backdrop, 0.2, {BackgroundTransparency = 1}, QUINT)
	task.delay(0.18, function()
		if current ~= panel then panel.Frame.Visible = false; panel.Glow.Visible = false end
		if not current then
			backdrop.Visible = false
			getBlur().Enabled = false -- a blur pass costs GPU even at size 0
		end
	end)
	if panel.Def.OnClose then panel.Def.OnClose(panel) end
end

function Panels.Toggle(name)
	if current and current.Def.Name == name then Panels.Close() else Panels.Open(name) end
end

-- Scrolling grid helper
function Panels.Grid(parent, cell: UDim2, pad: number)
	local sf = new("ScrollingFrame", {Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 10,
		ScrollBarImageColor3 = Color3.new(1, 1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 23})
	new("UIGridLayout", {Parent = sf, CellSize = cell, CellPadding = UDim2.fromOffset(pad, pad), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center})
	UI.Pad(sf, 6)
	sf.ChildAdded:Connect(function(c) if c:IsA("GuiObject") then UI.PopIn(c) end end)
	return sf
end

function Panels.Scroll(parent, pad)
	local sf = new("ScrollingFrame", {Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 10,
		ScrollBarImageColor3 = Color3.new(1, 1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 23})
	UI.List(sf, pad or 8)
	UI.Pad(sf, 6)
	sf.ChildAdded:Connect(function(c) if c:IsA("GuiObject") then UI.PopIn(c) end end)
	return sf
end

-- Tab bar helper: returns setTab(name)
function Panels.Tabs(parent, tabs, color, onChange)
	local bar = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 23})
	UI.List(bar, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
	local buttons = {}
	local function set(name)
		for n, b in buttons do
			-- active tab green, inactive tabs gold (like a simulator shop)
			UI.SetColor(b, if n == name then UI.C.Green else UI.C.Yellow)
			local sc = b:FindFirstChildOfClass("UIScale")
			if sc and n == name then sc.Scale = 0.9; UI.Tween(sc, 0.35, {Scale = 1}, Enum.EasingStyle.Back) end
		end
		onChange(name)
	end
	for i, t in tabs do
		buttons[t] = UI.Button(bar, {Text = t, Color = UI.C.Yellow, Size = UDim2.fromOffset(160, 40), Order = i, Z = 24, Radius = 8, OnClick = function() set(t) end})
	end
	return set, bar
end

-- Card: coloured tile with a soft top-lit gradient, embossed studs and a thick dark outline
function Panels.Card(parent, props)
	local f = new("Frame", {Parent = parent, BackgroundColor3 = UI.C.Card, ZIndex = 23})
	for k, v in props or {} do (f :: any)[k] = v end
	UI.Corner(f, 10)
	UI.Gradient(f, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)), nil, 90).Name = "Shade"
	UI.Studs(f, UI.Darken(f.BackgroundColor3, 0.3), 0.5, 20, 10)
	UI.Stroke(f, UI.C.Outline, 3)
	return f
end

return Panels
