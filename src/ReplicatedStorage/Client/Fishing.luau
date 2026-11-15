-- Client duck netting: renders YOUR ducks swimming in the pool (paths from Shared.PoolSim, so they match
-- the server exactly), shows a hoop where your net will land, and swings the net. The server decides catches.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rarity = require(Shared.Rarity)
local DuckData = require(Shared.DuckData)
local Stats = require(Shared.Stats)
local PoolSim = require(Shared.PoolSim)
local DuckModelBuilder = require(Shared.DuckModelBuilder)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local HUD = require(script.Parent.HUD)
local Effects = require(script.Parent.Effects)
local Panels = require(script.Parent.Panels)
local FP = require(script.Parent.FirstPerson)
local new = UI.new

local Fishing = {}
local player = Players.LocalPlayer
local screen
local world = 0
local ducks = {} -- [u] = {rec, model, root, duck, blink, born, leaving}
local folder
local marker, markerRing, markerFill
local lastSwing = -10
local cooldownLeft = 0
local swinging = false
local target -- predicted duck under the hoop
local highlight
local aimPoint, aimValid, aimWhy = nil, false, ""
-- mom + carrying
local mom = {model = nil, mode = "patrol", from = nil, t0 = 0, target = nil, pos = nil, heading = Vector3.new(0, 0, -1)}
local carrying = nil -- {duckId, model, t}
local escapeUI = {}
local wade = {inWater = false, base = 16, lastSplash = 0}
local stunUntil = 0
-- hunt & pounce
local sneaking, sneakToggle = false, false
local fighting = nil -- current net-fight round info
local fightUI = {}
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function now() return workspace:GetServerTimeNow() end

local function equippedNet()
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("RodId") then return tool end
	return nil
end

local function netStats()
	return State.Data and Stats.Net(State.Data) or {Reach = 13, Radius = 1.7, Grab = 1.7, Cooldown = 1.1, MissCooldown = 1.1}
end

Fishing.Busy = function() return swinging end

---------------------------------------------------------------- duck visuals
local function splash(pos: Vector3, size: number, color: Color3?)
	local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos), Parent = folder})
	local pe = new("ParticleEmitter", {Parent = p, Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(color or Color3.fromRGB(220, 245, 255)),
		LightEmission = 0.4, Size = NumberSequence.new(0.45 * size, 0), Speed = NumberRange.new(4 * size, 8 * size), Lifetime = NumberRange.new(0.4, 0.7),
		SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -30, 0), EmissionDirection = Enum.NormalId.Top, Rate = 0})
	pe:Emit(math.floor(14 * size))
	local ringP = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon,
		Color = Color3.new(1, 1, 1), Transparency = 0.35, Size = Vector3.new(0.08, 0.6, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Parent = folder})
	UI.Tween(ringP, 0.5, {Size = Vector3.new(0.08, 3.5 * size, 3.5 * size), Transparency = 1})
	task.delay(0.9, function() p:Destroy(); ringP:Destroy() end)
end

local function addLabel(entry)
	local r = entry.duck.Rarity
	if r < 3 then return end
	local tier = Rarity.List[r]
	local bb = new("BillboardGui", {Parent = entry.root, Size = UDim2.fromOffset(150, 34), StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0), AlwaysOnTop = r >= 6, MaxDistance = if r >= 6 then 200 else 70, LightInfluence = 0})
	local l = UI.Label(bb, tier.Name, UDim2.fromScale(1, 1), nil, {StrokeTh = 2.5, TextColor3 = Color3.new(1, 1, 1)})
	local g = UI.RarityGradient(l, r)
	if r >= 8 then UI.AnimateGradient(g) end
end

local function addWake(entry)
	local r = entry.duck.Rarity
	if r < 3 then return end
	new("ParticleEmitter", {Parent = entry.root, Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(235, 250, 255)),
		LightEmission = 0.2, Transparency = NumberSequence.new(0.3, 1), Size = NumberSequence.new(0.35, 0.05), Speed = NumberRange.new(0.3, 1),
		Lifetime = NumberRange.new(0.5, 0.9), SpreadAngle = Vector2.new(60, 10), Rate = 6 + r * 3, EmissionDirection = Enum.NormalId.Back})
end

local function spawnEntry(rec, fresh)
	if ducks[rec.u] then return end
	local duck = DuckData.List[rec.id]
	if not duck then return end
	local model = DuckModelBuilder.Build(duck, {Lite = duck.Rarity < 5, Scale = PoolSim.DUCK_SCALE})
	model:SetAttribute("AnimStyle", "swim")
	model:SetAttribute("PoolUid", rec.u)
	local entry = {rec = rec, model = model, root = model.PrimaryPart, duck = duck, blink = 0, born = if fresh then os.clock() else -10}
	ducks[rec.u] = entry
	local cf = PoolSim.CFrame(rec, world, now())
	model:PivotTo(cf)
	model.Parent = folder
	addLabel(entry)
	addWake(entry)
	if fresh then
		splash(cf.Position, 0.8)
		if duck.Rarity >= 5 then
			local tier = Rarity.List[duck.Rarity]
			UI.Toast("\u{2728} A " .. string.upper(tier.Name) .. " duck appeared: " .. duck.Name .. "!", if duck.Rarity >= 7 then "gem" else "good")
			Effects.Flash(tier.Glow, 0.25)
			UI.Chime(math.min(8, duck.Rarity - 1), 1)
		end
	end
end

local function removeEntry(u, how)
	local e = ducks[u]
	if not e then return end
	ducks[u] = nil
	if how == "left" then
		-- dives under and swims off
		local m = e.model
		local from = m:GetPivot()
		splash(from.Position, 0.7)
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.5 and m.Parent do
				local a = (os.clock() - t0) / 0.5
				m:PivotTo(from * CFrame.new(0, -2.2 * a, -1.5 * a) * CFrame.Angles(-0.9 * a, 0, 0))
				RunService.RenderStepped:Wait()
			end
			m:Destroy()
		end)
	else
		e.model:Destroy()
	end
end

local function clearAll()
	for u in ducks do removeEntry(u) end
end

local function setPool(payload)
	if not payload then return end
	clearAll()
	world = payload.world
	for _, rec in payload.ducks do spawnEntry(rec, false) end
end

---------------------------------------------------------------- aim hoop
local function buildMarker()
	marker = new("Part", {Name = "NetAim", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), Parent = folder})
	markerRing = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon,
		Color = Color3.new(1, 1, 1), Transparency = 0.15, Size = Vector3.new(0.06, 3.4, 3.4), CastShadow = false, Parent = folder})
	markerFill = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon,
		Color = Color3.new(1, 1, 1), Transparency = 0.8, Size = Vector3.new(0.05, 3.2, 3.2), CastShadow = false, Parent = folder})
	highlight = new("Highlight", {FillTransparency = 0.6, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(120, 255, 140), FillColor = Color3.fromRGB(120, 255, 140), DepthMode = Enum.HighlightDepthMode.Occluded, Enabled = false, Parent = folder})
end

local function updateAim()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local tool = equippedNet()
	aimPoint, aimValid, aimWhy = nil, false, ""
	if not hrp or world == 0 or player:GetAttribute("InBattleView") then return end
	local center = PoolSim.Center(world)
	local flatMe = Vector3.new(hrp.Position.X, center.Y, hrp.Position.Z)
	local edge = PoolSim.EdgeDistance(world, hrp.Position)
	if carrying then aimWhy = "Get out of the water before Mom catches you!"; return end
	if edge < -18 then aimWhy = "Walk to the duck pond"; return end
	if not tool then aimWhy = "Equip your net (press 1 / tap the net button)"; return end
	if edge < -2.5 then aimWhy = "Wade into the pond to catch a duck!"; return end
	local ns = netStats()
	local hit = FP.AimWater()
	if not hit then
		aimWhy = "Aim at the water"
		return
	end
	local flatHit = Vector3.new(hit.X, center.Y, hit.Z)
	local off = flatHit - flatMe
	local reach = ns.Reach + PoolSim.LUNGE
	if off.Magnitude > reach then
		flatHit = flatMe + off.Unit * reach -- the net (plus your pounce) only reaches so far
		if not PoolSim.InPool(world, flatHit, -0.2) then aimWhy = "Too far, get closer!"; aimPoint = flatHit; return end
	end
	aimPoint, aimValid = flatHit, true
	if sneaking then
		aimWhy = if isTouch then "Sneaking... tap SWING to pounce!" else "Sneaking... click to pounce!"
	else
		aimWhy = if isTouch then "Tap SNEAK so ducks don't hear you!" else "Hold Ctrl to sneak - ducks hear you splashing!"
	end
end

local function predictTarget(t)
	local ns = netStats()
	local best, bestD
	if not aimPoint then return nil end
	for _, e in ducks do
		if PoolSim.Alive(e.rec, t) then
			local p = PoolSim.Pos(e.rec, world, t)
			local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(aimPoint.X, 0, aimPoint.Z)).Magnitude
			if d <= ns.Grab and (not bestD or d < bestD) then best, bestD = e, d end
		end
	end
	return best
end

---------------------------------------------------------------- render loop
local function render(dt)
	debug.profilebegin("DuckPool")
	local t = now()
	updateAim()
	-- swimming ducks
	local parts, cfs = {}, {}
	local surfaceOffset = -0.32
	local clock = os.clock()
	for u, e in ducks do
		if not e.model.Parent then ducks[u] = nil continue end
		if e.flying then continue end
		local cf, blinkN = PoolSim.CFrame(e.rec, world, t)
		if e.dash then
			local a = (clock - e.dash.t0) / 0.35
			if a >= 1 then e.dash = nil else
				local s = a * a * (3 - 2 * a)
				cf = CFrame.new(e.dash.from:Lerp(cf.Position, s) + Vector3.new(0, math.sin(a * math.pi) * 2.2, 0)) * cf.Rotation * CFrame.Angles(0, a * math.pi * 2, 0)
			end
		end
		if blinkN ~= e.blink then
			if e.blink ~= 0 or blinkN > 0 then
				splash(cf.Position, 1.2, Rarity.List[e.duck.Rarity].Glow)
			end
			e.blink = blinkN
		end
		local ph = e.rec.seed % 100
		local bob = math.sin(clock * 3 + ph) * 0.07
		-- bank into turns: compare heading a bit ahead
		local ahead = PoolSim.CFrame(e.rec, world, t + 0.25)
		local turn = cf.LookVector:Cross(ahead.LookVector).Y
		local rise = 0
		local age = clock - e.born
		if age < 0.45 then rise = -1.6 * (1 - age / 0.45) ^ 2 end
		table.insert(parts, e.root)
		table.insert(cfs, cf * CFrame.new(0, surfaceOffset + bob + rise, 0) * CFrame.Angles(math.sin(clock * 2.4 + ph) * 0.05, 0, math.clamp(-turn * 2.2, -0.35, 0.35)))
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	Fishing._RenderMom(dt, t, clock)
	if fighting and fightUI.pivot then
		local a = ((t - fighting.start) / fighting.period) * 360
		fightUI.pivot.Rotation = if a < 0 then 0 else a % 360
		fightUI.duck.Rotation = math.sin(clock * 30) * 12
	end
	Fishing._RenderCarry(dt, clock)
	-- hoop marker
	local ns = netStats()
	cooldownLeft = math.max(0, lastSwing + ns.Cooldown - os.clock())
	if aimPoint and marker then
		local col = if not aimValid then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
		target = if aimValid then predictTarget(t) else nil
		if target then col = Color3.fromRGB(120, 255, 140) end
		local d = ns.Radius * 2
		local pulse = 1 + (if target then math.sin(clock * 12) * 0.05 else 0)
		markerRing.Size = Vector3.new(0.06, d * pulse, d * pulse)
		markerFill.Size = Vector3.new(0.05, d * 0.94 * (1 - cooldownLeft / math.max(ns.Cooldown, 0.01)), d * 0.94 * (1 - cooldownLeft / math.max(ns.Cooldown, 0.01)))
		local cf = CFrame.new(aimPoint + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
		markerRing.CFrame = cf; markerFill.CFrame = cf
		markerRing.Color = col; markerFill.Color = col
		markerRing.Transparency = 0.15; markerFill.Transparency = if cooldownLeft > 0 then 0.75 else 0.82
		highlight.Adornee = target and target.model or nil
		highlight.Enabled = target ~= nil
	elseif marker then
		markerRing.Transparency = 1; markerFill.Transparency = 1
		highlight.Enabled = false
		target = nil
	end
	debug.profileend()
end

---------------------------------------------------------------- catching
local function catchPop(duck, res)
	local tier = Rarity.List[duck.Rarity]
	local card = new("Frame", {Parent = screen, Size = UDim2.fromOffset(330, 64), Position = UDim2.new(0.5, 0, 1, -170), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = UI.C.Bg, ZIndex = 40})
	UI.Corner(card, 12); UI.Stroke(card, UI.C.Outline, 4)
	UI.Studs(card, UI.Darken(UI.C.Bg, 0.45), 0.4, 18, 12)
	local tile = new("Frame", {Parent = card, Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = UI.Darken(tier.Color, 0.1), ZIndex = 41})
	UI.Corner(tile, 8); UI.Stroke(tile, UI.C.Outline, 2.5)
	UI.Sunburst(tile, UDim2.fromScale(1.2, 1.2), nil, UI.Lighten(tier.Color, 0.6), 41, 0.2)
	UI.Viewport(tile, duck.Id, {Z = 42})
	local name = UI.Label(card, duck.Name, UDim2.new(1, -72, 0, 26), UDim2.fromOffset(66, 6), {ZIndex = 41, TextXAlignment = Enum.TextXAlignment.Left})
	UI.RarityGradient(name, duck.Rarity)
	UI.Label(card, tier.Name .. "   +" .. UI.Abbrev(res.coins) .. " \u{1F4B0}  +" .. UI.Abbrev(res.xp) .. " XP", UDim2.new(1, -72, 0, 20), UDim2.fromOffset(66, 34),
		{ZIndex = 41, Font = UI.Body, TextColor3 = UI.C.Sub, TextXAlignment = Enum.TextXAlignment.Left})
	local s = new("UIScale", {Parent = card, Scale = 0.4})
	UI.Tween(s, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
	task.delay(1.6, function()
		UI.Tween(card, 0.3, {Position = card.Position - UDim2.fromOffset(0, 30), BackgroundTransparency = 1})
		UI.Tween(s, 0.3, {Scale = 0.8})
		task.wait(0.3); card:Destroy()
	end)
end

local function flyIntoNet(e)
	e.flying = true
	local m = e.model
	local from = m:GetPivot()
	task.spawn(function()
		local t0 = os.clock()
		local cam = workspace.CurrentCamera
		while os.clock() - t0 < 0.42 and m.Parent do
			local a = (os.clock() - t0) / 0.42
			local goal = cam.CFrame * CFrame.new(0.9, -1.3, -3.2)
			local pos = from.Position:Lerp(goal.Position, a * a) + Vector3.new(0, math.sin(a * math.pi) * 3, 0)
			m:PivotTo(CFrame.new(pos) * from.Rotation * CFrame.Angles(a * 5, a * 8, 0))
			RunService.RenderStepped:Wait()
		end
		m:Destroy()
	end)
end

local submitFight -- defined below
function Fishing.Swing()
	if fighting then submitFight() return end
	if swinging then return end
	if cooldownLeft > 0 then return end
	local tool = equippedNet()
	if not tool then UI.Toast("Equip your net first! (press 1)", "warn") return end
	if player:GetAttribute("InBattle") or player:GetAttribute("InBattleView") then return end
	if carrying then UI.Toast("You're holding a duck - get out of the water!", "warn") return end
	if not aimPoint or not aimValid then
		if aimWhy ~= "" then UI.Toast(aimWhy, "warn") end
		return
	end
	swinging = true
	local ns = netStats()
	lastSwing = os.clock()
	-- POUNCE: lunge toward the aim point, then the net lands where you're aiming
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local d = (aimPoint - hrp.Position) * Vector3.new(1, 0, 1)
		if d.Magnitude > 2 then
			hrp.AssemblyLinearVelocity = d.Unit * math.min(46, d.Magnitude * 6) + Vector3.new(0, 9, 0)
			splash(Vector3.new(hrp.Position.X, PoolSim.Center(world).Y, hrp.Position.Z), 0.8)
		end
	end
	FP.PlayCast()
	task.wait(0.16)
	local aim = aimPoint or aimPoint
	if not aim then swinging = false return end
	local ts = now()
	local predicted = predictTarget(ts)
	UI.Sound("swoosh", 1.1, 0.5)
	local anim = new("StringValue", {Name = "toolanim", Value = "Slash", Parent = tool})
	game:GetService("Debris"):AddItem(anim, 0.5)
	-- the hoop hits the water a beat after the click
	task.delay(0.12, function() splash(aim, 1); UI.Sound("splash", 1.1, 0.55) end)
	local res = State.Request("Swing", aim, ts)
	swinging = false
	if not res.ok then
		if res.err and res.err ~= "cooldown" then UI.Toast(res.err, "warn") end
		return
	end
	if not res.hit then
		lastSwing = os.clock() - (ns.Cooldown - ns.MissCooldown)
		local l = new("BillboardGui", {Parent = marker, Size = UDim2.fromOffset(140, 40), StudsOffsetWorldSpace = Vector3.new(0, 2, 0), AlwaysOnTop = true})
		marker.CFrame = CFrame.new(aim)
		local txt = if res.dodged then "DODGED!" elseif predicted then "So close!" else "Missed!"
		if res.dodged then UI.Sound("swoosh", 1.6, 0.6); UI.Sound("quack", 1.25, 0.55) end
		UI.Label(l, txt, UDim2.fromScale(1, 1), nil, {TextColor3 = Color3.fromRGB(255, 120, 120), StrokeTh = 2.5})
		UI.Tween(l, 0.6, {StudsOffsetWorldSpace = Vector3.new(0, 4, 0)})
		task.delay(0.6, function() l:Destroy() end)
		return
	end
	local e = ducks[res.u]
	if e then
		ducks[res.u] = nil
		flyIntoNet(e)
	end
	UI.Sound("splash", 0.9, 0.7)
	UI.Sound("squeak", 1, 0.7)
	if res.fight then
		UI.Sound("quack", 0.8, 0.8) -- angry duck
		Fishing._Fight(res.fight)
		return
	end
	Fishing._StartCarry(res.duckId)
end

---------------------------------------------------------------- net fight (timing ring)
local function closeFight()
	fighting = nil
	if fightUI.catcher then fightUI.catcher.Visible = false end
	if fightUI.root then fightUI.root.Visible = false end
	if fightUI.vp then fightUI.vp:Destroy(); fightUI.vp = nil end
end

local GOLD_SEQ = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 160, 18))})

local function buildFightUI()
	-- full-screen catcher: a click / tap ANYWHERE counts while the duck is fighting
	local catcher = new("TextButton", {Parent = screen, Name = "FightCatcher", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 1, 80),
		Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Visible = false, ZIndex = 58, Modal = true})
	fightUI.catcher = catcher

	-- panel: studded brown body + shiny studded gold header (same look as the menus)
	local root = new("Frame", {Parent = screen, Name = "NetFight", Size = UDim2.fromOffset(380, 476), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UI.C.Bg, Visible = false, ZIndex = 60, Active = false})
	UI.Corner(root, 14); UI.Studs(root, UI.Darken(UI.C.Bg, 0.45), 0.35, 26, 14); UI.Stroke(root, UI.C.Outline, 5)
	fightUI.root = root
	local header = new("Frame", {Parent = root, Name = "Header", Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = UI.C.Gold, ZIndex = 61})
	UI.Corner(header, 14); UI.Gradient(header, GOLD_SEQ, nil, 90)
	new("Frame", {Parent = header, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundColor3 = Color3.fromRGB(242, 160, 18), BorderSizePixel = 0, ZIndex = 61})
	UI.Studs(header, Color3.fromRGB(214, 130, 0), 0.35, 22, 14)
	new("Frame", {Parent = header, Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = UI.C.Outline, BorderSizePixel = 0, ZIndex = 62})
	local iconHolder = new("Frame", {Parent = header, Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(-14, -16), BackgroundTransparency = 1, ZIndex = 63})
	UI.Sunburst(iconHolder, UDim2.fromScale(1.5, 1.5), nil, Color3.fromRGB(255, 250, 210), 63, 0.25)
	UI.Icon(iconHolder, "net", UDim2.fromScale(1, 1), nil, {ZIndex = 64, Rotation = -10})
	fightUI.title = UI.Label(header, "DUCK FIGHT!", UDim2.new(1, -86, 0, 42), UDim2.fromOffset(72, 10), {TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63, StrokeTh = 3.5})

	-- rarity tag under the header
	local tag = new("Frame", {Parent = root, Size = UDim2.fromOffset(220, 30), Position = UDim2.new(0.5, 0, 0, 78), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Gold, ZIndex = 61})
	UI.Corner(tag, 10); UI.Stroke(tag, UI.C.Outline, 3)
	fightUI.tag = tag
	fightUI.tagText = UI.Label(tag, "", UDim2.new(1, -12, 1, -4), UDim2.fromOffset(6, 2), {ZIndex = 62, StrokeTh = 2.5})

	-- dial: gold rim, dark studded face, tick marks, thick green zone, white needle, duck in the hub
	local rim = new("Frame", {Parent = root, Size = UDim2.fromOffset(272, 272), Position = UDim2.new(0.5, 0, 0, 118), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Gold, ZIndex = 61})
	UI.Corner(rim, 136); UI.Gradient(rim, GOLD_SEQ, nil, 90); UI.Stroke(rim, UI.C.Outline, 5)
	local dial = new("Frame", {Parent = rim, Size = UDim2.fromOffset(244, 244), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Bg2, ZIndex = 62})
	UI.Corner(dial, 122); UI.Stroke(dial, UI.C.Outline, 4)
	UI.Studs(dial, UI.Darken(UI.C.Bg2, 0.45), 0.4, 20, 122)
	fightUI.dial = dial
	for k = 0, 23 do
		local ang = math.rad(k * 15)
		local big = k % 6 == 0
		local tk = new("Frame", {Parent = dial, Size = UDim2.fromOffset(big and 6 or 4, big and 16 or 9), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(ang) * 112, 0.5, -math.cos(ang) * 112), Rotation = k * 15, BackgroundColor3 = UI.C.Sub, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 63})
		UI.Corner(tk, 2)
	end
	fightUI.dots = {}
	for k = 1, 40 do
		local dot = new("Frame", {Parent = dial, Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Green, ZIndex = 64})
		UI.Corner(dot, 12)
		fightUI.dots[k] = dot
	end
	local pivot = new("Frame", {Parent = dial, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 65})
	local needle = new("Frame", {Parent = pivot, Size = UDim2.fromOffset(12, 108), Position = UDim2.new(0.5, -6, 0.5, -108), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 66})
	UI.Corner(needle, 6); UI.Stroke(needle, UI.C.Outline, 3)
	local tip = new("Frame", {Parent = pivot, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0.5, 0, 0.5, -106), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = UI.C.Red, ZIndex = 67})
	UI.Corner(tip, 4); UI.Stroke(tip, UI.C.Outline, 3)
	fightUI.pivot = pivot
	local hub = new("Frame", {Parent = dial, Size = UDim2.fromOffset(92, 92), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Gold, ZIndex = 68})
	UI.Corner(hub, 46); UI.Stroke(hub, UI.C.Outline, 4)
	fightUI.hubGrad = UI.Gradient(hub, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170), 90)
	fightUI.duck = hub

	-- instruction strip (green, like a button) + round pips
	local strip = new("Frame", {Parent = root, Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0.5, 0, 0, 402), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Green, ZIndex = 61})
	UI.Corner(strip, 12); UI.Stroke(strip, UI.C.Outline, 4)
	UI.Gradient(strip, Color3.fromRGB(130, 240, 90), Color3.fromRGB(50, 170, 30), 90)
	fightUI.sub = UI.Label(strip, "", UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), {ZIndex = 62, StrokeTh = 2.5})
	fightUI.stripScale = new("UIScale", {Parent = strip})
	fightUI.pips = new("Frame", {Parent = root, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -12), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, ZIndex = 62})
	UI.List(fightUI.pips, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center)
	fightUI.scale = new("UIScale", {Parent = root})
	-- sneak indicator + phone sneak button
	fightUI.sneakLbl = UI.Label(screen, "\u{1F92B} SNEAKING", UDim2.fromOffset(220, 30), UDim2.new(0.5, -110, 0.5, 40), {ZIndex = 5, TextColor3 = Color3.fromRGB(170, 230, 255), StrokeTh = 2.5, Visible = false})
	if isTouch then
		-- rides on top of the SWING button wherever the phone layout puts it
		local b = UI.Button(HUD.CastButton, {Text = "SNEAK", Color = UI.C.Blue, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 0, -66), Radius = 12, Z = 6, OnClick = function()
			sneakToggle = not sneakToggle
			UI.Toast(if sneakToggle then "Sneaking - ducks won't hear you (rare ducks still notice up close)" else "Stopped sneaking", "info")
		end})
		fightUI.sneakBtn = b
	end
end

local function showRound(info)
	fighting = info
	local root = fightUI.root
	root.Visible = true
	fightUI.catcher.Visible = true
	local duck = DuckData.List[info.duckId]
	local tier = duck and Rarity.List[duck.Rarity]
	local col = tier and tier.Color or UI.C.Gold
	fightUI.title.Text = "IT'S FIGHTING BACK!"
	fightUI.tagText.Text = (if tier then string.upper(tier.Name) .. " " else "") .. string.upper(duck and duck.Name or "DUCK")
	fightUI.tag.BackgroundColor3 = col
	fightUI.duck.BackgroundColor3 = col
	if not fightUI.vp or fightUI.vpId ~= info.duckId then
		if fightUI.vp then fightUI.vp:Destroy() end
		fightUI.vp = UI.Viewport(fightUI.duck, info.duckId, {Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(0.5, 0.52), Anchor = Vector2.new(0.5, 0.5), Z = 69, Immediate = true, Zoom = 1.25})
		fightUI.vpId = info.duckId
	end
	fightUI.sub.Text = "ON GREEN? " .. (if isTouch then "TAP" else "CLICK") .. " ANYWHERE!"
	-- green zone as a solid arc of overlapping dots
	local R = 112
	local n = #fightUI.dots
	for k, dot in fightUI.dots do
		local a = math.rad(info.center - info.zone / 2 + (k - 1) / (n - 1) * info.zone)
		dot.Position = UDim2.new(0.5, math.sin(a) * R, 0.5, -math.cos(a) * R)
	end
	for _, c in fightUI.pips:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	for k = 1, info.rounds do
		local pip = new("Frame", {Parent = fightUI.pips, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = if k < info.round then UI.C.Green elseif k == info.round then UI.C.Gold else UI.C.Dark, LayoutOrder = k, ZIndex = 62})
		UI.Corner(pip, 12); UI.Stroke(pip, UI.C.Outline, 3)
	end
	fightUI.pips.Visible = info.rounds > 1
	local sc = fightUI.scale
	local fit = math.min(1, (screen.AbsoluteSize.Y - 40) / 500)
	sc.Scale = fit * 0.6; UI.Tween(sc, 0.2, {Scale = fit}, Enum.EasingStyle.Back)
	fightUI.stripScale.Scale = 1.15; UI.Tween(fightUI.stripScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
	UI.Sound("swoosh", 1.4, 0.4)
end

local busyFight = false
local lastSubmit = 0
submitFight = function()
	-- one press = one try (a tap on a button also reaches InputBegan, so drop the echo)
	if not fighting or busyFight or os.clock() - lastSubmit < 0.3 then return end
	lastSubmit = os.clock()
	busyFight = true
	local res = State.Request("Struggle", now())
	busyFight = false
	if not res.ok then return end
	if res.next then
		UI.Chime(3, 1.2)
		Effects.Flash(Color3.fromRGB(120, 255, 140), 0.12)
		showRound(res.next)
	elseif res.carry then
		closeFight()
		UI.Chime(6, 1)
		Fishing._StartCarry(res.duckId)
	elseif res.lost then
		closeFight()
		UI.Sound("swoosh", 0.7, 0.8)
		UI.Sound("fail", 1, 0.45)
		UI.Toast("It wriggled out of your net and swam off!", "warn")
	end
end

function Fishing._Fight(info)
	showRound(info)
end

---------------------------------------------------------------- carrying + mom
local function hum() return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
local function root() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end

local function buildEscapeUI()
	escapeUI.vignette = new("Frame", {Parent = screen, Name = "DangerVignette", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Visible = false})
	escapeUI.stroke = new("UIStroke", {Parent = escapeUI.vignette, Color = Color3.fromRGB(230, 30, 30), Thickness = 60, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	escapeUI.banner = new("Frame", {Parent = screen, Name = "EscapeBanner", Size = UDim2.fromOffset(460, 76), Position = UDim2.new(0.5, 0, 0, 92), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 40, 40), Visible = false, ZIndex = 30})
	UI.Corner(escapeUI.banner, 14); UI.Stroke(escapeUI.banner, UI.C.Outline, 4)
	UI.Studs(escapeUI.banner, Color3.fromRGB(150, 25, 25), 0.45, 18, 12)
	escapeUI.title = UI.Label(escapeUI.banner, "GET OUT OF THE WATER!", UDim2.new(1, -16, 0, 40), UDim2.fromOffset(8, 4), {ZIndex = 31, TextColor3 = Color3.fromRGB(255, 240, 120), StrokeTh = 3})
	escapeUI.sub = UI.Label(escapeUI.banner, "", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 44), {ZIndex = 31, Font = UI.Body, TextColor3 = Color3.new(1, 1, 1)})
	escapeUI.scale = new("UIScale", {Parent = escapeUI.banner})
end

local function bigText(text, color, sub)
	local f = new("Frame", {Parent = screen, Size = UDim2.fromOffset(520, 110), Position = UDim2.fromScale(0.5, 0.36), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 45})
	UI.Label(f, text, UDim2.new(1, 0, 0, 64), nil, {ZIndex = 46, TextColor3 = color, StrokeTh = 4})
	if sub then UI.Label(f, sub, UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 66), {ZIndex = 46, Font = UI.Body, TextColor3 = Color3.new(1, 1, 1)}) end
	local sc = new("UIScale", {Parent = f, Scale = 0.3})
	UI.Tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
	task.delay(1.8, function() UI.Tween(sc, 0.25, {Scale = 0.6}); task.wait(0.25); f:Destroy() end)
end

function Fishing._StartCarry(duckId)
	Fishing._EndCarry()
	local duck = DuckData.List[duckId]
	if not duck then return end
	local m = DuckModelBuilder.Build(duck, {Lite = true, NoEffects = true, Scale = 0.42})
	m:SetAttribute("Rig", nil)
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.CastShadow = false; p.CanQuery = false end end
	m.Name = "CarriedDuck"
	m.Parent = workspace.CurrentCamera
	carrying = {duckId = duckId, model = m, t = os.clock()}
	escapeUI.banner.Position = UDim2.new(0.5, 0, 0, (HUD.TopY or 66) + 26)
	escapeUI.banner.Visible = true; escapeUI.vignette.Visible = true
	escapeUI.scale.Scale = 0.4
	UI.Tween(escapeUI.scale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
	local tier = Rarity.List[duck.Rarity]
	UI.Chime(math.min(8, duck.Rarity), 1)
	UI.Toast("You scooped " .. duck.Name .. " (" .. tier.Name .. ")! Now RUN!", "good")
end

function Fishing.IsCarrying() return carrying ~= nil end

function Fishing._EndCarry()
	if carrying then
		if carrying.model then carrying.model:Destroy() end
		carrying = nil
	end
	if escapeUI.banner then escapeUI.banner.Visible = false; escapeUI.vignette.Visible = false end
end

function Fishing._RenderCarry(dt, clock)
	if not carrying then return end
	local m = carrying.model
	local cam = workspace.CurrentCamera
	local wiggle = CFrame.Angles(math.sin(clock * 16) * 0.25, math.sin(clock * 11) * 0.4, 0)
	if FP.IsFirstPerson() then
		m:PivotTo(cam.CFrame * CFrame.new(0.95, -1.05, -2.4) * CFrame.Angles(0, math.pi * 0.85, 0) * wiggle)
	else
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		local tip = tool and (tool:FindFirstChild("Bag", true) or tool:FindFirstChild("Tip", true))
		local hrp = root()
		local at = if tip then tip.CFrame elseif hrp then hrp.CFrame * CFrame.new(1.5, 1, -1) else cam.CFrame
		m:PivotTo(CFrame.new(at.Position + Vector3.new(0, 0.3, 0)) * at.Rotation * wiggle)
	end
	-- banner: distance to the shore + how close Mom is
	local hrp = root()
	if hrp and world ~= 0 then
		local edge = PoolSim.EdgeDistance(world, hrp.Position)
		local toShore = math.max(0, edge + PoolSim.ESCAPE_MARGIN)
		local momD = if mom.pos then (Vector3.new(mom.pos.X, 0, mom.pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude else 99
		local momTxt = if mom.mode ~= "chase" then "Mom noticed you..." else string.format("MOM IS %d STUDS AWAY!", math.floor(momD))
		escapeUI.sub.Text = string.format("Shore: %d studs   |   %s", math.ceil(toShore), momTxt)
		local danger = if mom.mode == "chase" then math.clamp(1 - (momD - PoolSim.MOM_CATCH) / 18, 0, 1) else 0.1
		escapeUI.stroke.Transparency = 1 - danger * (0.55 + 0.25 * math.sin(clock * 14))
		escapeUI.banner.Rotation = math.sin(clock * 20) * 2 * danger
	end
end

local function momTargetCF(pos, clock, chasing)
	local y = pos.Y - 1.05 + math.sin(clock * (if chasing then 9 else 2.2)) * (if chasing then 0.2 else 0.08)
	return CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(pos.X, y, pos.Z) + mom.heading)
end

function Fishing._RenderMom(dt, t, clock)
	if world == 0 then return end
	if not mom.model or mom.model:GetAttribute("World") ~= world then
		if mom.model then mom.model:Destroy() end
		local ok, m = pcall(DuckModelBuilder.BuildMom, {Scale = PoolSim.MOM_SCALE})
		if not ok then warn("[Fishing] mom build failed", m) return end
		m:SetAttribute("World", world)
		for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.CanQuery = false end end
		local bb = new("BillboardGui", {Parent = m.PrimaryPart, Size = UDim2.fromOffset(120, 30), StudsOffsetWorldSpace = Vector3.new(0, 10.5, 0), MaxDistance = 120, LightInfluence = 0})
		mom.label = UI.Label(bb, "MOM", UDim2.fromScale(1, 1), nil, {StrokeTh = 2.5, TextColor3 = Color3.fromRGB(255, 190, 210)})
		m.Parent = folder
		mom.model = m
		mom.pos = PoolSim.MomPatrol(world, t)
	end
	local want
	if mom.mode == "patrol" then
		want = PoolSim.MomPatrol(world, t)
	elseif mom.mode == "return" then
		local done
		want, done = PoolSim.MomReturning(world, mom.from, mom.t0, t)
		if done then mom.mode = "patrol" end
	else
		want = mom.target or mom.pos
	end
	local prev = mom.pos or want
	local chasing = mom.mode == "chase"
	mom.pos = if chasing then prev:Lerp(want, 1 - math.exp(-14 * dt)) else want
	local v = (mom.pos - prev) * Vector3.new(1, 0, 1)
	if chasing and carrying then
		local hrp = root()
		if hrp then v = (hrp.Position - mom.pos) * Vector3.new(1, 0, 1) end
	end
	if v.Magnitude > 1e-3 then mom.heading = mom.heading:Lerp(v.Unit, math.min(1, dt * 10)).Unit end
	local m = mom.model
	if m.PrimaryPart then m.PrimaryPart.CFrame = momTargetCF(mom.pos, clock, chasing) end
	local pin = m:FindFirstChild("J_Pin")
	local motor = pin and pin:FindFirstChild("J_Pin")
	if motor then
		motor.Transform = if chasing then CFrame.Angles(math.sin(clock * 15) * 0.9, 0, math.sin(clock * 7) * 0.2) else CFrame.Angles(math.sin(clock * 1.5) * 0.08, 0, 0)
	end
	local angry, calm = m:FindFirstChild("BrowsAngry"), m:FindFirstChild("BrowsCalm")
	if angry and calm then
		local a = if chasing then 0 else 1
		if angry.Transparency ~= a then angry.Transparency = a; calm.Transparency = 1 - a end
	end
	if mom.label then
		local txt = if chasing then "MOM (ANGRY!)" else "MOM"
		if mom.label.Text ~= txt then mom.label.Text = txt; mom.label.TextColor3 = if chasing then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 190, 210) end
	end
	if chasing and clock - (mom.lastSplash or 0) > 0.25 then
		mom.lastSplash = clock
		splash(mom.pos, 1.1)
	end
end

local function setMom(st)
	if not st then return end
	if st.m == "chase" and mom.mode ~= "chase" then
		-- Mom spotted you: an angry honk from her
		UI.SoundAt("quack", mom.model and mom.model.PrimaryPart, 0.55, 1)
		UI.Sound("quack", 0.55, 0.5)
	end
	mom.mode = st.m or "patrol"
	mom.t0 = st.t0 or 0
	mom.from = st.from
	if st.m == "chase" and st.p then mom.target = st.p; if not mom.pos then mom.pos = st.p end end
end

-- wading: slower in the water, splashy footsteps
local function wadeStep()
	local h, hrp = hum(), root()
	if not h or not hrp or world == 0 then return end
	local inWater = PoolSim.EdgeDistance(world, hrp.Position) > 0 and math.abs(hrp.Position.Y - PoolSim.Center(world).Y) < 6
	if os.clock() < stunUntil then
		h.WalkSpeed = 0
		return
	end
	if fighting then h.WalkSpeed = 0; return end
	sneaking = (sneakToggle or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)) and inWater
	h.CameraOffset = if sneaking then Vector3.new(0, -1.3, 0) else Vector3.zero
	if fightUI.sneakLbl then fightUI.sneakLbl.Visible = sneaking end
	if fightUI.sneakBtn then
		local col = if sneakToggle then UI.C.Green else UI.C.Blue
		if fightUI.sneakCol ~= col then fightUI.sneakCol = col; UI.SetColor(fightUI.sneakBtn, col) end
	end
	if inWater and wade.inWater and not fighting then
		local want = if sneaking then PoolSim.SNEAK_SPEED else math.min(wade.base, PoolSim.WADE_SPEED)
		if h.WalkSpeed ~= want then h.WalkSpeed = want end
	end
	if inWater ~= wade.inWater then
		wade.inWater = inWater
		if inWater then
			wade.base = if h.WalkSpeed > 0 then h.WalkSpeed else 16
			h.WalkSpeed = math.min(wade.base, PoolSim.WADE_SPEED)
			splash(Vector3.new(hrp.Position.X, PoolSim.Center(world).Y, hrp.Position.Z), 1)
			UI.Sound("splash", 1.2, 0.35)
		else
			h.WalkSpeed = wade.base
		end
	elseif h.WalkSpeed == 0 then
		h.WalkSpeed = if inWater then math.min(wade.base, PoolSim.WADE_SPEED) else wade.base
	end
	if inWater and not sneaking and h.MoveDirection.Magnitude > 0.1 and os.clock() - wade.lastSplash > 0.32 then
		wade.lastSplash = os.clock()
		splash(Vector3.new(hrp.Position.X, PoolSim.Center(world).Y, hrp.Position.Z) + h.MoveDirection * 1.2, 0.45)
	end
end
Fishing.Cast = Fishing.Swing -- debug hook compatibility

function Fishing.Init(s)
	screen = s
	folder = workspace:FindFirstChild("PoolDucks") or new("Folder", {Name = "PoolDucks", Parent = workspace})
	buildMarker()
	buildEscapeUI()
	buildFightUI()
	State.OnEvent("PoolSet", function(p) setPool(p); if p then setMom(p.mom) end; Fishing._EndCarry() end)
	State.OnEvent("MomMode", setMom)
	State.OnEvent("MomPos", function(p) if mom.mode == "chase" then mom.target = p.p end end)
	State.OnEvent("PoolRepath", function(p)
		local e = ducks[p.rec.u]
		if not e then return end
		e.rec = p.rec
		if p.panic then
			-- "!" pop over the startled duck
			local bb = new("BillboardGui", {Parent = e.root, Size = UDim2.fromOffset(60, 60), StudsOffsetWorldSpace = Vector3.new(0, 3, 0), AlwaysOnTop = true, LightInfluence = 0})
			local l = UI.Label(bb, "!", UDim2.fromScale(1, 1), nil, {TextColor3 = Color3.fromRGB(255, 70, 70), StrokeTh = 3})
			local sc = new("UIScale", {Parent = l, Scale = 0.3})
			UI.Tween(sc, 0.25, {Scale = 1.2}, Enum.EasingStyle.Back)
			task.delay(1.1, function() bb:Destroy() end)
			splash(e.model:GetPivot().Position, 0.7)
			UI.SoundAt("quack", e.root, 1.15, 0.8) -- startled quack
		end
	end)
	State.OnEvent("FightLost", function()
		if fighting then closeFight(); UI.Sound("fail", 1, 0.45); UI.Toast("Too slow! The duck wriggled free.", "warn") end
	end)
	State.OnEvent("PoolDodge", function(p)
		local e = ducks[p.rec.u]
		if not e then return end
		e.rec = p.rec
		e.dash = {from = p.from, t0 = os.clock()}
		splash(p.from, 1, Rarity.List[e.duck.Rarity].Glow)
		UI.SoundAt("quack", e.root, 1.3, 0.8)
	end)
	State.OnEvent("MomCaught", function(p)
		Fishing._EndCarry()
		local h, hrp = hum(), root()
		if hrp then
			hrp.AssemblyLinearVelocity = (p.dir or Vector3.zAxis) * 55 + Vector3.new(0, 38, 0)
		end
		if h then h:ChangeState(Enum.HumanoidStateType.Freefall) end
		stunUntil = os.clock() + 1
		UI.Sound("swoosh", 0.6, 0.9)
		UI.Sound("boing", 0.8, 0.7)
		UI.Sound("quack", 0.6, 0.9)
		task.delay(0.5, function() UI.Sound("fail", 1, 0.45) end)
		Effects.Flash(Color3.fromRGB(255, 60, 60), 0.35)
		local duck = DuckData.List[p.duckId]
		bigText("BONK! MOM GOT YOU!", Color3.fromRGB(255, 90, 90), (duck and duck.Name or "The duck") .. " swam back to the pond")
		HUD.SetStreak(0)
	end)
	State.OnEvent("CarryEnd", function(res)
		Fishing._EndCarry()
		if res.kept then
			local duck = DuckData.List[res.duckId]
			HUD.SetStreak(res.streak, res.streakBonus)
			UI.Sound("splash", 0.8, 0.5)
			UI.Sound("coin", 1, 0.6)
			if res.isNew or duck.Rarity >= 4 then
				Effects.Reveal({duckId = res.duckId, coins = res.coins, xp = res.xp, isNew = res.isNew})
			else
				bigText("SAFE!", Color3.fromRGB(120, 255, 140))
				UI.Sound("sting", 1, 0.4)
				catchPop(duck, res)
			end
		elseif res.why == "lost" or res.why == "world" then
			UI.Toast("You dropped the duck and it swam back to the pond.", "warn")
		end
	end)
	task.spawn(function()
		while true do task.wait(0.1); pcall(wadeStep) end
	end)
	State.OnEvent("PoolAdd", function(rec)
		if world ~= 0 then spawnEntry(rec, true) end
	end)
	State.OnEvent("PoolRemove", function(p)
		-- a catch we made ourselves is already flying into the net; this just cleans up anything left over
		if p.why == "caught" then task.delay(0.6, function() removeEntry(p.u, "caught") end)
		elseif p.why == "taken" then
			-- another player scooped it
			local e = ducks[p.u]
			if e then splash(e.model:GetPivot().Position, 1) end
			removeEntry(p.u, "caught")
		else removeEntry(p.u, p.why) end
	end)
	State.OnEvent("StreakReset", function() HUD.SetStreak(0) end)
	task.spawn(function()
		for _ = 1, 20 do
			local r = State.Request("PoolSync")
			if r.ok then
				setPool(r); setMom(r.mom)
				if r.carry then Fishing._StartCarry(r.carry.duckId) end
				return
			end
			task.wait(1)
		end
	end)
	RunService:BindToRenderStep("DuckPool", Enum.RenderPriority.Camera.Value + 2, render)
	HUD.CastButton.Activated:Connect(function() Fishing.Swing() end)
	-- clicking with the net equipped swings it
	local function hookTool(tool)
		if tool:IsA("Tool") and tool:GetAttribute("RodId") and not tool:GetAttribute("Hooked") then
			tool:SetAttribute("Hooked", true)
			tool.Activated:Connect(function() Fishing.Swing() end)
		end
	end
	local function watchChar(char)
		char.ChildAdded:Connect(hookTool)
		for _, c in char:GetChildren() do hookTool(c) end
	end
	player.CharacterAdded:Connect(watchChar)
	if player.Character then watchChar(player.Character) end
	UserInputService.InputBegan:Connect(function(input, gp)
		-- during a duck fight ANY click / tap / swing key counts, even over other buttons
		if fighting then
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space
				or input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonA then
				submitFight()
			end
			return
		end
		if gp then return end
		if (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonX) and not Panels.Current() then
			Fishing.Swing()
		end
	end)
	-- swing button state: only touch the UI when something actually changed
	-- (rewriting TextScaled labels/gradients every tick is what made the HUD stutter)
	task.spawn(function()
		local lastReady, lastLabel, lastHint, lastNet
		while true do
			task.wait(0.1)
			local ready = aimValid and cooldownLeft <= 0
			if ready ~= lastReady then lastReady = ready; UI.SetColor(HUD.CastButton, if ready then UI.C.Green else Color3.fromRGB(120, 110, 105)) end
			local label = if cooldownLeft > 0 then string.format("%.1f", cooldownLeft) else "SWING"
			if label ~= lastLabel then lastLabel = label; HUD.CastButton.Label.Text = label end
			if aimWhy ~= lastHint then lastHint = aimWhy; HUD.CastHint.Text = aimWhy end
			local hasNet = equippedNet() ~= nil
			if hasNet ~= lastNet then lastNet = hasNet; UI.SetColor(HUD.RodButton, if hasNet then UI.C.Green else UI.C.Card) end
		end
	end)
end

return Fishing
