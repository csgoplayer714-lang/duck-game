-- Screen effects: catch reveal (scaled by rarity), announcements, level-up, achievements, rebirth.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local Rarity = require(Shared.Rarity)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local new = UI.new

local Effects = {}
local player = Players.LocalPlayer
local screen
local revealQueue = {}
local revealing = false

function Effects.Init(s) screen = s end
function Effects.IsRevealing() return revealing end

function Effects.Shake(intensity: number, duration: number)
	local cam = workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e > duration then conn:Disconnect() return end
		local k = intensity * (1 - e / duration)
		cam.CFrame *= CFrame.Angles(math.rad(math.random(-10, 10) / 10 * k), math.rad(math.random(-10, 10) / 10 * k), 0)
	end)
end

function Effects.Flash(color: Color3, strength: number?)
	local f = new("Frame", {Parent = screen, Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 1 - (strength or 0.7), ZIndex = 90})
	UI.Tween(f, 0.6, {BackgroundTransparency = 1})
	task.delay(0.65, function() f:Destroy() end)
end

local function rays(parent, color, count, z)
	local holder = new("Frame", {Parent = parent, Size = UDim2.fromOffset(1200, 1200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), BackgroundTransparency = 1, ZIndex = z})
	for i = 1, count do
		-- full-size pivot frame so rotation happens around the burst centre
		local pivot = new("Frame", {Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = (i / count) * 360, ZIndex = z})
		local r = new("Frame", {Parent = pivot, Size = UDim2.new(0, 70, 0.5, 0), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = color, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = z})
		new("UIGradient", {Parent = r, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(1, 0.2)})})
	end
	task.spawn(function()
		while holder.Parent do
			holder.Rotation += 0.4
			RunService.RenderStepped:Wait()
		end
	end)
	return holder
end

local function confetti(parent, n, colors, z)
	for i = 1, n do
		local c = new("Frame", {Parent = parent, Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22)), Position = UDim2.new(math.random(), 0, -0.05, 0),
			Rotation = math.random(0, 360), BackgroundColor3 = colors[math.random(1, #colors)], BorderSizePixel = 0, ZIndex = z})
		local t = math.random(18, 35) / 10
		UI.Tween(c, t, {Position = UDim2.new(c.Position.X.Scale + math.random(-10, 10) / 100, 0, 1.1, 0), Rotation = c.Rotation + math.random(-400, 400)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(t, function() c:Destroy() end)
	end
end
Effects.Confetti = function(n, colors) confetti(screen, n, colors or {UI.C.Yellow, UI.C.Pink, UI.C.Blue, UI.C.Green}, 95) end

-- The duck reveal. info: {duckId, coins, xp, isNew, source}
local function doReveal(info)
	revealing = true
	local duck = DuckData.List[info.duckId]
	local r = duck.Rarity
	local tier = Rarity.List[r]
	local overlay = new("TextButton", {Parent = screen, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 80})
	UI.Tween(overlay, 0.3, {BackgroundTransparency = if r >= 5 then 0.25 else 0.5})
	local suspense = if r >= 9 then 2.2 elseif r >= 7 then 1.6 elseif r >= 5 then 1.0 else 0
	if suspense > 0 then
		-- suspense: pulsing rarity glow with a dark silhouette
		local sil = UI.Viewport(overlay, duck.Id, {Size = UDim2.fromOffset(320, 320), Position = UDim2.fromScale(0.5, 0.42), Anchor = Vector2.new(0.5, 0.5), Silhouette = true, Z = 83})
		local glow = new("Frame", {Parent = overlay, Size = UDim2.fromOffset(380, 380), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = tier.Glow, BackgroundTransparency = 0.6, ZIndex = 82})
		UI.Corner(glow, 190)
		local gs = new("UIScale", {Parent = glow})
		for i = 1, math.floor(suspense / 0.4) do
			UI.Sound(if r >= 9 then "bass" else "click", 0.5 + i * 0.08, 0.5)
			gs.Scale = 0.85
			UI.Tween(gs, 0.35, {Scale = 1.1})
			if r >= 9 then Effects.Shake(0.3 + i * 0.1, 0.35) end
			task.wait(0.4)
		end
		sil:Destroy(); glow:Destroy()
		Effects.Flash(tier.Glow, 0.9)
		UI.Sound("flash", 1, 0.6)
	end
	local rayHolder = rays(overlay, tier.Glow, 10 + r * 2, 81)
	-- reveal jingle: big brass for Legendary+, a happy sting for the rest
	UI.Sound(if r >= 5 then "fanfare" else "sting", 1, if r >= 5 then 0.55 else 0.45)
	UI.Sound("squeak", 1.1, 0.5)
	-- framed reward card: studded gold header, dark-brown studded body, rarity tile with a spinning sunburst
	local card = new("Frame", {Parent = overlay, Size = UDim2.fromOffset(420, 540), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Bg, ZIndex = 84})
	UI.Corner(card, 14)
	UI.Studs(card, UI.Darken(UI.C.Bg, 0.45), 0.35, 26, 14)
	UI.Stroke(card, UI.C.Outline, 5)
	local sc = new("UIScale", {Parent = card, Scale = 0.2})
	UI.Tween(sc, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
	local head = new("Frame", {Parent = card, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = UI.C.Gold, ZIndex = 85})
	UI.Corner(head, 14)
	UI.Gradient(head, ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 160, 18))}), nil, 90)
	UI.Studs(head, Color3.fromRGB(214, 130, 0), 0.35, 22, 14)
	new("Frame", {Parent = head, Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = UI.C.Outline, BorderSizePixel = 0, ZIndex = 86})
	local top = UI.Label(head, if info.source == "boss" then "BOSS DROP!" else "YOU CAUGHT!", UDim2.new(1, -20, 1, -14), UDim2.fromOffset(10, 7), {ZIndex = 86, StrokeTh = 3.5})
	local rl = UI.Label(card, string.upper(tier.Name), UDim2.new(1, -20, 0, 48), UDim2.fromOffset(10, 68), {ZIndex = 85, StrokeTh = 3.5, TextColor3 = Color3.new(1, 1, 1)})
	local g = UI.RarityGradient(rl, r)
	if r >= 8 then UI.AnimateGradient(g, 1.5) end
	local tile = new("Frame", {Parent = card, Size = UDim2.fromOffset(360, 290), Position = UDim2.fromOffset(30, 120), BackgroundColor3 = UI.Darken(tier.Color, 0.1), ZIndex = 85, ClipsDescendants = true})
	UI.Corner(tile, 12)
	UI.Gradient(tile, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)), nil, 90)
	UI.Studs(tile, UI.Darken(tier.Color, 0.35), 0.5, 22, 12)
	UI.Stroke(tile, UI.C.Outline, 4)
	local burst = UI.Sunburst(tile, UDim2.fromOffset(460, 460), UDim2.fromScale(0.5, 0.5), UI.Lighten(tier.Glow, 0.4), 85, 0.1)
	task.spawn(function()
		while burst.Parent do
			burst.Rotation = (burst.Rotation + 0.6) % 360
			game:GetService("RunService").RenderStepped:Wait()
		end
	end)
	local vp = UI.Viewport(tile, duck.Id, {Spin = 1.2, Zoom = 1.3, Z = 86})
	local nm = UI.Label(card, duck.Name, UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 416), {ZIndex = 85, StrokeTh = 3, TextColor3 = UI.Lighten(tier.Color, 0.35)})
	local sub = {}
	if info.coins then table.insert(sub, "\u{1F4B0} +" .. UI.Abbrev(info.coins)) end
	if info.xp then table.insert(sub, "\u{2B50} +" .. UI.Abbrev(info.xp) .. " XP") end
	UI.Label(card, table.concat(sub, "    "), UDim2.new(1, -20, 0, 28), UDim2.fromOffset(10, 458), {ZIndex = 85, StrokeTh = 2.5})
	if info.isNew then
		local nb = new("Frame", {Parent = card, Size = UDim2.fromOffset(110, 40), Position = UDim2.new(1, -90, 0, 108), Rotation = 12, BackgroundColor3 = UI.C.Red, ZIndex = 87})
		UI.Corner(nb, 8); UI.Stroke(nb, UI.C.Outline, 3)
		UI.Label(nb, "NEW!", UDim2.fromScale(0.9, 0.8), UDim2.fromScale(0.05, 0.1), {ZIndex = 88})
	end
	UI.Label(card, "Tap to continue", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 498), {ZIndex = 85, Font = UI.Body, TextColor3 = UI.C.Sub})
	-- audio & juice
	UI.Chime(math.min(3 + r, 12), 0.7 + r * 0.03)
	if r >= 5 then
		Effects.Shake(0.6 + (r - 5) * 0.25, 0.6 + (r - 5) * 0.15)
		confetti(overlay, 30 + r * 10, {tier.Color, tier.Glow, Color3.new(1, 1, 1)}, 89)
	end
	if r >= 7 then
		local cc = Lighting:FindFirstChild("WorldColor")
		if cc then
			local old = cc.TintColor
			cc.TintColor = tier.Glow
			UI.Tween(cc, 2.5, {TintColor = old})
		end
	end
	local minTime = 1.2 + (if r >= 5 then 1 else 0)
	local t0 = os.clock()
	local closed = false
	local function close()
		if closed or os.clock() - t0 < minTime then return end
		closed = true
		UI.Tween(sc, 0.2, {Scale = 0})
		UI.Tween(overlay, 0.25, {BackgroundTransparency = 1})
		task.wait(0.26)
		overlay:Destroy()
		revealing = false
		if #revealQueue > 0 then doReveal(table.remove(revealQueue, 1)) end
	end
	overlay.Activated:Connect(close)
	task.delay(if r >= 5 then 7 else 3.2, close)
end

function Effects.Reveal(info)
	if revealing then table.insert(revealQueue, info) return end
	task.spawn(doReveal, info)
end

-- Top-of-screen banner for other players' (and your) rare catches
local bannerHolder
function Effects.Announce(p)
	local tier = Rarity.List[p.Rarity]
	if not tier then return end
	if not bannerHolder then
		bannerHolder = new("Frame", {Parent = screen, Size = UDim2.fromOffset(640, 300), Position = UDim2.new(0.5, 0, 0, 130), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, ZIndex = 60})
		UI.List(bannerHolder, 6)
	end
	local isSpawn = p.Kind == "spawn"
	local f = new("Frame", {Parent = bannerHolder, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = UI.C.Bg, ZIndex = 61})
	UI.Corner(f, 12)
	local g = UI.Gradient(f, Rarity.Gradient(p.Rarity), nil, 0)
	if p.Rarity >= 8 then UI.AnimateGradient(g, 0.8) end
	UI.Studs(f, Color3.new(0, 0, 0), 0.75, 20, 12)
	UI.Stroke(f, UI.C.Outline, 4)
	local prefix = if p.Kind == "global" then "\u{1F310} GLOBAL: " else ""
	local txt = if isSpawn then string.format("%sA %s DUCK appeared for %s!", prefix, string.upper(tier.Name), p.Name)
		else string.format("%s%s caught a %s duck: %s!", prefix, p.Name, string.upper(tier.Name), p.Duck)
	UI.Label(f, txt, UDim2.new(1, -24, 1, -14), UDim2.fromOffset(12, 7), {ZIndex = 62, StrokeTh = 2.5})
	local s = new("UIScale", {Parent = f, Scale = 0})
	UI.Tween(s, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
	UI.Chime(if p.Rarity >= 9 then 8 else 4, 0.6)
	if p.Rarity >= 9 and p.UserId ~= player.UserId then
		Effects.Flash(tier.Glow, 0.5)
		Effects.Shake(0.4, 0.5)
	end
	task.delay(if p.Rarity >= 8 then 7 else 5, function()
		UI.Tween(s, 0.25, {Scale = 0})
		task.wait(0.3)
		f:Destroy()
	end)
end

function Effects.LevelUp(p)
	local f = UI.Label(screen, "LEVEL UP!  \u{2B06}\u{FE0F} " .. p.Level, UDim2.fromOffset(500, 70), UDim2.new(0.5, -250, 0.12, 30), {ZIndex = 70, StrokeTh = 3.5, TextColor3 = UI.C.Green})
	local s = new("UIScale", {Parent = f, Scale = 0.3})
	UI.Tween(s, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	UI.Chime(6, 1)
	UI.Toast("+" .. p.Points .. " skill point" .. (p.Points > 1 and "s" or "") .. "! Open Skills to spend.", "good")
	task.delay(1.8, function()
		UI.Tween(f, 0.4, {TextTransparency = 1, Position = f.Position - UDim2.fromOffset(0, 40)})
		task.wait(0.45); f:Destroy()
	end)
end

function Effects.Achievement(p)
	local f = new("Frame", {Parent = screen, Size = UDim2.fromOffset(420, 90), Position = UDim2.new(1, 440, 1, -230), BackgroundColor3 = UI.C.Bg, ZIndex = 70})
	UI.Corner(f, 16); UI.Stroke(f, UI.C.Gold, 3); UI.Gradient(f, UI.Darken(UI.C.Gold, 0.5), UI.C.Bg, 0)
	UI.Label(f, "\u{1F3C6}", UDim2.fromOffset(70, 70), UDim2.fromOffset(10, 10), {ZIndex = 71, NoStroke = true})
	UI.Label(f, "Achievement: " .. p.Name, UDim2.new(1, -100, 0, 30), UDim2.fromOffset(88, 12), {ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
	UI.Label(f, p.Desc .. "  (+" .. p.Gems .. " \u{1F48E})", UDim2.new(1, -100, 0, 24), UDim2.fromOffset(88, 50), {ZIndex = 71, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
	UI.Tween(f, 0.4, {Position = UDim2.new(1, -440, 1, -230)}, Enum.EasingStyle.Back)
	UI.Chime(5, 1.1)
	task.delay(4.5, function()
		UI.Tween(f, 0.3, {Position = UDim2.new(1, 440, 1, -230)})
		task.wait(0.35); f:Destroy()
	end)
end

function Effects.Rebirth(p)
	if p.UserId == player.UserId then
		local overlay = new("Frame", {Parent = screen, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 95})
		UI.Tween(overlay, 0.6, {BackgroundTransparency = 0})
		UI.Chime(12, 0.6)
		Effects.Shake(1.2, 1.2)
		task.wait(0.8)
		rays(overlay, UI.C.Purple, 24, 96)
		local t = UI.Label(overlay, "REBIRTH " .. p.Rebirths .. "!", UDim2.fromOffset(700, 110), UDim2.new(0.5, -350, 0.35, 0), {ZIndex = 97, StrokeTh = 4, TextColor3 = UI.C.Purple})
		local s = new("UIScale", {Parent = t, Scale = 0.2}); UI.Tween(s, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
		UI.Label(overlay, "Permanent bonuses increased!", UDim2.fromOffset(600, 40), UDim2.new(0.5, -300, 0.35, 120), {ZIndex = 97, TextColor3 = UI.C.Dark, NoStroke = true})
		confetti(overlay, 120, {UI.C.Purple, UI.C.Pink, UI.C.Gem, UI.C.Gold}, 98)
		task.wait(3)
		UI.Tween(overlay, 0.8, {BackgroundTransparency = 1})
		for _, c in overlay:GetDescendants() do if c:IsA("TextLabel") then UI.Tween(c, 0.6, {TextTransparency = 1}) end end
		task.wait(0.9)
		overlay:Destroy()
	else
		UI.Toast("\u{267B}\u{FE0F} " .. p.Name .. " reached Rebirth " .. p.Rebirths .. "!", "title")
	end
end

return Effects
