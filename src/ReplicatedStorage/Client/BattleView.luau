-- Battle presentation (boss + PvP): 3D arena, animations, damage numbers, HP bars, controls, results.
-- Purely visual: every outcome comes from the server's event log.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local DuckData = require(Shared.DuckData)
local Rarity = require(Shared.Rarity)
local WorldData = require(Shared.WorldData)
local Stats = require(Shared.Stats)
local DuckModelBuilder = require(Shared.DuckModelBuilder)
local BossModelBuilder = require(Shared.BossModelBuilder)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local Effects = require(script.Parent.Effects)
local WorldFx = require(script.Parent.WorldFx)
local HUD = require(script.Parent.HUD)
local Anim = require(script.Parent.RigAnimator)
local new = UI.new

local BV = {}
local player = Players.LocalPlayer
local screen
local ARENA = Vector3.new(0, 1200, 3200)
local active -- current battle context

local STATUS_ICON = {burn = "\u{1F525}", freeze = "\u{2744}\u{FE0F}", poison = "\u{2620}\u{FE0F}", stun = "\u{1F4AB}", shield = "\u{1F6E1}\u{FE0F}", buff = "\u{2B06}\u{FE0F}", enrage = "\u{1F621}"}
local KIND_COLOR = {burn = Color3.fromRGB(255, 120, 40), freeze = Color3.fromRGB(150, 230, 255), poison = Color3.fromRGB(140, 255, 80), aoe = Color3.fromRGB(255, 200, 80),
	pierce = Color3.fromRGB(200, 90, 255), nuke = Color3.fromRGB(255, 230, 90), crit = Color3.fromRGB(255, 80, 80), drain = Color3.fromRGB(200, 60, 120), stun = Color3.fromRGB(255, 240, 120),
	multi = Color3.fromRGB(120, 220, 255), execute = Color3.fromRGB(255, 60, 60), shield = Color3.fromRGB(120, 200, 255), buff = Color3.fromRGB(255, 180, 60), heal = Color3.fromRGB(100, 255, 120),
	single = Color3.fromRGB(255, 255, 255), enrage = Color3.fromRGB(255, 50, 50)}

---------------------------------------------------------------- arena
local function part(parent, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	if shape == "cyl" then p.Shape = Enum.PartType.Cylinder elseif shape == "ball" then p.Shape = Enum.PartType.Ball end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic; p.Parent = parent
	return p
end

local function buildArena(worldId)
	local w = WorldData.List[worldId] or WorldData.List[1]
	local m = Instance.new("Model"); m.Name = "BattleArena"
	part(m, Vector3.new(4, 110, 110), CFrame.new(ARENA - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), w.Ground, Enum.Material.Slate, "cyl")
	part(m, Vector3.new(4.2, 60, 60), CFrame.new(ARENA - Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), w.Accent:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Marble, "cyl")
	local ring = part(m, Vector3.new(4, 63.5, 63.5), CFrame.new(ARENA - Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), w.Accent, Enum.Material.Neon, "cyl")
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local pos = ARENA + Vector3.new(math.cos(a) * 46, 8, math.sin(a) * 46)
		part(m, Vector3.new(3, 20, 3), CFrame.new(pos), w.Ground:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Marble)
		local orb = part(m, Vector3.new(2.4, 2.4, 2.4), CFrame.new(pos + Vector3.new(0, 11.5, 0)), w.Accent, Enum.Material.Neon, "ball")
		local l = Instance.new("PointLight"); l.Color = w.Accent; l.Range = 22; l.Brightness = 1.5; l.Parent = orb
	end
	-- backdrop dome
	for i = 1, 40 do
		local a, h = math.random() * math.pi * 2, math.random(10, 120)
		part(m, Vector3.new(0.8, 0.8, 0.8), CFrame.new(ARENA + Vector3.new(math.cos(a) * 160, h, math.sin(a) * 160)), Color3.new(1, 1, 1), Enum.Material.Neon, "ball")
	end
	m.Parent = workspace
	return m
end

---------------------------------------------------------------- unit visuals
local function billboard(adornee, offset)
	local bb = new("BillboardGui", {Parent = adornee, Size = UDim2.fromOffset(170, 56), StudsOffsetWorldSpace = offset, AlwaysOnTop = true, LightInfluence = 0})
	return bb
end

local function makeUnitVisual(ctx, u, cf)
	local model
	if u.BossId then
		model = BossModelBuilder.Build(Config.Bosses[u.BossId])
	else
		model = DuckModelBuilder.Build(DuckData.List[u.DuckId], {Scale = 1.8})
	end
	model:SetAttribute("AnimStyle", "battle")
	model:PivotTo(cf)
	model.Parent = ctx.Arena
	WorldFx.RegisterHubs(model)
	Anim.Register(model)
	if u.BossId then task.delay(0.6, function() Anim.Play(model, "roar") end) end
	local _, size = model:GetBoundingBox()
	local anchor = part(ctx.Arena, Vector3.new(0.2, 0.2, 0.2), cf + Vector3.new(0, size.Y + 1, 0), Color3.new(1, 1, 1))
	anchor.Transparency = 1
	local bb = billboard(anchor, Vector3.new(0, 1.5, 0))
	bb.Size = if u.BossId then UDim2.fromOffset(0, 0) else UDim2.fromOffset(170, 56)
	local name = UI.Label(bb, (u.Level and ("Lv" .. u.Level .. " ") or "") .. u.Name, UDim2.new(1, 0, 0, 22), nil, {Font = UI.Body, StrokeTh = 2})
	local bg = new("Frame", {Parent = bb, Size = UDim2.new(1, -10, 0, 16), Position = UDim2.fromOffset(5, 26), BackgroundColor3 = UI.C.Dark})
	UI.Corner(bg, 8); UI.Stroke(bg, UI.C.Outline, 2)
	local fill = new("Frame", {Parent = bg, Size = UDim2.fromScale(1, 1), BackgroundColor3 = if u.Side == ctx.MySide then UI.C.Green else UI.C.Red})
	UI.Corner(fill, 8)
	local status = UI.Label(bb, "", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 43), {NoStroke = true})
	local vis = {Unit = u, Model = model, Root = model.PrimaryPart, Home = cf, Anchor = anchor, Fill = fill, Status = status, Statuses = {},
		Height = size.Y, Width = math.max(size.X, size.Z)}
	ctx.Vis[u.Id] = vis
	return vis
end

local function setHp(ctx, id, hp)
	local v = ctx.Vis[id]
	if not v then return end
	v.Unit.Hp = hp
	local frac = math.clamp(hp / v.Unit.MaxHp, 0, 1)
	UI.Tween(v.Fill, 0.25, {Size = UDim2.fromScale(frac, 1)})
	if v.Unit.BossId and ctx.BossBar then
		UI.Tween(ctx.BossBar, 0.3, {Size = UDim2.fromScale(frac, 1)})
		ctx.BossHpText.Text = UI.Abbrev(hp) .. " / " .. UI.Abbrev(v.Unit.MaxHp)
	end
	if ctx.Cards[id] then
		UI.Tween(ctx.Cards[id].Fill, 0.25, {Size = UDim2.fromScale(frac, 1)})
		ctx.Cards[id].Hp.Text = UI.Abbrev(hp) .. " / " .. UI.Abbrev(v.Unit.MaxHp)
	end
end

local function popText(ctx, id, text, color, big)
	local v = ctx.Vis[id]
	if not v then return end
	local holder = part(ctx.Arena, Vector3.new(0.1, 0.1, 0.1), v.Root.CFrame + Vector3.new(math.random(-15, 15) / 10, v.Height * 0.8, 0), Color3.new(1, 1, 1))
	holder.Transparency = 1
	local bb = new("BillboardGui", {Parent = holder, Size = UDim2.fromOffset(if big then 260 else 180, if big then 80 else 50), AlwaysOnTop = true, LightInfluence = 0})
	local l = UI.Label(bb, text, UDim2.fromScale(1, 1), nil, {TextColor3 = color, StrokeTh = 3})
	local s = new("UIScale", {Parent = l, Scale = 0.3})
	UI.Tween(s, 0.25, {Scale = if big then 1.3 else 1}, Enum.EasingStyle.Back)
	UI.Tween(bb, 1.0, {StudsOffset = Vector3.new(0, 4, 0)})
	task.delay(0.6, function() UI.Tween(l, 0.4, {TextTransparency = 1}) end)
	task.delay(1.05, function() holder:Destroy() end)
end

local function moveRoot(v, cf, t, style)
	local tw = TweenService:Create(v.Root, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = cf})
	tw:Play()
	return tw
end

local function flashModel(v, color)
	local h = new("Highlight", {Parent = v.Model, FillColor = color, FillTransparency = 0.3, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded})
	UI.Tween(h, 0.35, {FillTransparency = 1})
	task.delay(0.4, function() h:Destroy() end)
end

local function burst(ctx, pos, color, size, count)
	local p = part(ctx.Arena, Vector3.new(1, 1, 1), CFrame.new(pos), color)
	p.Transparency = 1
	local pe = new("ParticleEmitter", {Parent = p, Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(color, Color3.new(1, 1, 1)),
		LightEmission = 1, Size = NumberSequence.new(size or 1, 0), Speed = NumberRange.new(8, 18), Lifetime = NumberRange.new(0.4, 0.8), SpreadAngle = Vector2.new(180, 180), Rate = 0})
	pe:Emit(count or 25)
	task.delay(1, function() p:Destroy() end)
end

local function shockwave(ctx, pos, color)
	local ring = part(ctx.Arena, Vector3.new(0.4, 2, 2), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Neon, "cyl")
	ring.Transparency = 0.2
	UI.Tween(ring, 0.5, {Size = Vector3.new(0.4, 60, 60), Transparency = 1})
	task.delay(0.55, function() ring:Destroy() end)
end

local function beamFx(ctx, a: Vector3, b: Vector3, color)
	local len = (b - a).Magnitude
	local p = part(ctx.Arena, Vector3.new(len, 1.4, 1.4), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Neon, "cyl")
	p.Transparency = 0.1
	UI.Tween(p, 0.4, {Size = Vector3.new(len, 0.1, 0.1), Transparency = 1})
	task.delay(0.45, function() p:Destroy() end)
end

---------------------------------------------------------------- event playback
local function center(v) return v.Root.Position + Vector3.new(0, v.Height * 0.45, 0) end

local function playEvent(ctx, e, fast)
	local sp = if fast then 0.55 else 1
	if e.t == "turn" then
		local v = ctx.Vis[e.u]
		if v and ctx.TurnArrow then
			ctx.TurnArrow.Adornee = v.Anchor
			ctx.TurnArrow.Enabled = true
		end
		task.wait(0.12 * sp)
	elseif e.t == "hit" then
		local src, dst = ctx.Vis[e.src], ctx.Vis[e.dst]
		if not src or not dst then return end
		local color = KIND_COLOR[e.kind or "single"] or Color3.new(1, 1, 1)
		if e.skill and not ctx.LastSkillShown then
			ctx.SkillBanner.Text = "\u{2728} " .. e.skill
			ctx.SkillBanner.TextColor3 = color
			ctx.SkillBanner.Visible = true
			ctx.LastSkillShown = true
			task.delay(1.1 * sp, function() if ctx.SkillBanner then ctx.SkillBanner.Visible = false end end)
		end
		-- attacker lunges toward target
		local home = src.Home
		local dir = (dst.Home.Position - home.Position) * Vector3.new(1, 0, 1)
		local ranged = e.kind == "pierce" or e.kind == "nuke" or e.kind == "aoe" or e.kind == "freeze" or e.kind == "burn" or e.kind == "poison"
		if src.Unit.BossId then ranged = e.kind == "aoe" or e.kind == "burn" end
		Anim.Play(src.Model, if ranged then "cast" else "attack")
		if not ranged then
			local reach = math.max(0, dir.Magnitude - (dst.Width * 0.5 + src.Width * 0.5) - 1)
			moveRoot(src, home + dir.Unit * reach * 0.85, 0.18 * sp, Enum.EasingStyle.Back).Completed:Wait()
		else
			moveRoot(src, home * CFrame.new(0, 1.5, 0), 0.12 * sp).Completed:Wait()
			if e.kind == "aoe" then shockwave(ctx, ARENA + Vector3.new(0, 0.3, 0), color)
			else beamFx(ctx, center(src), center(dst), color) end
		end
		UI.Sound("hit", if e.crit then 0.7 else 1, 0.6)
		flashModel(dst, if e.crit then Color3.fromRGB(255, 60, 60) else Color3.new(1, 1, 1))
		Anim.Play(dst.Model, "hit")
		burst(ctx, center(dst), color, if e.crit then 1.6 else 1, if e.crit then 40 else 18)
		moveRoot(dst, dst.Home * CFrame.new(0, 0, if dst.Unit.Side == ctx.MySide then 1.2 else -1.2), 0.07)
		local txt = UI.Abbrev(e.dmg)
		if e.crit then txt = "CRIT! " .. txt end
		popText(ctx, e.dst, txt, if e.crit then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 240, 120), e.crit)
		if e.eff == "strong" then task.delay(0.15, function() popText(ctx, e.dst, "Super effective!", Color3.fromRGB(120, 255, 120)) end)
		elseif e.eff == "weak" then task.delay(0.15, function() popText(ctx, e.dst, "Not very effective", Color3.fromRGB(180, 180, 200)) end) end
		if e.crit then Effects.Shake(0.5, 0.25) end
		if src.Unit.BossId then Effects.Shake(0.35, 0.2) end
		setHp(ctx, e.dst, e.hp)
		task.wait(0.12 * sp)
		moveRoot(src, home, 0.2 * sp)
		moveRoot(dst, dst.Home, 0.15)
		task.wait(0.25 * sp)
	elseif e.t == "cast" then
		local src = ctx.Vis[e.src]
		if src then
			ctx.SkillBanner.Text = "\u{2728} " .. e.skill
			ctx.SkillBanner.TextColor3 = KIND_COLOR[e.kind] or Color3.new(1, 1, 1)
			ctx.SkillBanner.Visible = true
			task.delay(1.1 * sp, function() if ctx.SkillBanner then ctx.SkillBanner.Visible = false end end)
			Anim.Play(src.Model, if src.Unit.BossId then "roar" else "cast")
			moveRoot(src, src.Home * CFrame.new(0, 2, 0), 0.2 * sp).Completed:Wait()
			burst(ctx, center(src), KIND_COLOR[e.kind] or Color3.new(1, 1, 1), 1.4, 30)
			moveRoot(src, src.Home, 0.2 * sp).Completed:Wait()
		end
	elseif e.t == "heal" then
		local dst = ctx.Vis[e.dst]
		if dst then
			if e.amt > 0 then popText(ctx, e.dst, "+" .. UI.Abbrev(e.amt), Color3.fromRGB(100, 255, 120)) end
			burst(ctx, center(dst), Color3.fromRGB(100, 255, 120), 0.8, 12)
			setHp(ctx, e.dst, e.hp)
			task.wait(0.2 * sp)
		end
	elseif e.t == "status" then
		local v = ctx.Vis[e.dst]
		if v then
			v.Statuses[e.s] = true
			local icons = {}
			for s in v.Statuses do table.insert(icons, STATUS_ICON[s] or "") end
			v.Status.Text = table.concat(icons, " ")
			popText(ctx, e.dst, (STATUS_ICON[e.s] or "") .. " " .. string.upper(e.s), KIND_COLOR[e.s] or Color3.new(1, 1, 1))
			task.wait(0.18 * sp)
		end
	elseif e.t == "dot" then
		local v = ctx.Vis[e.dst]
		if v then
			popText(ctx, e.dst, (STATUS_ICON[e.s] or "") .. " " .. UI.Abbrev(e.dmg), KIND_COLOR[e.s] or Color3.new(1, 1, 1))
			flashModel(v, KIND_COLOR[e.s] or Color3.new(1, 1, 1))
			setHp(ctx, e.dst, e.hp)
			task.wait(0.3 * sp)
		end
	elseif e.t == "skip" then
		popText(ctx, e.u, if e.s == "stun" then "STUNNED!" else "FROZEN!", KIND_COLOR[e.s] or Color3.new(1, 1, 1))
		local v = ctx.Vis[e.u]
		if v then v.Statuses[e.s] = nil end
		task.wait(0.35 * sp)
	elseif e.t == "die" then
		local v = ctx.Vis[e.u]
		if v then
			UI.Sound("swim", 0.7, 0.6)
			Anim.Play(v.Model, "faint")
			burst(ctx, center(v), Color3.fromRGB(200, 200, 200), 1.5, 30)
			moveRoot(v, v.Home * CFrame.new(0, -v.Height * 0.6, 0) * CFrame.Angles(0, 0, math.rad(80)), 0.6 * sp)
			v.Anchor:ClearAllChildren()
			if ctx.Cards[e.u] then ctx.Cards[e.u].Frame.BackgroundTransparency = 0.6 end
			task.wait(0.4 * sp)
		end
	elseif e.t == "round" then
		ctx.RoundText.Text = "Round " .. e.n
	end
end

local function playEvents(ctx, events, fast)
	for _, e in events do
		if not active or active ~= ctx then return end
		if e.t == "turn" then ctx.LastSkillShown = false end
		playEvent(ctx, e, fast)
	end
end

---------------------------------------------------------------- UI
local function buildBattleUI(ctx, title, isBoss)
	local ui = new("Frame", {Parent = screen, Name = "BattleUI", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30})
	ctx.UI = ui
	ctx.RoundText = UI.Label(ui, "Round 1", UDim2.fromOffset(200, 28), UDim2.new(0, 16, 0, 70), {ZIndex = 31, TextXAlignment = Enum.TextXAlignment.Left})
	ctx.SkillBanner = UI.Label(ui, "", UDim2.fromOffset(600, 50), UDim2.new(0.5, -300, 0.2, 0), {ZIndex = 32, StrokeTh = 3, Visible = false})
	if isBoss then
		local bar = new("Frame", {Parent = ui, Size = UDim2.fromOffset(620, 64), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Bg, ZIndex = 31})
		UI.Corner(bar, 16); UI.Stroke(bar, UI.C.Red, 3)
		UI.Label(bar, "\u{1F480} " .. title, UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 4), {ZIndex = 32})
		local bg = new("Frame", {Parent = bar, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 32), BackgroundColor3 = UI.C.Dark, ZIndex = 32})
		UI.Corner(bg, 10)
		ctx.BossBar = new("Frame", {Parent = bg, Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.Red, ZIndex = 33})
		UI.Corner(ctx.BossBar, 10)
		UI.Gradient(ctx.BossBar, Color3.fromRGB(255, 120, 120), Color3.fromRGB(200, 30, 40), 90)
		ctx.BossHpText = UI.Label(bg, "", UDim2.new(1, 0, 1, -4), UDim2.fromOffset(0, 2), {ZIndex = 34, Font = UI.Body})
	else
		UI.Label(ui, title, UDim2.fromOffset(600, 40), UDim2.new(0.5, -300, 0, 14), {ZIndex = 31, StrokeTh = 3})
	end
	-- team cards
	local cards = new("Frame", {Parent = ui, Size = UDim2.fromOffset(560, 92), Position = UDim2.new(0.5, 0, 1, -110), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, ZIndex = 31})
	UI.List(cards, 10, Enum.FillDirection.Horizontal)
	ctx.Cards = {}
	for _, u in ctx.Units do
		if u.Side == ctx.MySide then
			local duck = DuckData.List[u.DuckId]
			local f = new("Frame", {Parent = cards, Size = UDim2.fromOffset(176, 86), BackgroundColor3 = UI.C.Bg, ZIndex = 31})
			UI.Corner(f, 14)
			local st = UI.Stroke(f, Rarity.List[duck.Rarity].Color, 2.5)
			UI.Viewport(f, u.DuckId, {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(6, 11), Z = 32})
			UI.Label(f, u.Name, UDim2.new(1, -78, 0, 20), UDim2.fromOffset(72, 8), {ZIndex = 32, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
			local bg = new("Frame", {Parent = f, Size = UDim2.new(1, -80, 0, 14), Position = UDim2.fromOffset(72, 32), BackgroundColor3 = UI.C.Dark, ZIndex = 32})
			UI.Corner(bg, 7)
			local fill = new("Frame", {Parent = bg, Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.Green, ZIndex = 33})
			UI.Corner(fill, 7)
			local hp = UI.Label(f, UI.Abbrev(u.Hp) .. " / " .. UI.Abbrev(u.MaxHp), UDim2.new(1, -80, 0, 14), UDim2.fromOffset(72, 48), {ZIndex = 32, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
			local ab = UI.Label(f, u.Ability and ("\u{2728} " .. u.Ability.Name) or "", UDim2.new(1, -80, 0, 14), UDim2.fromOffset(72, 64), {ZIndex = 32, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
			ctx.Cards[u.Id] = {Frame = f, Fill = fill, Hp = hp, Stroke = st, Ability = ab}
		end
	end
	ctx.TurnArrow = new("BillboardGui", {Parent = ui, Size = UDim2.fromOffset(60, 60), StudsOffsetWorldSpace = Vector3.new(0, 6, 0), AlwaysOnTop = true, Enabled = false})
	UI.Label(ctx.TurnArrow, "\u{25BC}", UDim2.fromScale(1, 1), nil, {TextColor3 = UI.C.Yellow, StrokeTh = 3})
end

local function buildControls(ctx)
	local bar = new("Frame", {Parent = ctx.UI, Size = UDim2.fromOffset(640, 64), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, ZIndex = 31})
	UI.List(bar, 10, Enum.FillDirection.Horizontal)
	ctx.ActorText = UI.Label(ctx.UI, "", UDim2.fromOffset(500, 30), UDim2.new(0.5, -250, 1, -248), {ZIndex = 32, StrokeTh = 2.5})
	local function act(kind)
		if not ctx.Waiting or ctx.Busy then return end
		ctx.Busy = true
		BV.SetControls(ctx, false)
		local r = State.Request("BattleAction", ctx.BattleId, kind)
		if not r.ok then
			UI.Toast(r.err or "Action failed", "error")
			ctx.Busy = false
			BV.SetControls(ctx, true)
			return
		end
		if r.cds then ctx.Cds = r.cds end
		playEvents(ctx, r.events, ctx.Auto)
		ctx.Busy = false
		BV.AfterEvents(ctx, r.waiting, r.over, r.result)
	end
	ctx.Act = act
	ctx.AttackBtn = UI.Button(bar, {Text = "ATTACK", IconImage = "swords", Color = UI.C.Red, Size = UDim2.fromOffset(170, 58), Order = 1, Z = 32, OnClick = function() act("attack") end})
	ctx.SpecialBtn = UI.Button(bar, {Text = "SPECIAL", IconImage = "star", Color = UI.C.Purple, Size = UDim2.fromOffset(200, 58), Order = 2, Z = 32, OnClick = function() act("special") end})
	ctx.AutoBtn = UI.Button(bar, {Text = "AUTO: OFF", Color = UI.C.Card, Size = UDim2.fromOffset(130, 58), Order = 3, Z = 32, OnClick = function()
		ctx.Auto = not ctx.Auto
		UI.SetText(ctx.AutoBtn, if ctx.Auto then "AUTO: ON" else "AUTO: OFF")
		UI.SetColor(ctx.AutoBtn, if ctx.Auto then UI.C.Green else UI.C.Card)
		if ctx.Auto and ctx.Waiting and not ctx.Busy then act("auto") end
	end})
	UI.Button(bar, {Text = "FLEE", Color = UI.C.Dark, Size = UDim2.fromOffset(100, 58), Order = 4, Z = 32, OnClick = function()
		if ctx.Busy then return end
		local r = State.Request("Forfeit", ctx.BattleId)
		BV.Finish(ctx, r.result or {won = false})
	end})
	ctx.Controls = bar
end

function BV.SetControls(ctx, on)
	if not ctx.Controls then return end
	ctx.Controls.Visible = on
	if on and ctx.Waiting then
		local v = ctx.Vis[ctx.Waiting]
		local cd = ctx.Cds and ctx.Cds[ctx.Waiting] or 0
		local ab = v and v.Unit.Ability
		ctx.ActorText.Text = "\u{1F986} " .. (v and v.Unit.Name or "") .. "'s turn"
		if ab then
			UI.SetText(ctx.SpecialBtn, if cd > 0 then (ab.Name .. " (" .. cd .. ")") else ab.Name)
			UI.SetColor(ctx.SpecialBtn, if cd > 0 then UI.C.Dark else UI.C.Purple)
		end
		for id, card in ctx.Cards do card.Stroke.Thickness = if id == ctx.Waiting then 5 else 2.5 end
	else
		ctx.ActorText.Text = ""
	end
end

function BV.AfterEvents(ctx, waiting, over, result)
	if active ~= ctx then return end
	if over then
		BV.Finish(ctx, result or {won = false})
		return
	end
	ctx.Waiting = waiting
	if ctx.TurnArrow and waiting and ctx.Vis[waiting] then ctx.TurnArrow.Adornee = ctx.Vis[waiting].Anchor; ctx.TurnArrow.Enabled = true end
	if ctx.Auto then
		BV.SetControls(ctx, false)
		task.wait(0.15)
		ctx.Act("auto")
	else
		BV.SetControls(ctx, true)
	end
end

---------------------------------------------------------------- lifecycle
local savedCam
local function enter(ctx, worldId)
	active = ctx
	player:SetAttribute("InBattleView", true)
	Panels.Close()
	HUD.Root.Visible = false
	ctx.Arena = buildArena(worldId)
	WorldFx.ApplyMood(worldId)
	local cam = workspace.CurrentCamera
	savedCam = cam.CameraType
	local goal = CFrame.lookAt(ARENA + Vector3.new(0, 13, 36), ARENA + Vector3.new(0, 4, 0))
	-- the first-person camera controller keeps reclaiming the camera, so we own it every frame
	local camValue = Instance.new("CFrameValue")
	camValue.Value = goal * CFrame.new(0, 10, 30)
	ctx.CamValue = camValue
	TweenService:Create(camValue, TweenInfo.new(1.1, Enum.EasingStyle.Quint), {Value = goal}):Play()
	local fov = cam.FieldOfView
	ctx.SavedFov = fov
	RunService:BindToRenderStep("DuckBattleCam", Enum.RenderPriority.Camera.Value + 5, function()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 70
		local shake = ctx.Shake or CFrame.new()
		cam.CFrame = camValue.Value * shake
	end)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
end

local function leave(ctx)
	if active == ctx then active = nil end
	if ctx.UI then ctx.UI:Destroy() end
	if ctx.Arena then ctx.Arena:Destroy() end
	pcall(function() RunService:UnbindFromRenderStep("DuckBattleCam") end)
	if ctx.CamValue then ctx.CamValue:Destroy() end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	if ctx.SavedFov then cam.FieldOfView = ctx.SavedFov end
	HUD.Root.Visible = true
	player:SetAttribute("InBattleView", nil)
	WorldFx.ForceMood()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
end

local function placeUnits(ctx)
	ctx.Vis = {}
	local mine, theirs = {}, {}
	for _, u in ctx.Units do if u.Side == ctx.MySide then table.insert(mine, u) else table.insert(theirs, u) end end
	for i, u in mine do
		local pos = ARENA + Vector3.new(-16, 0, (i - (#mine + 1) / 2) * 9 + 4)
		makeUnitVisual(ctx, u, CFrame.lookAt(pos, pos + Vector3.new(1, 0, 0)) * CFrame.Angles(0, 0, 0))
	end
	for i, u in theirs do
		local pos = ARENA + Vector3.new(if u.BossId then 18 else 16, 0, if u.BossId then -2 else (i - (#theirs + 1) / 2) * 9 + 4)
		makeUnitVisual(ctx, u, CFrame.lookAt(pos, pos - Vector3.new(1, 0, 0)))
	end
end

function BV.Finish(ctx, result)
	if ctx.Finished then return end
	ctx.Finished = true
	BV.SetControls(ctx, false)
	if ctx.TurnArrow then ctx.TurnArrow.Enabled = false end
	local won = result.won
	local overlay = new("Frame", {Parent = ctx.UI, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 40})
	UI.Tween(overlay, 0.4, {BackgroundTransparency = 0.45})
	local card = new("Frame", {Parent = overlay, Size = UDim2.fromOffset(520, 420), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Bg, ZIndex = 41})
	UI.Corner(card, 22)
	UI.Stroke(card, if won then UI.C.Gold else UI.C.Red, 4)
	UI.Gradient(card, if won then UI.Darken(UI.C.Gold, 0.45) else UI.Darken(UI.C.Red, 0.6), UI.C.Bg, 90)
	local sc = new("UIScale", {Parent = card, Scale = 0.3}); UI.Tween(sc, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	UI.Label(card, if won then "VICTORY!" else "DEFEAT", UDim2.new(1, 0, 0, 70), UDim2.fromOffset(0, 16), {ZIndex = 42, StrokeTh = 4, TextColor3 = if won then UI.C.Gold else UI.C.Red})
	local lines = {}
	if ctx.IsPvP then
		table.insert(lines, "vs " .. ctx.Opponent .. " (" .. ctx.Mode .. ")")
		if ctx.Mode == "ranked" then table.insert(lines, string.format("Rating: %d (%s%d)", result.rating or 0, (result.change or 0) >= 0 and "+" or "", result.change or 0)) end
		if (result.coins or 0) > 0 then table.insert(lines, "\u{1F4B0} +" .. UI.Abbrev(result.coins)) end
		if won and (result.streak or 0) > 1 then table.insert(lines, "\u{1F525} Win streak: " .. result.streak) end
	elseif won then
		table.insert(lines, "\u{1F4B0} +" .. UI.Abbrev(result.coins or 0) .. " coins")
		table.insert(lines, "\u{1F48E} +" .. (result.gems or 0) .. " gems    \u{2B50} +" .. UI.Abbrev(result.xp or 0) .. " XP")
		table.insert(lines, "\u{2728} +" .. (result.essence or 0) .. " Duck Essence")
		if result.rodId then table.insert(lines, "\u{1F3A3} NEW: " .. Config.Rods[result.rodId].Name .. "!") end
		if result.duckId then table.insert(lines, "\u{1F986} EXCLUSIVE DROP: " .. DuckData.List[result.duckId].Name .. "!") end
	else
		table.insert(lines, "\u{1F4B0} +" .. UI.Abbrev(result.coins or 0) .. " consolation coins")
		table.insert(lines, "Tip: train your ducks, evolve them, or catch rarer ones!")
		table.insert(lines, "Elements matter: Water > Fire > Nature > Water")
	end
	for i, l in lines do
		UI.Label(card, l, UDim2.new(1, -40, 0, 30), UDim2.fromOffset(20, 96 + (i - 1) * 38), {ZIndex = 42, Font = UI.Body})
	end
	if won then
		UI.Sound("victory", 1, 0.6)
		UI.Chime(8, 0.9)
		Effects.Confetti(100)
		for _, v in ctx.Vis do
			if v.Unit.Side == ctx.MySide and v.Unit.Hp > 0 then
				task.spawn(function()
					for _ = 1, 3 do moveRoot(v, v.Home * CFrame.new(0, 3, 0), 0.2).Completed:Wait(); moveRoot(v, v.Home, 0.2).Completed:Wait() end
				end)
			end
		end
	else
		UI.Sound("swim", 0.6, 0.7)
	end
	UI.Button(card, {Text = "CONTINUE", Color = if won then UI.C.Green else UI.C.Blue, Size = UDim2.fromOffset(240, 60), Position = UDim2.new(0.5, -120, 1, -78), Z = 42, OnClick = function()
		leave(ctx)
		if result.duckId then Effects.Reveal({duckId = result.duckId, source = "boss", isNew = true}) end
	end})
end

function BV.StartBoss(bossId)
	if active then return end
	local r = State.Request("StartBoss", bossId)
	if not r.ok then UI.Toast(r.err or "Can't start battle", "error") return end
	local boss = Config.Bosses[bossId]
	local ctx = {BattleId = r.battleId, Units = r.units, MySide = "A", Cds = {}}
	enter(ctx, boss.World)
	placeUnits(ctx)
	buildBattleUI(ctx, boss.Name, true)
	setHp(ctx, "B1", boss.HP)
	buildControls(ctx)
	BV.SetControls(ctx, false)
	local intro = UI.Label(ctx.UI, boss.Name:upper(), UDim2.fromOffset(700, 90), UDim2.new(0.5, -350, 0.35, 0), {ZIndex = 35, StrokeTh = 4, TextColor3 = UI.C.Red})
	local s = new("UIScale", {Parent = intro, Scale = 2}); UI.Tween(s, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
	Effects.Shake(0.8, 0.6)
	UI.Sound("bass", 0.7, 0.9)
	task.wait(1.3)
	intro:Destroy()
	playEvents(ctx, r.events)
	BV.AfterEvents(ctx, r.waiting, r.over, r.result)
end

function BV.PlayPvP(p)
	if active then
		UI.Toast((if p.Won then "You won" else "You lost") .. " a PvP battle vs " .. p.Opponent, if p.Won then "good" else "warn")
		return
	end
	local ctx = {Units = p.Units, MySide = p.Side, IsPvP = true, Opponent = p.Opponent, Mode = p.Mode}
	enter(ctx, State.Data.world)
	placeUnits(ctx)
	buildBattleUI(ctx, "\u{2694}\u{FE0F} " .. player.DisplayName .. "  vs  " .. p.Opponent, false)
	task.wait(1.2)
	playEvents(ctx, p.Events, true)
	BV.Finish(ctx, {won = p.Won, rating = p.Rating, change = p.RatingChange, coins = p.Coins, streak = p.Streak})
end

---------------------------------------------------------------- Battle panel (bosses + PvP)
function BV.Register()
	local body, tab = nil, "Bosses"
	local function clear(f) for _, c in f:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end
	local function refresh()
		local d = State.Data
		clear(body)
		if tab == "Bosses" then
			for i, b in Config.Bosses do
				local worldOk = d.worlds[tostring(b.World)]
				local prevOk = i == 1 or (d.bossesBeaten[tostring(i - 1)] or 0) > 0
				local beaten = d.bossesBeaten[tostring(i)] or 0
				local card = Panels.Card(body, {Size = UDim2.new(1, -12, 0, 92), LayoutOrder = i, BackgroundColor3 = UI.Darken(b.Color, if worldOk and prevOk then 0.55 else 0.8)})
				UI.Label(card, (if beaten > 0 then "\u{2705} " else "\u{1F480} ") .. b.Name, UDim2.new(0.5, 0, 0, 30), UDim2.fromOffset(14, 8), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
				UI.Label(card, string.format("%s  |  \u{2764}\u{FE0F} %s  \u{2694}\u{FE0F} %s  |  %s", WorldData.List[b.World].Name, UI.Abbrev(b.HP), UI.Abbrev(b.Atk), b.Element),
					UDim2.new(0.6, 0, 0, 20), UDim2.fromOffset(14, 40), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Sub})
				local drops = DuckData.BossDrops[b.Id]
				local dropName = drops and DuckData.List[drops[1]].Name or ""
				UI.Label(card, string.format("\u{1F381} %s coins, %d gems, %d essence  |  Drop: %s%s", UI.Abbrev(b.Coins), b.Gems, b.Essence, dropName, b.RodReward and (" + " .. Config.Rods[b.RodReward].Name) or ""),
					UDim2.new(1, -230, 0, 18), UDim2.fromOffset(14, 64), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Gold})
				local label, color = "FIGHT", UI.C.Red
				if not worldOk then label, color = "\u{1F512} World", UI.C.Dark
				elseif not prevOk then label, color = "\u{1F512} Beat previous", UI.C.Dark end
				UI.Button(card, {Text = label, Color = color, Size = UDim2.fromOffset(190, 56), Position = UDim2.new(1, -204, 0.5, -28), Z = 26, OnClick = function()
					if color == UI.C.Dark then UI.Toast("Locked! " .. (if not worldOk then "Unlock " .. WorldData.List[b.World].Name .. " first." else "Defeat the previous boss first."), "warn") return end
					if #d.team == 0 then UI.Toast("Equip ducks in your team first!", "warn") return end
					task.spawn(BV.StartBoss, i)
				end})
			end
		else
			local pv = d.pvp
			local t = Config.PvPTitle(pv.rating)
			local head = Panels.Card(body, {Size = UDim2.new(1, -12, 0, 80), LayoutOrder = 0, BackgroundColor3 = UI.Darken(t.Color, 0.6)})
			UI.Label(head, string.format("\u{1F3C5} %s  |  Rating %d (peak %d)", t.Name, pv.rating, pv.peak), UDim2.new(1, -20, 0, 30), UDim2.fromOffset(12, 8), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Lighten(t.Color, 0.3)})
			UI.Label(head, string.format("Wins %d  |  Losses %d  |  Streak %d (best %d)  |  Team power \u{26A1}%s  |  Season %s", d.stats.pvpWins, d.stats.pvpLosses, pv.streak, pv.bestStreak, UI.Abbrev(Stats.TeamPower(d)), pv.season),
				UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 44), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left})
			local r = State.Request("ListPvP")
			local list = r.ok and r.players or {}
			if #list == 0 then
				UI.Label(body, "No other players in this server yet. Invite a friend!", UDim2.new(1, 0, 0, 40), nil, {ZIndex = 24, LayoutOrder = 1, Font = UI.Body})
			end
			for i, p in list do
				local card = Panels.Card(body, {Size = UDim2.new(1, -12, 0, 70), LayoutOrder = i + 1})
				UI.Label(card, p.Name .. "  -  " .. p.Title, UDim2.new(0.5, 0, 0, 26), UDim2.fromOffset(12, 8), {ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left})
				UI.Label(card, string.format("Rating %d  |  \u{26A1}%s%s", p.Rating, UI.Abbrev(p.Power), p.Busy and "  |  In battle" or ""), UDim2.new(0.5, 0, 0, 20), UDim2.fromOffset(12, 40), {ZIndex = 25, Font = UI.Body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.Sub})
				for j, mode in {"ranked", "casual"} do
					UI.Button(card, {Text = if mode == "ranked" then "Ranked" else "Casual", Color = if mode == "ranked" then UI.C.Red else UI.C.Blue, Size = UDim2.fromOffset(120, 46), Position = UDim2.new(1, -268 + (j - 1) * 130, 0.5, -23), Z = 26, OnClick = function()
						local res = State.Request("Challenge", p.UserId, mode)
						UI.Toast(if res.ok then ("Challenge sent to " .. p.Name .. "!") else (res.err or "Failed"), if res.ok then "good" else "error")
					end})
				end
			end
		end
	end
	Panels.Register({Name = "Battle", Title = "Battle", Icon = "\u{2694}\u{FE0F}", Color = UI.C.Red, Size = UDim2.fromOffset(860, 560),
		Build = function(content)
			local holder = new("Frame", {Parent = content, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1, ZIndex = 23})
			body = Panels.Scroll(holder, 8)
			local set = Panels.Tabs(content, {"Bosses", "PvP"}, UI.C.Red, function(t) tab = t; if State.Data then refresh() end end)
			set("Bosses")
			BV.SetBattleTab = set
		end,
		Refresh = function(_, _, wantTab)
			if wantTab and wantTab ~= tab then BV.SetBattleTab(wantTab) else refresh() end
		end})

	-- PvP invite popup
	State.OnEvent("PvPInvite", function(p)
		local f = new("Frame", {Parent = screen, Size = UDim2.fromOffset(420, 150), Position = UDim2.new(0.5, 0, 0.25, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Bg, ZIndex = 70})
		UI.Corner(f, 18); UI.Stroke(f, UI.C.Red, 3)
		UI.Label(f, "\u{2694}\u{FE0F} " .. p.From .. " challenges you!", UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 10), {ZIndex = 71})
		UI.Label(f, string.format("%s  |  Rating %d  |  \u{26A1}%s", p.Mode:upper(), p.Rating, UI.Abbrev(p.Power)), UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 46), {ZIndex = 71, Font = UI.Body})
		local function respond(yes)
			f:Destroy()
			local r = State.Request("RespondPvP", p.UserId, yes)
			if not r.ok then UI.Toast(r.err or "Failed", "error") end
		end
		UI.Button(f, {Text = "ACCEPT", Color = UI.C.Green, Size = UDim2.fromOffset(180, 50), Position = UDim2.new(0.5, -190, 1, -62), Z = 72, OnClick = function() respond(true) end})
		UI.Button(f, {Text = "DECLINE", Color = UI.C.Red, Size = UDim2.fromOffset(180, 50), Position = UDim2.new(0.5, 10, 1, -62), Z = 72, OnClick = function() respond(false) end})
		UI.Chime(3, 0.8)
		task.delay(28, function() if f.Parent then f:Destroy() end end)
	end)
	State.OnEvent("PvPResult", function(p) task.spawn(BV.PlayPvP, p) end)
	State.OnEvent("BattleAbandoned", function()
		if active and not active.IsPvP then leave(active) end
		UI.Toast("Battle timed out.", "warn")
	end)
end

function BV.Init(s) screen = s end

-- Studio test helpers
function BV.DebugState()
	if not active then return "none" end
	return (active.Finished and "finished" or "active") .. ":" .. tostring(active.Waiting) .. ":" .. tostring(active.Busy)
end
function BV.DebugAuto()
	if active and active.Act then
		active.Auto = true
		if active.Waiting and not active.Busy then task.spawn(active.Act, "auto") end
	end
end
function BV.DebugLeave()
	if active then leave(active) end
end

return BV
