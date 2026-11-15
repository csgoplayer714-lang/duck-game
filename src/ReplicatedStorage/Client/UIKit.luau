-- UI toolkit: theme, components, tweens, sounds, number formatting, duck viewports.
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local DuckModelBuilder = require(Shared.DuckModelBuilder)
local Rarity = require(Shared.Rarity)

local UI = {}
local player = Players.LocalPlayer

-- Chunky simulator style: studded gold headers, dark-brown studded bodies, thick dark outlines,
-- bright green/yellow buttons with white outlined text, sunbursts behind rewards.
UI.Font = Enum.Font.FredokaOne
UI.Body = Enum.Font.FredokaOne
UI.C = {
	Bg = Color3.fromRGB(58, 32, 20), Bg2 = Color3.fromRGB(78, 45, 28), Card = Color3.fromRGB(104, 64, 38),
	Text = Color3.fromRGB(255, 255, 255), Sub = Color3.fromRGB(255, 228, 185), Outline = Color3.fromRGB(30, 15, 6),
	Yellow = Color3.fromRGB(255, 204, 40), Blue = Color3.fromRGB(45, 150, 255), Green = Color3.fromRGB(78, 214, 48),
	Orange = Color3.fromRGB(255, 140, 30), Pink = Color3.fromRGB(255, 80, 175), Purple = Color3.fromRGB(165, 85, 255),
	Red = Color3.fromRGB(232, 44, 44), Teal = Color3.fromRGB(30, 200, 190), Gold = Color3.fromRGB(255, 196, 30),
	Gem = Color3.fromRGB(80, 215, 255), Dark = Color3.fromRGB(40, 22, 13),
}
UI.Images = {
	Stud = "rbxassetid://119166410854885",
	Sunburst = "rbxassetid://114459361165919",
	Icons = "rbxassetid://95360015903001", -- 1024x1024 sprite sheet, 160px cells
	Icons2 = "rbxassetid://87034217213824", -- 480x160 sheet: coop, feather, style
}
-- cell positions in the icon sprite sheet
local ICON_CELLS = {
	addfriend = {0, 0}, trophy_rainbow = {1, 0}, quests = {2, 0}, gift = {3, 0}, rebirth = {4, 0}, team = {5, 0},
	star = {0, 1}, potion = {1, 1}, gear_blue = {2, 1}, gear_white = {3, 1}, portal = {4, 1}, basket = {5, 1},
	sound = {0, 2}, chat = {1, 2}, play = {2, 2}, trophy = {3, 2}, duck = {4, 2}, coins = {5, 2},
	gem = {0, 3}, swords = {1, 3}, net = {2, 3},
	-- second sheet
	coop = {0, 0, 2}, feather = {1, 0, 2}, style = {2, 0, 2},
}
UI.IconNames = ICON_CELLS

-- Sprite-sheet icon as an ImageLabel (one texture for every icon = one download, fast to draw)
function UI.Icon(parent: Instance, name: string, size: UDim2?, pos: UDim2?, props)
	local cell = ICON_CELLS[name] or ICON_CELLS.star
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.BackgroundTransparency = 1
	img.Image = if cell[3] == 2 then UI.Images.Icons2 else UI.Images.Icons
	img.ImageRectOffset = Vector2.new(cell[1] * 160, cell[2] * 160)
	img.ImageRectSize = Vector2.new(160, 160)
	img.ScaleType = Enum.ScaleType.Fit
	img.Size = size or UDim2.fromScale(1, 1)
	img.Position = pos or UDim2.new()
	for k, v in props or {} do (img :: any)[k] = v end
	img.Parent = parent
	return img
end
function UI.SetIcon(img: ImageLabel, name: string)
	local cell = ICON_CELLS[name]
	if img and cell then
		img.Image = if cell[3] == 2 then UI.Images.Icons2 else UI.Images.Icons
		img.ImageRectOffset = Vector2.new(cell[1] * 160, cell[2] * 160)
	end
end

function UI.new(class: string, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in props or {} do
		if k == "Parent" then parent = v else (inst :: any)[k] = v end
	end
	for _, c in children or {} do c.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end
local new = UI.new

function UI.Corner(inst, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 12), Parent = inst}) end
function UI.Stroke(inst, color, th, trans)
	return new("UIStroke", {Color = color or UI.C.Outline, Thickness = th or 2, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst})
end
function UI.TextStroke(inst, th) return new("UIStroke", {Color = UI.C.Outline, Thickness = th or 2, Parent = inst}) end
function UI.Gradient(inst, c1, c2, rot)
	-- a custom gradient replaces the default top-lit shading a card/toast was created with
	local shade = inst:FindFirstChild("Shade")
	if shade and shade:IsA("UIGradient") then shade:Destroy() end
	return new("UIGradient", {Color = if typeof(c1) == "ColorSequence" then c1 else ColorSequence.new(c1, c2 or c1), Rotation = rot or 90, Parent = inst})
end
function UI.Pad(inst, p) return new("UIPadding", {PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p), PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), Parent = inst}) end
function UI.List(inst, pad, dir, align)
	return new("UIListLayout", {Padding = UDim.new(0, pad or 6), FillDirection = dir or Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center, Parent = inst})
end
function UI.Lighten(c, f) return c:Lerp(Color3.new(1, 1, 1), f) end
function UI.Darken(c, f) return c:Lerp(Color3.new(0, 0, 0), f) end

-- Tiled LEGO-style stud pattern over a frame (tinted darker than the frame for a subtle embossed look)
function UI.Studs(frame: GuiObject, color: Color3?, transparency: number?, tile: number?, radius: number?)
	local img = new("ImageLabel", {Parent = frame, Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Image = UI.Images.Stud, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(tile or 22, tile or 22),
		ImageColor3 = color or UI.Darken(frame.BackgroundColor3, 0.25), ImageTransparency = transparency or 0.45, ZIndex = frame.ZIndex})
	if radius ~= 0 then new("UICorner", {Parent = img, CornerRadius = UDim.new(0, radius or 12)}) end
	return img
end

-- Soft light rays behind an icon or reward
function UI.Sunburst(parent: GuiObject, size: UDim2, pos: UDim2?, color: Color3?, z: number?, transparency: number?)
	return new("ImageLabel", {Parent = parent, Name = "Sunburst", Size = size, Position = pos or UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1, Image = UI.Images.Sunburst, ImageColor3 = color or Color3.new(1, 1, 1), ImageTransparency = transparency or 0.15, ZIndex = z or parent.ZIndex})
end

-- Strip of darker colour across the top of a card for its title
function UI.CardHeader(card: GuiObject, text: string, height: number?, color: Color3?, z: number?)
	local h = new("Frame", {Parent = card, Name = "CardHeader", Size = UDim2.new(1, 0, 0, height or 32), BackgroundColor3 = color or UI.Darken(card.BackgroundColor3, 0.18),
		BorderSizePixel = 0, ZIndex = z or card.ZIndex})
	UI.Corner(h, 10)
	local l = UI.Label(h, text, UDim2.new(1, -16, 1, -6), UDim2.fromOffset(10, 3), {TextXAlignment = Enum.TextXAlignment.Left, ZIndex = (z or card.ZIndex) + 1, StrokeTh = 2.5})
	return h, l
end

function UI.Tween(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function UI.Label(parent, text, size, pos, props)
	local l = new("TextLabel", {Parent = parent, Text = text, Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1,
		Font = UI.Font, TextColor3 = UI.C.Text, TextScaled = true, RichText = true})
	for k, v in props or {} do
		if k ~= "StrokeTh" and k ~= "NoStroke" then (l :: any)[k] = v end
	end
	if not (props and props.NoStroke) then UI.TextStroke(l, props and props.StrokeTh or 2) end
	return l
end

function UI.Abbrev(n: number): string
	n = math.floor(n or 0)
	local units = {{1e15, "Qa"}, {1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"}}
	for _, u in units do
		if math.abs(n) >= u[1] then
			local v = n / u[1]
			return (if v >= 100 then string.format("%d", v) elseif v >= 10 then string.format("%.1f", v) else string.format("%.2f", v)) .. u[2]
		end
	end
	return tostring(n)
end

function UI.Odds(n: number): string
	if n <= 1 then return "1 in 1" end
	return "1 in " .. UI.Abbrev(math.floor(n + 0.5))
end

---------------------------------------------------------------- sounds
-- licensed Creator Store sounds (Pro Sound Effects / APM Music) + Roblox built-ins.
-- A list means "pick one at random" so repeated sounds don't feel robotic.
local SOUNDS = {
	click = "rbxasset://sounds/electronicpingshort.wav", -- tonal ping used by chimes
	ui = "rbxassetid://8755541422", -- soft pop for buttons
	swoosh = {"rbxassetid://9120972321", "rbxassetid://9120972444"},
	victory = "rbxasset://sounds/victory.wav",
	bass = "rbxasset://sounds/bass.mp3",
	flash = "rbxasset://sounds/flashbulb.wav",
	snap = "rbxasset://sounds/snap.mp3",
	splash = {"rbxassetid://9125703162", "rbxassetid://9125702803"},
	swim = "rbxasset://sounds/action_swim.mp3",
	jump = "rbxasset://sounds/action_jump.mp3",
	hit = "rbxasset://sounds/hit.wav",
	quack = {"rbxassetid://9068554227", "rbxassetid://6239232266"},
	squeak = {"rbxassetid://9125994778", "rbxassetid://9125994570", "rbxassetid://9125994773"},
	coin = "rbxassetid://1169806635",
	coins = "rbxassetid://7437419566",
	boing = "rbxassetid://2772396665",
	sting = "rbxassetid://1839881844", -- short happy jingle
	fanfare = "rbxassetid://9045298695", -- big brassy jingle
	fail = "rbxassetid://1841983099", -- sad trombone-ish sting
}
local function pickSound(name)
	local id = SOUNDS[name]
	if type(id) == "table" then id = id[math.random(1, #id)] end
	return id
end
local soundObjs = {}
UI.SfxEnabled = true
function UI.Sound(name: string, pitch: number?, volume: number?)
	if not UI.SfxEnabled then return end
	local id = pickSound(name)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	task.delay(8, function() if s.Parent then s:Destroy() end end)
end
-- 3D sound that comes from a part in the world (louder when you're close)
function UI.SoundAt(name: string, part: Instance?, pitch: number?, volume: number?)
	if not UI.SfxEnabled or not part or not part:IsA("BasePart") then return end
	local id = pickSound(name)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = (pitch or 1) * (0.94 + math.random() * 0.12)
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = 140
	s.Parent = part
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	task.delay(8, function() if s.Parent then s:Destroy() end end)
end
-- preload so the first play isn't silent
task.spawn(function()
	local list = {}
	for _, v in SOUNDS do
		for _, id in (if type(v) == "table" then v else {v}) do
			if id:find("rbxassetid") then local s = Instance.new("Sound"); s.SoundId = id; table.insert(list, s) end
		end
	end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
end)
-- ascending chime, more notes for rarer ducks
function UI.Chime(notes: number, base: number?)
	for i = 1, notes do
		task.delay((i - 1) * 0.09, function() UI.Sound("click", (base or 0.8) + i * 0.12, 0.45) end)
	end
end

---------------------------------------------------------------- buttons
local QUINT = Enum.EasingStyle.Quint
function UI.Button(parent, opts)
	local color = opts.Color or UI.C.Blue
	local z = opts.Z or 1
	local radius = opts.Radius or 12
	local b = new("TextButton", {Parent = parent, Size = opts.Size or UDim2.fromOffset(140, 44), Position = opts.Position or UDim2.new(),
		AnchorPoint = opts.Anchor or Vector2.new(0, 0), BackgroundColor3 = color, Text = "", AutoButtonColor = false,
		LayoutOrder = opts.Order or 0, Name = opts.Name or "Button", ZIndex = z})
	UI.Corner(b, radius)
	UI.Gradient(b, UI.Lighten(color, 0.25), UI.Darken(color, 0.15), 90)
	local stroke = UI.Stroke(b, UI.C.Outline, opts.StrokeTh or 3)
	local scale = new("UIScale", {Parent = b})
	-- bottom lip gives the button depth
	local lip = new("Frame", {Parent = b, Name = "Lip", Size = UDim2.new(1, 0, 0, math.max(4, radius * 0.45)), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = UI.Darken(color, 0.35), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = z})
	UI.Corner(lip, radius)
	-- glossy shine with an animated sweep band
	local shine = new("Frame", {Parent = b, Name = "Shine", Size = UDim2.new(1, -8, 0.4, 0), Position = UDim2.fromOffset(4, 3), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = z})
	UI.Corner(shine, radius - 3)
	local sweep = new("UIGradient", {Parent = shine, Rotation = 20, Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.45, 0.6), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.55, 0.6), NumberSequenceKeypoint.new(1, 0.6)})})
	local flash = new("Frame", {Parent = b, Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z + 2})
	UI.Corner(flash, radius)
	local text = opts.Text or ""
	local lbl
	if opts.IconImage then
		-- picture icon: centred and big when there's no text, otherwise on the left with the text beside it
		if text == "" then
			UI.Icon(b, opts.IconImage, UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.47), {AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z + 1})
			lbl = UI.Label(b, "", UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 4), {ZIndex = z + 1, StrokeTh = 2.5})
		else
			local h = (opts.Size or UDim2.fromOffset(140, 44)).Y.Offset
			UI.Icon(b, opts.IconImage, UDim2.fromOffset(h * 0.95, h * 0.95), UDim2.new(0, 4, 0.5, 0), {AnchorPoint = Vector2.new(0, 0.5), ZIndex = z + 1})
			lbl = UI.Label(b, text, UDim2.new(1, -(h * 0.95 + 14), 1, -12), UDim2.fromOffset(h * 0.95 + 6, 4), {ZIndex = z + 1, StrokeTh = 2.5})
		end
	else
		if opts.Icon then text = opts.Icon .. (if text ~= "" then " " .. text else "") end
		lbl = UI.Label(b, text, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 4), {ZIndex = z + 1, StrokeTh = 2.5})
	end
	lbl.Name = "Label"
	local hovering = false
	b.MouseEnter:Connect(function()
		hovering = true
		local c = b:GetAttribute("BaseColor") or color
		UI.Tween(scale, 0.18, {Scale = 1.07}, QUINT)
		UI.Tween(stroke, 0.18, {Color = UI.Lighten(c, 0.6), Thickness = (opts.StrokeTh or 3) + 0.6})
		sweep.Offset = Vector2.new(-1, 0)
		UI.Tween(sweep, 0.45, {Offset = Vector2.new(1, 0)}, Enum.EasingStyle.Sine)
	end)
	b.MouseLeave:Connect(function()
		hovering = false
		local c = b:GetAttribute("BaseColor") or color
		UI.Tween(scale, 0.22, {Scale = 1}, QUINT)
		UI.Tween(stroke, 0.22, {Color = UI.C.Outline, Thickness = opts.StrokeTh or 3})
	end)
	b.MouseButton1Down:Connect(function() UI.Tween(scale, 0.07, {Scale = 0.92}, QUINT) end)
	b.MouseButton1Up:Connect(function() UI.Tween(scale, 0.35, {Scale = if hovering then 1.07 else 1}, Enum.EasingStyle.Back) end)
	b.Activated:Connect(function()
		flash.BackgroundTransparency = 0.55
		UI.Tween(flash, 0.35, {BackgroundTransparency = 1}, QUINT)
		if not opts.OnClick then return end
		UI.Sound("ui", 1.1, 0.35)
		opts.OnClick(b)
	end)
	b:SetAttribute("BaseColor", color)
	return b, lbl
end

function UI.SetText(b, t)
	local l = b and b:FindFirstChild("Label")
	if l then l.Text = t end
end
function UI.SetColor(b, c)
	if not b then return end
	b:SetAttribute("BaseColor", c)
	b.BackgroundColor3 = c
	local g = b:FindFirstChildOfClass("UIGradient")
	if g then g.Color = ColorSequence.new(UI.Lighten(c, 0.25), UI.Darken(c, 0.15)) end
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then s.Color = UI.C.Outline end
	local lip = b:FindFirstChild("Lip")
	if lip then lip.BackgroundColor3 = UI.Darken(c, 0.35) end
end

---------------------------------------------------------------- toasts
local toastHolder
function UI.SetToastHolder(h) toastHolder = h end
local KIND_COLORS = {info = UI.C.Blue, warn = UI.C.Orange, error = UI.C.Red, good = UI.C.Green, quest = UI.C.Yellow, title = UI.C.Pink, gem = UI.C.Gem}
local KIND_ICONS = {info = "\u{2139}\u{FE0F}", warn = "\u{26A0}\u{FE0F}", error = "\u{274C}", good = "\u{2705}", quest = "\u{1F4DC}", title = "\u{1F3C5}", gem = "\u{1F48E}"}
function UI.Toast(text: string, kind: string?)
	if not toastHolder then return end
	kind = kind or "info"
	local color = KIND_COLORS[kind] or UI.C.Blue
	local slot = new("Frame", {Parent = toastHolder, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = false})
	UI.Tween(slot, 0.25, {Size = UDim2.new(1, 0, 0, 56)}, QUINT)
	local f = new("Frame", {Parent = slot, Size = UDim2.new(1, 0, 0, 52), Position = UDim2.new(1.2, 0, 0, 0), BackgroundColor3 = UI.C.Bg, BackgroundTransparency = 0.04})
	UI.Corner(f, 12)
	UI.Gradient(f, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)), nil, 90)
	UI.Studs(f, UI.Darken(UI.C.Bg, 0.35), 0.55, 18, 12)
	local st = UI.Stroke(f, UI.C.Outline, 3)
	local strip = new("Frame", {Parent = f, Size = UDim2.new(0, 8, 1, -10), Position = UDim2.fromOffset(5, 5), BackgroundColor3 = color, BorderSizePixel = 0})
	UI.Corner(strip, 4)
	local ic = new("Frame", {Parent = f, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(18, 8), BackgroundColor3 = color})
	UI.Corner(ic, 8)
	UI.Stroke(ic, UI.C.Outline, 2.5)
	local KIND_IMG = {info = "chat", good = "star", quest = "quests", title = "trophy", gem = "gem"}
	if KIND_IMG[kind] then
		ic.BackgroundTransparency = 1
		local s = ic:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end
		UI.Icon(ic, KIND_IMG[kind], UDim2.fromScale(1.25, 1.25), UDim2.fromScale(0.5, 0.5), {AnchorPoint = Vector2.new(0.5, 0.5)})
	else
		UI.Label(ic, KIND_ICONS[kind] or "", UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.15, 0.15), {NoStroke = true})
	end
	UI.Label(f, text, UDim2.new(1, -72, 1, -16), UDim2.fromOffset(62, 6), {Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2})
	local timer = new("Frame", {Parent = f, Size = UDim2.new(1, -28, 0, 3), Position = UDim2.new(0, 14, 1, -5), BackgroundColor3 = color, BorderSizePixel = 0})
	UI.Corner(timer, 2)
	UI.Tween(f, 0.4, {Position = UDim2.new(0, 0, 0, 0)}, QUINT)
	UI.Tween(timer, 3.6, {Size = UDim2.new(0, 0, 0, 3)}, Enum.EasingStyle.Linear)
	task.delay(3.6, function()
		if f.Parent then
			UI.Tween(f, 0.3, {Position = UDim2.new(1.2, 0, 0, 0), BackgroundTransparency = 1}, QUINT)
			UI.Tween(st, 0.3, {Transparency = 1})
			task.wait(0.25)
			UI.Tween(slot, 0.2, {Size = UDim2.new(1, 0, 0, 0)}, QUINT)
			task.wait(0.22)
			slot:Destroy()
		end
	end)
	local kids = {}
	for _, c in toastHolder:GetChildren() do if c:IsA("Frame") then table.insert(kids, c) end end
	if #kids > 5 then kids[1]:Destroy() end
end

-- Pop-in animation for newly created list/grid items (staggered)
local burstCount, burstLast = 0, 0
function UI.PopIn(obj: GuiObject)
	local now = os.clock()
	if now - burstLast > 0.15 then burstCount = 0 end
	burstLast = now
	burstCount += 1
	-- only the first few items of a burst pop; animating dozens of scaled cards at once is what stutters
	if burstCount > 10 then return end
	local delayT = burstCount * 0.02
	task.defer(function()
		if not obj.Parent then return end
		local sc = obj:FindFirstChildOfClass("UIScale") or new("UIScale", {Parent = obj})
		sc.Scale = 0.8
		task.delay(delayT, function()
			if sc.Parent then UI.Tween(sc, 0.22, {Scale = 1}, Enum.EasingStyle.Back) end
		end)
	end)
end

-- Smoothly counts a TextLabel's displayed number toward a target
local counters = setmetatable({}, {__mode = "k"})
function UI.CountTo(label: TextLabel, target: number, formatter)
	formatter = formatter or UI.Abbrev
	local c = counters[label]
	if not c then
		c = {value = target, nv = Instance.new("NumberValue")}
		c.nv.Value = target
		c.nv.Changed:Connect(function(v) label.Text = formatter(v) end)
		counters[label] = c
		label.Text = formatter(target)
		return
	end
	if c.tween then c.tween:Cancel() end
	c.tween = TweenService:Create(c.nv, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Value = target})
	c.tween:Play()
end

---------------------------------------------------------------- duck viewports
local modelCache = {}
local function duckModel(id)
	if not modelCache[id] then
		local duck = DuckData.List[id]
		modelCache[id] = DuckModelBuilder.Build(duck, {NoEffects = true})
	end
	return modelCache[id]:Clone()
end
UI.DuckModel = duckModel

-- Duck previews are static pictures: no WorldModel (no physics/joints) and no per-frame animation,
-- so each ViewportFrame renders once instead of every frame. Models are filled in through a small
-- per-frame budget so opening a big grid never freezes the game.
local vpQueue = {}
local vpRunning = false
local function runVpQueue()
	if vpRunning then return end
	vpRunning = true
	local RunService = game:GetService("RunService")
	task.spawn(function()
		while #vpQueue > 0 do
			local t0 = os.clock()
			while #vpQueue > 0 and os.clock() - t0 < 0.004 do
				local job = table.remove(vpQueue, 1)
				if job.vf.Parent then job.fn() end
			end
			RunService.RenderStepped:Wait()
		end
		vpRunning = false
	end)
end

local sizeCache = {}
function UI.Viewport(parent, duckId: number, opts)
	opts = opts or {}
	local vf = new("ViewportFrame", {Parent = parent, Size = opts.Size or UDim2.fromScale(1, 1), Position = opts.Position or UDim2.new(),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 190), LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.6, -1, -0.8), ZIndex = opts.Z or 1, AnchorPoint = opts.Anchor or Vector2.new()})
	local cam = new("Camera", {Parent = vf, FieldOfView = 32})
	vf.CurrentCamera = cam
	if opts.Silhouette then
		vf.ImageColor3 = Color3.new(0, 0, 0)
		vf.Ambient = Color3.new(0, 0, 0)
		vf.LightColor = Color3.new(0, 0, 0)
	end
	local holder = {}
	local function fill()
		local m = duckModel(duckId)
		m:SetAttribute("Rig", nil) -- static preview, never animated
		m:PivotTo(CFrame.new())
		m.Parent = vf
		holder.m = m
		local size = sizeCache[duckId]
		if not size then
			local _, s = m:GetBoundingBox()
			size = s
			sizeCache[duckId] = s
		end
		local dist = math.max(size.X, size.Y, size.Z) * (opts.Zoom or 1.55) + 2
		local center = Vector3.new(0, size.Y * 0.42, 0)
		local angle = opts.Angle or math.rad(200)
		local function place(a)
			cam.CFrame = CFrame.lookAt(center + Vector3.new(math.sin(a) * dist, dist * 0.28, math.cos(a) * dist), center)
		end
		place(angle)
		if opts.Spin then
			local conn
			conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
				if not vf.Parent then conn:Disconnect() return end
				angle += dt * (opts.Spin or 0.8)
				place(angle)
			end)
		end
	end
	if opts.Immediate or opts.Spin then
		fill()
	else
		table.insert(vpQueue, {vf = vf, fn = fill})
		runVpQueue()
	end
	return vf, holder.m
end

-- Runs UI build jobs a few at a time (~5 ms per frame) so big lists never freeze a frame.
-- Calling again with the same key cancels the previous unfinished build.
local chunkTokens = {}
function UI.BuildChunked(key: string, jobs)
	chunkTokens[key] = (chunkTokens[key] or 0) + 1
	local my = chunkTokens[key]
	local RunService = game:GetService("RunService")
	task.spawn(function()
		local i = 1
		while i <= #jobs do
			if chunkTokens[key] ~= my then return end
			local t0 = os.clock()
			while i <= #jobs and os.clock() - t0 < 0.005 do
				jobs[i]()
				i += 1
			end
			if i <= #jobs then RunService.RenderStepped:Wait() end
		end
	end)
end

function UI.RarityColor(i: number): Color3 return Rarity.List[i].Color end
function UI.RarityGradient(inst, i: number, rot)
	return UI.Gradient(inst, Rarity.Gradient(i), nil, rot or 0)
end

-- animated rainbow/shine for top rarities
function UI.AnimateGradient(grad: UIGradient, speed: number?)
	task.spawn(function()
		while grad.Parent do
			grad.Offset = Vector2.new(-1, 0)
			UI.Tween(grad, 1.6 / (speed or 1), {Offset = Vector2.new(1, 0)}, Enum.EasingStyle.Linear)
			task.wait(1.6 / (speed or 1))
		end
	end)
end

return UI
