-- Edit-time map generator (run from the command bar / MCP). Builds the carnival hub and all 8 worlds
-- into Workspace.Map. Safe to re-run per world: it replaces that world's folder.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local WorldData = require(Shared.WorldData)
local DuckData = require(Shared.DuckData)
local DuckModelBuilder = require(Shared.DuckModelBuilder)
local RodModelBuilder = require(Shared.RodModelBuilder)
local Config = require(Shared.Config)
local Rarity = require(Shared.Rarity)

local M = {}
local RAD = math.rad
local WHITE = Color3.new(1, 1, 1)

local function part(parent, size, cf, color, mat, shape, name)
	local p = Instance.new("Part")
	if shape == "cyl" then p.Shape = Enum.PartType.Cylinder elseif shape == "ball" then p.Shape = Enum.PartType.Ball end
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- small decor doesn't need to cast shadows (big frame-rate cost for no visible gain)
	if math.max(size.X, size.Y, size.Z) < 4 then p.CastShadow = false end
	if name then p.Name = name end
	p.Parent = parent
	return p
end
local function wedge(parent, size, cf, color, mat)
	local p = Instance.new("WedgePart")
	p.Anchored = true; p.Size = size; p.CFrame = cf; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end
local function folder(parent, name)
	local f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f
end
local function model(parent, name)
	local m = Instance.new("Model"); m.Name = name; m.Parent = parent; return m
end
local function decorate(p, noCollide)
	if noCollide then p.CanCollide = false end
	p.CanQuery = false
	return p
end

-- Blender prop meshes (ReplicatedStorage.Assets.Meshes.Props.<Name>), authored with base at y=0.
-- style[slot] = {Color3, Material, collide?}
local PROP_STYLE = {
	Trunk = {Color3.fromRGB(140, 100, 62), Enum.Material.Wood, true}, Leaf = {Color3.fromRGB(70, 180, 80), Enum.Material.SmoothPlastic},
	Pine = {Color3.fromRGB(40, 115, 65), Enum.Material.SmoothPlastic, true}, Snow = {WHITE, Enum.Material.Snow},
	Rock = {Color3.fromRGB(130, 125, 120), Enum.Material.Slate, true}, Crystal = {Color3.fromRGB(150, 220, 255), Enum.Material.Glass},
	Wood = {Color3.fromRGB(62, 52, 46), Enum.Material.Wood, true}, Stem = {Color3.fromRGB(235, 225, 205), Enum.Material.SmoothPlastic},
	Cap = {Color3.fromRGB(230, 60, 60), Enum.Material.SmoothPlastic}, TentA = {Color3.fromRGB(235, 50, 60), Enum.Material.Fabric, true},
	TentB = {WHITE, Enum.Material.Fabric, true}, Lamp = {Color3.fromRGB(255, 220, 140), Enum.Material.Neon}, Black = {Color3.fromRGB(40, 40, 45), Enum.Material.Metal, true},
}
local function propMesh(parent, name: string, cf: CFrame, scale: number, style)
	local lib = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Meshes") and RS.Assets.Meshes.Props:FindFirstChild(name)
	if not lib then return nil end
	local m = Instance.new("Model"); m.Name = name
	local parts = {}
	for _, src in lib:GetChildren() do
		local slot = src:GetAttribute("Slot")
		local st = (style and style[slot]) or PROP_STYLE[slot] or {WHITE, Enum.Material.SmoothPlastic}
		local p = src:Clone()
		p.Anchored = true
		p.Size = src.Size * scale
		p.CFrame = cf * CFrame.new(src.Position * scale) * src.CFrame.Rotation
		p.Color = st[1]
		p.Material = st[2]
		p.CanCollide = st[3] == true
		p.CanQuery = false
		p.CanTouch = false
		if p.CanCollide then pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.Hull end) end
		if st[2] == Enum.Material.Glass then p.Transparency = 0.2 end
		p.Parent = m
		parts[slot] = p
	end
	m.Parent = parent
	return m, parts
end

local function label(parentPart, face, text, color, bg, font)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = parentPart
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	if bg then t.BackgroundColor3 = bg end
	t.Text = text
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextColor3 = color or WHITE
	t.Parent = sg
	local s = Instance.new("UIStroke"); s.Thickness = 3; s.Color = Color3.fromRGB(30, 30, 50); s.Parent = t
	return t
end

local function prompt(parentPart, action, actionText, objectText, attrs)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText or ""
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Style = Enum.ProximityPromptStyle.Default
	pp:SetAttribute("Action", action)
	for k, v in attrs or {} do pp:SetAttribute(k, v) end
	pp.Parent = parentPart
	return pp
end

local function billboard(adornee, text, color, height)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 60)
	bb.StudsOffset = Vector3.new(0, height or 4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 120
	bb.LightInfluence = 0
	bb.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or WHITE
	t.Parent = bb
	local s = Instance.new("UIStroke"); s.Thickness = 2.5; s.Parent = t
	return bb
end

local function stripedRoof(parent, cf, w, d, c1, c2, stripes)
	-- gabled striped canopy centered at cf (ridge along X)
	local sw = w / stripes
	for i = 0, stripes - 1 do
		local x = -w / 2 + sw * (i + 0.5)
		local col = if i % 2 == 0 then c1 else c2
		for _, s in {-1, 1} do
			local pcf = cf * CFrame.new(x, -d * 0.12, s * d / 4) * CFrame.Angles(RAD(s * 20), 0, 0)
			decorate(part(parent, Vector3.new(sw, 0.4, d / 2 + 0.6), pcf, col, Enum.Material.Fabric))
		end
	end
	-- scalloped edge
	for i = 0, stripes - 1 do
		local x = -w / 2 + sw * (i + 0.5)
		for _, s in {-1, 1} do
			decorate(part(parent, Vector3.new(0.4, sw * 0.9, sw * 0.9), cf * CFrame.new(x, -d * 0.12 - math.sin(RAD(20)) * d / 4 - 0.4, s * (d / 2 - 0.1)) * CFrame.Angles(0, 0, RAD(90)), if i % 2 == 0 then c1 else c2, Enum.Material.Fabric, "cyl"), true)
		end
	end
end

local function stringLights(parent, a: Vector3, b: Vector3, n)
	local cols = {Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 255), Color3.fromRGB(120, 255, 120), Color3.fromRGB(255, 120, 230)}
	for i = 0, n do
		local t = i / n
		local pos = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 1.2, 0)
		local bulb = decorate(part(parent, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), cols[i % #cols + 1], Enum.Material.Neon, "ball"), true)
	end
end

---------------------------------------------------------------- POOL
-- Round carnival pool: wall ring, water disc, fountain island with a duck statue, wooden deck ring,
-- striped circus canopy on poles. Ducks are NOT built here: each player's ducks are spawned by the
-- server (FishingService) and rendered on their client (Client.Fishing) using Shared.PoolSim.
local PoolSim = require(Shared.PoolSim)

local function triangle(parent, a: Vector3, b: Vector3, c: Vector3, color, mat, th)
	th = th or 0.3
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c
	elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local w1 = wedge(parent, Vector3.new(th, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat)
	local w2 = wedge(parent, Vector3.new(th, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat)
	for _, w in {w1, w2} do w.CanQuery = false; w.CanCollide = false; w.CastShadow = true end
	return w1, w2
end

local function ring(parent, center: Vector3, radius, segs, size: Vector3, color, mat, name, collide)
	local len = 2 * math.pi * radius / segs * 1.06
	local parts = {}
	for i = 0, segs - 1 do
		local ang = i / segs * math.pi * 2
		local cf = CFrame.new(center) * CFrame.Angles(0, -ang, 0) * CFrame.new(radius, 0, 0)
		local p = part(parent, Vector3.new(size.X, size.Y, len), cf, color, mat, nil, name)
		if not collide then p.CanCollide = false end
		p.CanQuery = false
		table.insert(parts, p)
	end
	return parts
end

function M.Pool(parent, worldId, center: Vector3, size: Vector3, theme, duckCount)
	local pool = model(parent, "Pool")
	pool:SetAttribute("WorldId", worldId)
	local R = PoolSim.Radius(worldId)
	local y0 = center.Y
	local surfaceY = y0 + 3
	local wallH, t = 3.35, 1.6
	pool:SetAttribute("Radius", R)
	-- floor
	local floor = part(pool, Vector3.new(0.4, R * 2 + 1, R * 2 + 1), CFrame.new(center.X, y0 + 0.2, center.Z) * CFrame.Angles(0, 0, RAD(90)), theme.Floor or Color3.fromRGB(120, 200, 255), Enum.Material.SmoothPlastic, "cyl", "Floor")
	floor.CanQuery = false
	-- wall ring with a darker band and a white trim lip
	local wc = Vector3.new(center.X, y0, center.Z)
	ring(pool, wc + Vector3.new(0, wallH / 2, 0), R + t / 2, 48, Vector3.new(t, wallH, 0), theme.Wall, Enum.Material.SmoothPlastic, "Wall", true)
	ring(pool, wc + Vector3.new(0, 0.9, 0), R + t / 2, 48, Vector3.new(t + 0.06, 0.6, 0), Color3.new(theme.Wall.R * 0.75, theme.Wall.G * 0.75, theme.Wall.B * 0.75), Enum.Material.SmoothPlastic)
	ring(pool, wc + Vector3.new(0, wallH + 0.15, 0), R + t / 2, 48, Vector3.new(t + 0.5, 0.5, 0), theme.Trim, Enum.Material.SmoothPlastic, "Trim", true)
	-- water disc
	local water = part(pool, Vector3.new(2.8, R * 2, R * 2), CFrame.new(center.X, surfaceY - 1.4, center.Z) * CFrame.Angles(0, 0, RAD(90)), theme.Water, Enum.Material.Glass, "cyl", "Water")
	water.Transparency = 0.35
	water.CanCollide = false
	water.Reflectance = 0.1
	if theme.Liquid == "lava" then
		water.Material = Enum.Material.Neon; water.Transparency = 0.15
	elseif theme.Liquid == "void" then
		water.Material = Enum.Material.Neon; water.Transparency = 0.45
	elseif theme.Liquid == "swamp" then
		water.Transparency = 0.15; water.Material = Enum.Material.SmoothPlastic
	end
	water:SetAttribute("SurfaceY", surfaceY)
	water:SetAttribute("Radius", R)
	local bub = Instance.new("ParticleEmitter")
	bub.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bub.Color = ColorSequence.new(Color3.new(1, 1, 1))
	bub.Transparency = NumberSequence.new(0.4, 1)
	bub.Rate = 8; bub.Lifetime = NumberRange.new(1, 2); bub.Speed = NumberRange.new(0.5, 1)
	bub.Size = NumberSequence.new(0.3, 0); bub.EmissionDirection = Enum.NormalId.Top
	bub.Parent = water
	-- fountain island + statue duck (the canopy's centre pole rises from it)
	local isl = PoolSim.ISLAND
	part(pool, Vector3.new(wallH + 0.4, isl * 2, isl * 2), CFrame.new(center.X, y0 + (wallH + 0.4) / 2, center.Z) * CFrame.Angles(0, 0, RAD(90)), theme.Wall, Enum.Material.SmoothPlastic, "cyl", "Island")
	decorate(part(pool, Vector3.new(0.5, isl * 2 + 0.6, isl * 2 + 0.6), CFrame.new(center.X, y0 + wallH + 0.55, center.Z) * CFrame.Angles(0, 0, RAD(90)), theme.Trim, Enum.Material.SmoothPlastic, "cyl"))
	local basin = decorate(part(pool, Vector3.new(0.6, isl * 1.5, isl * 1.5), CFrame.new(center.X, y0 + wallH + 0.9, center.Z) * CFrame.Angles(0, 0, RAD(90)), theme.Water, Enum.Material.Glass, "cyl"), true)
	basin.Transparency = 0.3
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255))
	spray.LightEmission = 0.3
	spray.Rate = 26; spray.Lifetime = NumberRange.new(0.8, 1.2); spray.Speed = NumberRange.new(5, 7)
	spray.SpreadAngle = Vector2.new(14, 14); spray.Acceleration = Vector3.new(0, -14, 0)
	spray.Size = NumberSequence.new(0.35, 0.1); spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = basin
	local statueDuck = DuckData.List[DuckData.Pools[worldId][1][1]]
	local statue = DuckModelBuilder.Build(statueDuck, {Lite = true, Scale = 1.15})
	statue:PivotTo(CFrame.new(center.X, y0 + wallH + 1.1, center.Z) * CFrame.Angles(0, math.pi, 0))
	statue.Name = "FountainDuck"
	statue.Parent = pool
	-- deck ring (where players stand) + steps down to the ground
	local deckC = theme.Deck or Color3.fromRGB(170, 120, 70)
	local deckW = 7
	ring(pool, wc + Vector3.new(0, 0.5, 0), R + t + deckW / 2, 56, Vector3.new(deckW, 1, 0), deckC, Enum.Material.WoodPlanks, "Deck", true)
	-- canopy poles, string lights and a striped circus roof
	local poleR = R + t + deckW - 0.8
	local rimY, apexY = y0 + 17, y0 + 25
	local nPoles = 8
	local tops = {}
	for i = 0, nPoles - 1 do
		local ang = (i + 0.5) / nPoles * math.pi * 2
		local p = Vector3.new(center.X + math.cos(ang) * poleR, 0, center.Z + math.sin(ang) * poleR)
		part(pool, Vector3.new(0.9, rimY - y0, 0.9), CFrame.new(p.X, y0 + (rimY - y0) / 2, p.Z), theme.Trim, Enum.Material.Metal, nil, "Pole")
		decorate(part(pool, Vector3.new(1.4, 1.4, 1.4), CFrame.new(p.X, rimY + 0.4, p.Z), theme.Canopy1, Enum.Material.SmoothPlastic, "ball"), true)
		table.insert(tops, Vector3.new(p.X, rimY, p.Z))
	end
	for i = 1, nPoles do
		stringLights(pool, tops[i] - Vector3.new(0, 0.8, 0), tops[i % nPoles + 1] - Vector3.new(0, 0.8, 0), 7)
	end
	local roofR = poleR + 2.5
	local slices = 20
	local apex = Vector3.new(center.X, apexY, center.Z)
	for i = 0, slices - 1 do
		local a0, a1 = i / slices * math.pi * 2, (i + 1) / slices * math.pi * 2
		local p0 = Vector3.new(center.X + math.cos(a0) * roofR, rimY + 0.6, center.Z + math.sin(a0) * roofR)
		local p1 = Vector3.new(center.X + math.cos(a1) * roofR, rimY + 0.6, center.Z + math.sin(a1) * roofR)
		triangle(pool, apex, p0, p1, if i % 2 == 0 then theme.Canopy1 else theme.Canopy2, Enum.Material.Fabric, 0.3)
		-- scalloped valance
		local mid = (a0 + a1) / 2
		decorate(part(pool, Vector3.new(0.3, 2.6, 2.6), CFrame.new(center.X + math.cos(mid) * roofR, rimY + 0.3, center.Z + math.sin(mid) * roofR) * CFrame.Angles(0, -mid, 0) * CFrame.Angles(0, 0, 0), if i % 2 == 0 then theme.Canopy1 else theme.Canopy2, Enum.Material.Fabric, "cyl"), true)
	end
	-- centre pole from the fountain to the apex, topped with a flag
	part(pool, Vector3.new(0.7, apexY - (y0 + wallH), 0.7), CFrame.new(center.X, (apexY + y0 + wallH) / 2, center.Z), theme.Trim, Enum.Material.Metal, nil, "CenterPole")
	decorate(part(pool, Vector3.new(0.25, 4, 0.25), CFrame.new(center.X, apexY + 2, center.Z), WHITE, Enum.Material.Metal), true)
	decorate(part(pool, Vector3.new(0.1, 1.6, 2.6), CFrame.new(center.X, apexY + 3.2, center.Z + 1.3), theme.Canopy1, Enum.Material.Fabric), true)
	-- sign facing the plaza (+Z) and the far side
	local w = WorldData.List[worldId]
	local text = if worldId == 1 then "DUCK RNG" else string.upper(w.Name)
	for _, side in {1, -1} do
		local sign = part(pool, Vector3.new(26, 5, 0.8), CFrame.new(center.X, rimY + 4.6, center.Z + side * (roofR * 0.55)) * CFrame.Angles(RAD(side * -14), 0, 0), theme.Canopy1, Enum.Material.SmoothPlastic, nil, "Sign")
		decorate(sign, true)
		label(sign, if side > 0 then Enum.NormalId.Back else Enum.NormalId.Front, text, Color3.fromRGB(255, 230, 80))
	end
	-- a couple of duck baskets on the deck for flavour
	for i = 0, 3 do
		local ang = (i / 4) * math.pi * 2 + 0.4
		local p = Vector3.new(center.X + math.cos(ang) * (R + t + deckW - 1.6), y0 + 1.7, center.Z + math.sin(ang) * (R + t + deckW - 1.6))
		decorate(part(pool, Vector3.new(2, 1.4, 1.4), CFrame.new(p) * CFrame.Angles(0, -ang, 0), WHITE, Enum.Material.Plastic))
	end
	return pool
end

---------------------------------------------------------------- POND
-- Each world's pond is a Blender model (Assets.Meshes.Ponds.<id>) whose outline matches Shared.PoolSim.SHAPES.
-- Players walk straight in from the flat ground and wade; nothing in the pond collides.
local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local MAT = Enum.Material
-- slots come from the Blender model: RimA/RimB (pebble rim, two shades), Boulder, Shore (soil under the rim),
-- Grass, Lily, Flower, DecorA/DecorB/Glow (world extras). Water/Bed are styled from the world theme.
local POND_STYLE = {
	[1] = {RimA = {C(215, 212, 205), MAT.Slate}, RimB = {C(158, 156, 150), MAT.Slate}, Boulder = {C(190, 188, 182), MAT.Slate}, Shore = {C(92, 132, 62), MAT.Grass},
		Grass = {C(130, 178, 90), MAT.SmoothPlastic}, Lily = {C(95, 175, 70), MAT.SmoothPlastic}, Flower = {C(255, 140, 190), MAT.SmoothPlastic},
		DecorA = {C(235, 50, 60), MAT.SmoothPlastic}, DecorB = {C(250, 250, 250), MAT.SmoothPlastic}},
	[2] = {RimA = {C(230, 215, 185), MAT.Slate}, RimB = {C(172, 158, 132), MAT.Slate}, Boulder = {C(200, 186, 160), MAT.Slate}, Shore = {C(110, 170, 80), MAT.Grass},
		Grass = {C(100, 190, 80), MAT.SmoothPlastic}, Lily = {C(80, 180, 70), MAT.SmoothPlastic}, Flower = {C(255, 120, 190), MAT.SmoothPlastic}},
	[3] = {RimA = {C(236, 245, 255), MAT.Snow}, RimB = {C(150, 170, 190), MAT.Slate}, Boulder = {C(212, 232, 248), MAT.Ice}, Shore = {C(232, 242, 255), MAT.Snow},
		Grass = {C(190, 220, 232), MAT.SmoothPlastic}, DecorA = {C(225, 245, 255), MAT.Ice}, DecorB = {C(170, 225, 255), MAT.Ice}},
	[4] = {RimA = {C(72, 56, 52), MAT.Basalt}, RimB = {C(40, 32, 32), MAT.Basalt}, Boulder = {C(55, 42, 40), MAT.Basalt}, Shore = {C(48, 36, 36), MAT.Basalt},
		DecorA = {C(62, 42, 36), MAT.Basalt}, Glow = {C(255, 120, 20), MAT.Neon}},
	[5] = {RimA = {C(122, 116, 96), MAT.Slate}, RimB = {C(80, 78, 62), MAT.Slate}, Boulder = {C(95, 96, 80), MAT.Slate}, Shore = {C(62, 72, 45), MAT.Mud},
		Grass = {C(110, 122, 60), MAT.SmoothPlastic}, Lily = {C(70, 122, 50), MAT.SmoothPlastic}, Flower = {C(215, 195, 255), MAT.SmoothPlastic},
		DecorA = {C(95, 120, 55), MAT.Grass}, DecorB = {C(105, 72, 45), MAT.Wood}},
	[6] = {RimA = {C(228, 228, 255), MAT.Slate}, RimB = {C(170, 160, 230), MAT.Slate}, Boulder = {C(205, 195, 250), MAT.Slate}, Shore = {C(200, 215, 255), MAT.Sand},
		Grass = {C(150, 230, 220), MAT.SmoothPlastic}, Lily = {C(110, 200, 170), MAT.SmoothPlastic}, Flower = {C(255, 140, 240), MAT.SmoothPlastic},
		DecorA = {C(255, 140, 240), MAT.Glass}, DecorB = {C(140, 220, 255), MAT.Glass}},
	[7] = {RimA = {C(255, 252, 242), MAT.Marble}, RimB = {C(236, 222, 182), MAT.Marble}, Boulder = {C(255, 246, 228), MAT.Marble}, Shore = {C(255, 250, 240), MAT.Marble},
		Grass = {C(222, 242, 182), MAT.SmoothPlastic}, Lily = {C(150, 210, 120), MAT.SmoothPlastic}, Flower = {C(255, 215, 90), MAT.SmoothPlastic},
		DecorB = {C(255, 210, 80), MAT.Metal}},
	[8] = {RimA = {C(62, 42, 92), MAT.Slate}, RimB = {C(30, 20, 50), MAT.Slate}, Boulder = {C(46, 30, 72), MAT.Slate}, Shore = {C(32, 20, 52), MAT.Glass},
		DecorA = {C(200, 80, 255), MAT.Neon}, Glow = {C(200, 80, 255), MAT.Neon}},
}

function M.Pond(parent, worldId, theme)
	local pond = model(parent, "Pond")
	pond:SetAttribute("WorldId", worldId)
	local c = PoolSim.Center(worldId)
	local ground = Vector3.new(c.X, WorldData.List[worldId].Origin.Y, c.Z)
	local base = CFrame.new(ground)
	local lib = RS.Assets.Meshes:FindFirstChild("Ponds") and RS.Assets.Meshes.Ponds:FindFirstChild(tostring(worldId))
	local st = POND_STYLE[worldId]
	local wc = theme.Water
	local style = table.clone(st)
	style.Bed = {Color3.new(wc.R * 0.4, wc.G * 0.45, wc.B * 0.5), Enum.Material.Sand}
	if lib then
		for _, src in lib:GetChildren() do
			local p = src:Clone()
			p.CFrame = base * src.CFrame
			local s = style[src:GetAttribute("Slot")]
			if s then p.Color = s[1]; p.Material = s[2] end
			p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
			local sl = src:GetAttribute("Slot")
			p.CastShadow = sl == "RimA" or sl == "RimB" or sl == "Boulder" or sl == "DecorA" or sl == "DecorB"
			p.Name = if src.Name == "water" then "Water" else src.Name
			if src.Name == "water" then
				p.Color = wc; p.Material = Enum.Material.Glass; p.Transparency = 0.32; p.Reflectance = 0.12
				if theme.Liquid == "lava" then p.Material = Enum.Material.Neon; p.Transparency = 0.1
				elseif theme.Liquid == "void" then p.Material = Enum.Material.Neon; p.Transparency = 0.4
				elseif theme.Liquid == "swamp" then p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0.18 end
				p:SetAttribute("SurfaceY", c.Y)
				p:SetAttribute("Radius", PoolSim.Radius(worldId))
				local bub = Instance.new("ParticleEmitter")
				bub.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				bub.Color = ColorSequence.new(if theme.Liquid == "lava" then Color3.fromRGB(255, 200, 80) else Color3.new(1, 1, 1))
				bub.Transparency = NumberSequence.new(0.4, 1)
				bub.Rate = 10; bub.Lifetime = NumberRange.new(1, 2); bub.Speed = NumberRange.new(0.5, 1.2)
				bub.Size = NumberSequence.new(0.35, 0); bub.EmissionDirection = Enum.NormalId.Top
				bub.Parent = p
			elseif src.Name == "bed" then
				p.Transparency = 0
			end
			p.Parent = pond
		end
	else
		warn("[MapBuilder] pond meshes missing for world " .. worldId)
	end
	-- welcome sign on the plaza side of the shore
	local th = math.pi / 2
	local sr = PoolSim.EdgeR(worldId, th) + 10
	local sp = ground + Vector3.new(math.cos(th) * sr, 0, math.sin(th) * sr)
	local w = WorldData.List[worldId]
	for _, dx in {-4.5, 4.5} do
		part(pond, Vector3.new(0.6, 6, 0.6), CFrame.new(sp + Vector3.new(dx, 3, 0)), theme.Trim, Enum.Material.Wood, nil, "SignPost")
	end
	local sign = part(pond, Vector3.new(11, 3.2, 0.6), CFrame.new(sp + Vector3.new(0, 5.6, 0)), theme.Canopy1, Enum.Material.SmoothPlastic, nil, "Sign")
	decorate(sign, true)
	label(sign, Enum.NormalId.Back, if worldId == 1 then "DUCK POND" else string.upper(w.Name), Color3.fromRGB(255, 230, 80))
	local warnSign = part(pond, Vector3.new(9, 1.6, 0.4), CFrame.new(sp + Vector3.new(0, 3.2, 0)), Color3.fromRGB(255, 220, 60), Enum.Material.SmoothPlastic, nil, "Warn")
	decorate(warnSign, true)
	label(warnSign, Enum.NormalId.Back, "BEWARE OF MOM!", Color3.fromRGB(200, 30, 30))
	return pond
end

---------------------------------------------------------------- PORTAL
function M.Portal(parent, cf: CFrame, color: Color3, title: string, sub: string, action: string, attrs)
	local m = model(parent, "Portal_" .. title)
	part(m, Vector3.new(14, 1.2, 6), cf * CFrame.new(0, 0.6, 0), Color3.fromRGB(70, 70, 90), Enum.Material.Slate)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		decorate(part(m, Vector3.new(1.1, 1.1, 1.1), cf * CFrame.new(math.cos(a) * 5, 7 + math.sin(a) * 5.6, 0), if i % 2 == 0 then color else WHITE, Enum.Material.Neon, "ball"))
	end
	local disc = part(m, Vector3.new(0.4, 10, 9), cf * CFrame.new(0, 7, 0) * CFrame.Angles(0, RAD(90), 0), color, Enum.Material.ForceField, "cyl", "Swirl")
	disc.CanCollide = false
	disc.Size = Vector3.new(0.4, 11, 11)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(color, WHITE); pe.LightEmission = 1; pe.Rate = 25
	pe.Lifetime = NumberRange.new(1, 2); pe.Speed = NumberRange.new(1, 3); pe.Size = NumberSequence.new(0.5, 0)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Parent = disc
	local l = Instance.new("PointLight"); l.Color = color; l.Range = 18; l.Brightness = 2; l.Parent = disc
	local sign = part(m, Vector3.new(12, 2.6, 0.6), cf * CFrame.new(0, 14.6, 0), Color3.fromRGB(40, 40, 60))
	decorate(sign, true)
	label(sign, Enum.NormalId.Front, title, color)
	label(sign, Enum.NormalId.Back, title, color)
	if sub and sub ~= "" then
		local s2 = part(m, Vector3.new(10, 1.3, 0.5), cf * CFrame.new(0, 12.4, 0), Color3.fromRGB(30, 30, 45))
		decorate(s2, true)
		label(s2, Enum.NormalId.Front, sub, Color3.fromRGB(255, 255, 200))
		label(s2, Enum.NormalId.Back, sub, Color3.fromRGB(255, 255, 200))
	end
	prompt(disc, action, action == "World" and "Travel" or "Enter", title, attrs)
	return m
end

---------------------------------------------------------------- NPC
function M.NPC(parent, cf: CFrame, duckName: string, npcName: string, action: string, actionText: string, scale)
	local d = DuckData.ByName[duckName]
	local m = DuckModelBuilder.Build(d, {Scale = scale or 2.2})
	m.Name = "NPC_" .. npcName
	m:PivotTo(cf * CFrame.new(0, 1.5, 0))
	part(m, Vector3.new(1.5, 7, 7), cf * CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(255, 255, 255), Enum.Material.Marble, "cyl", "Pedestal")
	local head = m:FindFirstChild("Head")
	billboard(head or m.PrimaryPart, npcName, Color3.fromRGB(255, 230, 90), 4)
	prompt(m.PrimaryPart, action, actionText, npcName)
	m.Parent = parent
	return m
end

---------------------------------------------------------------- BOOTH
function M.Booth(parent, cf: CFrame, w, d, c1, c2, title)
	local m = model(parent, "Booth_" .. title)
	part(m, Vector3.new(w, 1, d), cf * CFrame.new(0, 0.5, 0), Color3.fromRGB(230, 220, 200), Enum.Material.WoodPlanks)
	part(m, Vector3.new(w, 10, 1), cf * CFrame.new(0, 5.5, d / 2 - 0.5), c2, Enum.Material.SmoothPlastic)
	for _, s in {-1, 1} do
		part(m, Vector3.new(1, 10, d), cf * CFrame.new(s * (w / 2 - 0.5), 5.5, 0), c2)
		part(m, Vector3.new(1, 12, 1), cf * CFrame.new(s * (w / 2 - 0.5), 6, -d / 2 + 0.5), WHITE, Enum.Material.Metal)
	end
	part(m, Vector3.new(w - 2, 3.5, 2), cf * CFrame.new(0, 2.75, -d / 2 + 2), c1, Enum.Material.WoodPlanks, nil, "Counter")
	decorate(part(m, Vector3.new(w - 1.6, 0.4, 2.4), cf * CFrame.new(0, 4.7, -d / 2 + 2), WHITE))
	stripedRoof(m, cf * CFrame.new(0, 14, 0), w + 2, d + 3, c1, WHITE, 10)
	local sign = part(m, Vector3.new(w * 0.8, 3, 0.6), cf * CFrame.new(0, 17.5, -d / 2 + 0.4), c1)
	decorate(sign, true)
	label(sign, Enum.NormalId.Front, title, Color3.fromRGB(255, 240, 120))
	return m
end

---------------------------------------------------------------- LEADERBOARD
function M.Leaderboard(parent, cf: CFrame, key: string, title: string, color: Color3)
	local m = model(parent, "Leaderboard_" .. key)
	for _, s in {-1, 1} do part(m, Vector3.new(1, 16, 1), cf * CFrame.new(s * 6.5, 8, 0.6), Color3.fromRGB(60, 60, 80), Enum.Material.Metal) end
	local board = part(m, Vector3.new(12, 14, 0.6), cf * CFrame.new(0, 9, 0), Color3.fromRGB(25, 25, 45), Enum.Material.SmoothPlastic, nil, "Board")
	local sg = Instance.new("SurfaceGui")
	sg.Name = "BoardGui"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.LightInfluence = 0
	sg.Parent = board
	local grad = Instance.new("Frame"); grad.Size = UDim2.fromScale(1, 1); grad.BackgroundColor3 = Color3.fromRGB(30, 30, 55); grad.Parent = sg
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(60, 50, 110), Color3.fromRGB(20, 20, 40)); g.Rotation = 90; g.Parent = grad
	local t = Instance.new("TextLabel"); t.Name = "Title"; t.Size = UDim2.fromScale(1, 0.13); t.BackgroundColor3 = color; t.Text = title
	t.TextScaled = true; t.Font = Enum.Font.FredokaOne; t.TextColor3 = WHITE; t.Parent = grad
	local s = Instance.new("UIStroke"); s.Thickness = 3; s.Parent = t
	local list = Instance.new("Frame"); list.Name = "List"; list.BackgroundTransparency = 1; list.Position = UDim2.fromScale(0.04, 0.15); list.Size = UDim2.fromScale(0.92, 0.83); list.Parent = grad
	local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0.008, 0); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = list
	m:SetAttribute("LeaderboardKey", key)
	return m
end

---------------------------------------------------------------- DECOR
local function palm(parent, pos: Vector3, rng)
	local lean = rng:NextNumber(-12, 12)
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), RAD(lean))
	if propMesh(parent, "Palm", cf, rng:NextNumber(0.9, 1.25)) then return end
	for i = 0, 5 do
		decorate(part(parent, Vector3.new(1.6 - i * 0.12, 2.2, 1.6 - i * 0.12), cf * CFrame.new(0, 1.1 + i * 2.1, 0) * CFrame.Angles(0, i * 0.4, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood))
	end
	local top = cf * CFrame.new(0, 13, 0)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		decorate(part(parent, Vector3.new(1.6, 0.3, 7), top * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.6, -3.2) * CFrame.Angles(RAD(-20), 0, 0), Color3.fromRGB(60, 170, 70), Enum.Material.Grass), true)
	end
	for i = 1, 3 do decorate(part(parent, Vector3.new(0.9, 0.9, 0.9), top * CFrame.new(math.cos(i * 2) * 0.6, -0.8, math.sin(i * 2) * 0.6), Color3.fromRGB(110, 70, 40), nil, "ball"), true) end
end
local function pine(parent, pos: Vector3, rng, snow)
	local h = rng:NextNumber(10, 16)
	if snow ~= nil and propMesh(parent, "Pine", CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), h / 13.9 * 1.1,
		if snow then nil else {Snow = {Color3.fromRGB(40, 115, 65), Enum.Material.SmoothPlastic}}) then return end
	decorate(part(parent, Vector3.new(1.4, 3, 1.4), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(100, 70, 45), Enum.Material.Wood))
	for i = 0, 3 do
		local r = (4 - i) * h / 10
		decorate(part(parent, Vector3.new(h / 4, r * 2, r * 2), CFrame.new(pos + Vector3.new(0, 3 + i * h / 5, 0)) * CFrame.Angles(0, 0, RAD(90)), if snow and i % 2 == 1 then WHITE else Color3.fromRGB(40, 110, 60), snow and Enum.Material.Snow or Enum.Material.Grass, "cyl"))
	end
end
local function crystal(parent, pos: Vector3, rng, color, mat)
	if propMesh(parent, "Crystals", CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber(0.7, 1.3),
		{Crystal = {color, mat or Enum.Material.Glass}}) then return end
	for i = 1, rng:NextInteger(3, 5) do
		local h = rng:NextNumber(3, 9)
		decorate(part(parent, Vector3.new(h / 3, h, h / 3), CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)) * CFrame.new(0, h / 2, 0), color, mat or Enum.Material.Glass))
	end
end
local function rock(parent, pos: Vector3, rng, color, mat)
	local s = rng:NextNumber(3, 8)
	if propMesh(parent, "Rock", CFrame.new(pos - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), s / 5,
		{Rock = {color, mat or Enum.Material.Slate, true}}) then return end
	decorate(part(parent, Vector3.new(s, s * 0.7, s * 0.9), CFrame.new(pos + Vector3.new(0, s * 0.25, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), color, mat or Enum.Material.Slate))
end
local function deadTree(parent, pos, rng)
	local c = Color3.fromRGB(60, 50, 45)
	local cf = CFrame.new(pos)
	if propMesh(parent, "DeadTree", cf * CFrame.Angles(0, rng:NextNumber(0, 6.28), RAD(rng:NextNumber(-6, 6))), rng:NextNumber(0.9, 1.3)) then return end
	decorate(part(parent, Vector3.new(1.6, 10, 1.6), cf * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, RAD(rng:NextNumber(-8, 8))), c, Enum.Material.Wood))
	for i = 1, 4 do
		local a = i * 1.6
		decorate(part(parent, Vector3.new(0.6, 5, 0.6), cf * CFrame.new(math.cos(a) * 1.5, 8 + i * 0.5, math.sin(a) * 1.5) * CFrame.Angles(math.sin(a) * 0.8, 0, -math.cos(a) * 0.8), c, Enum.Material.Wood))
	end
end
local function mushroom(parent, pos, rng, glow)
	local h = rng:NextNumber(2, 5)
	local mm, mp = propMesh(parent, "Mushroom", CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), h / 3.2,
		{Cap = {glow, Enum.Material.Neon}, TentB = {Color3.fromRGB(255, 250, 235), Enum.Material.SmoothPlastic}})
	if mm then
		if mp.Cap and h > 3.5 then local l = Instance.new("PointLight"); l.Color = glow; l.Range = 10; l.Brightness = 0.8; l.Parent = mp.Cap end
		return
	end
	decorate(part(parent, Vector3.new(h, 0.8, 0.8) * Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(230, 220, 200), nil, "cyl"))
	local cap = decorate(part(parent, Vector3.new(h * 0.9, h * 0.5, h * 0.9), CFrame.new(pos + Vector3.new(0, h, 0)), glow, Enum.Material.Neon))
	local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = cap
end
local function cloud(parent, pos, rng)
	for i = 1, 5 do
		decorate(part(parent, Vector3.one * rng:NextNumber(4, 8), CFrame.new(pos + Vector3.new(rng:NextNumber(-5, 5), rng:NextNumber(-1, 2), rng:NextNumber(-3, 3))), WHITE, Enum.Material.SmoothPlastic, "ball"), true)
	end
end
local function pillar(parent, pos, color)
	decorate(part(parent, Vector3.new(18, 3, 3), CFrame.new(pos + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, RAD(90)), color, Enum.Material.Marble, "cyl"))
	decorate(part(parent, Vector3.new(4.5, 1.2, 4.5), CFrame.new(pos + Vector3.new(0, 0.6, 0)), color, Enum.Material.Marble))
	decorate(part(parent, Vector3.new(4.5, 1.2, 4.5), CFrame.new(pos + Vector3.new(0, 18.6, 0)), color, Enum.Material.Marble))
end
local function snowman(parent, pos)
	for i, s in {4, 3, 2.2} do
		decorate(part(parent, Vector3.one * s, CFrame.new(pos + Vector3.new(0, ({2, 5.2, 7.6})[i], 0)), WHITE, Enum.Material.Snow, "ball"))
	end
	decorate(part(parent, Vector3.new(0.4, 0.4, 1.4), CFrame.new(pos + Vector3.new(0, 7.6, -1.4)), Color3.fromRGB(255, 140, 30)))
end
local function gravestone(parent, pos, rng)
	decorate(part(parent, Vector3.new(2.5, 3.5, 0.7), CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(RAD(rng:NextNumber(-10, 10)), rng:NextNumber(0, 6), 0), Color3.fromRGB(120, 120, 130), Enum.Material.Slate))
end
local function lantern(parent, pos, color)
	local lm, lp = propMesh(parent, "Lantern", CFrame.new(pos), 1, {Lamp = {color, Enum.Material.Neon}})
	if lm then
		local l = Instance.new("PointLight"); l.Color = color; l.Range = 16; l.Brightness = 1.2; l.Parent = lp.Lamp
		return
	end
	decorate(part(parent, Vector3.new(0.4, 6, 0.4), CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.fromRGB(40, 40, 40), Enum.Material.Metal))
	local b = decorate(part(parent, Vector3.new(1.2, 1.4, 1.2), CFrame.new(pos + Vector3.new(0, 6.6, 0)), color, Enum.Material.Neon), true)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = 16; l.Brightness = 1.2; l.Parent = b
end
local function tikiTorch(parent, pos)
	decorate(part(parent, Vector3.new(0.6, 6, 0.6), CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.fromRGB(140, 100, 60), Enum.Material.Wood))
	local top = decorate(part(parent, Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 6.4, 0)), Color3.fromRGB(90, 60, 40), Enum.Material.Wood))
	local f = Instance.new("Fire"); f.Size = 3; f.Heat = 5; f.Parent = top
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 160, 60); l.Range = 14; l.Parent = top
end
local function floatingCube(parent, pos, rng, color)
	local s = rng:NextNumber(2, 6)
	local p = decorate(part(parent, Vector3.one * s, CFrame.new(pos + Vector3.new(0, rng:NextNumber(8, 30), 0)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)), if rng:NextNumber() < 0.3 then color else Color3.fromRGB(15, 10, 25), if rng:NextNumber() < 0.3 then Enum.Material.Neon else Enum.Material.Glass), true)
	p:SetAttribute("Float", true)
end
local function umbrella(parent, pos, rng)
	decorate(part(parent, Vector3.new(0.3, 8, 0.3), CFrame.new(pos + Vector3.new(0, 4, 0)), WHITE))
	local cols = {Color3.fromRGB(255, 80, 80), WHITE}
	for i = 0, 7 do
		decorate(part(parent, Vector3.new(0.2, 4.4, 3.6), CFrame.new(pos + Vector3.new(0, 7.8, 0)) * CFrame.Angles(0, i * math.pi / 4, 0) * CFrame.new(0, 0, -1.8) * CFrame.Angles(RAD(70), 0, 0), cols[i % 2 + 1], Enum.Material.Fabric), true)
	end
end
local function coral(parent, pos, rng)
	local cols = {Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 170, 70), Color3.fromRGB(180, 110, 255)}
	local c = cols[rng:NextInteger(1, 3)]
	for i = 1, 4 do
		local h = rng:NextNumber(2, 5)
		decorate(part(parent, Vector3.new(h, 0.8, 0.8), CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), RAD(rng:NextNumber(50, 90))) * CFrame.new(h / 2, 0, 0), c, Enum.Material.SmoothPlastic, "cyl"))
	end
end

local function scatter(n, rng, origin, minR, maxR, fn, avoid)
	local placed = 0
	local tries = 0
	while placed < n and tries < n * 20 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(minR, maxR)
		local pos = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, box in avoid do
			if math.abs(pos.X - box[1].X) < box[2].X / 2 and math.abs(pos.Z - box[1].Z) < box[2].Z / 2 then ok = false break end
		end
		if ok then fn(pos); placed += 1 end
	end
end

---------------------------------------------------------------- WORLD THEMES
M.Themes = {
	[1] = {Water = Color3.fromRGB(40, 150, 240), Wall = Color3.fromRGB(30, 140, 235), Trim = WHITE, Canopy1 = Color3.fromRGB(235, 50, 60), Canopy2 = WHITE, Ground = Color3.fromRGB(235, 210, 160), GroundMat = Enum.Material.Sand, Plaza = Color3.fromRGB(240, 235, 225), Liquid = "water"},
	[2] = {Water = Color3.fromRGB(30, 220, 205), Wall = Color3.fromRGB(255, 170, 60), Trim = Color3.fromRGB(255, 240, 200), Canopy1 = Color3.fromRGB(60, 190, 90), Canopy2 = Color3.fromRGB(255, 240, 150), Ground = Color3.fromRGB(250, 230, 170), GroundMat = Enum.Material.Sand, Plaza = Color3.fromRGB(200, 170, 120), Liquid = "water"},
	[3] = {Water = Color3.fromRGB(140, 210, 255), Wall = Color3.fromRGB(110, 180, 240), Trim = WHITE, Canopy1 = Color3.fromRGB(80, 140, 230), Canopy2 = WHITE, Ground = Color3.fromRGB(240, 248, 255), GroundMat = Enum.Material.Snow, Plaza = Color3.fromRGB(200, 230, 250), Liquid = "water", Floor = Color3.fromRGB(200, 240, 255)},
	[4] = {Water = Color3.fromRGB(255, 100, 20), Wall = Color3.fromRGB(60, 45, 45), Trim = Color3.fromRGB(255, 140, 40), Canopy1 = Color3.fromRGB(180, 30, 20), Canopy2 = Color3.fromRGB(40, 30, 30), Ground = Color3.fromRGB(55, 40, 40), GroundMat = Enum.Material.Basalt, Plaza = Color3.fromRGB(80, 60, 55), Liquid = "lava", Floor = Color3.fromRGB(120, 30, 10), Deck = Color3.fromRGB(70, 60, 60)},
	[5] = {Water = Color3.fromRGB(70, 110, 55), Wall = Color3.fromRGB(70, 50, 90), Trim = Color3.fromRGB(170, 90, 255), Canopy1 = Color3.fromRGB(80, 40, 120), Canopy2 = Color3.fromRGB(40, 40, 50), Ground = Color3.fromRGB(55, 65, 45), GroundMat = Enum.Material.Mud, Plaza = Color3.fromRGB(70, 70, 70), Liquid = "swamp", Floor = Color3.fromRGB(40, 60, 35), Deck = Color3.fromRGB(80, 60, 50)},
	[6] = {Water = Color3.fromRGB(60, 130, 255), Wall = Color3.fromRGB(150, 120, 255), Trim = Color3.fromRGB(255, 160, 240), Canopy1 = Color3.fromRGB(255, 130, 220), Canopy2 = Color3.fromRGB(150, 230, 255), Ground = Color3.fromRGB(205, 220, 255), GroundMat = Enum.Material.Sand, Plaza = Color3.fromRGB(230, 230, 255), Liquid = "water", Floor = Color3.fromRGB(180, 160, 255)},
	[7] = {Water = Color3.fromRGB(190, 225, 255), Wall = Color3.fromRGB(255, 245, 220), Trim = Color3.fromRGB(255, 210, 80), Canopy1 = Color3.fromRGB(255, 215, 90), Canopy2 = WHITE, Ground = Color3.fromRGB(255, 252, 240), GroundMat = Enum.Material.Marble, Plaza = Color3.fromRGB(255, 240, 200), Liquid = "water", Floor = Color3.fromRGB(255, 240, 200), Deck = Color3.fromRGB(240, 230, 210)},
	[8] = {Water = Color3.fromRGB(120, 30, 210), Wall = Color3.fromRGB(25, 15, 40), Trim = Color3.fromRGB(200, 80, 255), Canopy1 = Color3.fromRGB(40, 20, 70), Canopy2 = Color3.fromRGB(200, 80, 255), Ground = Color3.fromRGB(20, 12, 35), GroundMat = Enum.Material.Glass, Plaza = Color3.fromRGB(35, 25, 55), Liquid = "void", Floor = Color3.fromRGB(20, 0, 40), Deck = Color3.fromRGB(40, 30, 60)},
}

local function island(f, origin, radius, theme)
	local g = part(f, Vector3.new(10, radius * 2, radius * 2), CFrame.new(origin + Vector3.new(0, -5.6, 0)) * CFrame.Angles(0, 0, RAD(90)), theme.Ground, theme.GroundMat, "cyl", "Ground")
	g.Transparency = 1 -- smooth terrain draws the ground; this is just a safety floor
	decorate(part(f, Vector3.new(30, radius * 1.9, radius * 1.9), CFrame.new(origin + Vector3.new(0, -24, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.new(theme.Ground.R * 0.6, theme.Ground.G * 0.55, theme.Ground.B * 0.5), Enum.Material.Rock, "cyl"))
	decorate(part(f, Vector3.new(30, radius * 1.4, radius * 1.4), CFrame.new(origin + Vector3.new(0, -50, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.new(theme.Ground.R * 0.45, theme.Ground.G * 0.4, theme.Ground.B * 0.4), Enum.Material.Rock, "cyl"))
	-- plaza and path
	part(f, Vector3.new(0.2, 46, 46), CFrame.new(origin + Vector3.new(0, 0.1, 50)) * CFrame.Angles(0, 0, RAD(90)), theme.Plaza, Enum.Material.Cobblestone, "cyl", "Plaza")
	-- invisible edge wall so players don't fall off
	for i = 1, 24 do
		local a = i / 24 * math.pi * 2
		local wpart = part(f, Vector3.new(radius * 0.27, 30, 2), CFrame.new(origin + Vector3.new(math.cos(a) * radius, 15, math.sin(a) * radius)) * CFrame.Angles(0, -a + math.pi / 2, 0), WHITE, nil, nil, "EdgeWall")
		wpart.Transparency = 1
		wpart.CanQuery = false
	end
	-- distant sea plane
	local sea = part(f, Vector3.new(radius * 3, 1, radius * 3), CFrame.new(origin + Vector3.new(0, -40, 0)), theme.Water, Enum.Material.Glass, nil, "Sea")
	sea.Transparency = 0.2; sea.CanCollide = false
	return g
end

-- Carnival fence (Blender segment, 16 studs long) ringed around the island edge in the world's colours.
function M.Border(f, origin: Vector3, radius: number, theme)
	local meshes = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Meshes")
	local lib = meshes and meshes:FindFirstChild("Fence")
	if not lib then return end
	local m = model(f, "Border")
	local N = math.max(12, math.floor(2 * math.pi * radius / 16 + 0.5))
	local chord = 2 * radius * math.sin(math.pi / N)
	local s = chord / 16
	local rm = radius * math.cos(math.pi / N)
	local g = theme.Ground
	local stone = Color3.new(g.R * 0.55 + 0.18, g.G * 0.52 + 0.17, g.B * 0.5 + 0.16)
	local style = {
		Trim = {theme.Trim, Enum.Material.SmoothPlastic},
		AccentA = {theme.Canopy1, Enum.Material.SmoothPlastic},
		AccentB = {theme.Canopy2, Enum.Material.SmoothPlastic},
		Stone = {stone, Enum.Material.Slate},
	}
	for i = 0, N - 1 do
		local th = (i + 0.5) / N * math.pi * 2
		local base = CFrame.new(origin) * CFrame.Angles(0, -th, 0) * CFrame.new(rm, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
		for _, src in lib:GetChildren() do
			local st = style[src:GetAttribute("Slot")] or style.Trim
			local p = src:Clone()
			local lp = src.CFrame
			p.Size = Vector3.new(src.Size.X * s, src.Size.Y, src.Size.Z)
			p.CFrame = base * CFrame.new(lp.X * s, lp.Y, lp.Z) * lp.Rotation
			p.Color = st[1]
			p.Material = st[2]
			p.Anchored = true
			p.CanCollide = false -- the invisible EdgeWall ring does the blocking
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = src.Name:find("pickets") ~= nil or src.Name:find("rails") ~= nil
			p.Parent = m
		end
	end
	return m
end

-- Rare duck showcase: the world's rarest ducks on pedestals with their odds (base odds here; the client adds "your odds")
function M.Showcase(parent, id, o, theme)
	local m = model(parent, "Showcase")
	local w = WorldData.List[id]
	local z = 92
	-- arch with a title
	for _, sx in {-58, 58} do
		part(m, Vector3.new(2.4, 18, 2.4), CFrame.new(o + Vector3.new(sx, 9, z + 6)), theme.Trim, Enum.Material.Marble, nil, "ArchPost")
		decorate(part(m, Vector3.new(3.2, 3.2, 3.2), CFrame.new(o + Vector3.new(sx, 19, z + 6)), theme.Canopy1, Enum.Material.Neon, "ball"), true)
	end
	local title = part(m, Vector3.new(80, 5, 1), CFrame.new(o + Vector3.new(0, 16, z + 6)), theme.Canopy1, Enum.Material.SmoothPlastic, nil, "ShowcaseTitle")
	decorate(title, true)
	label(title, Enum.NormalId.Front, "\u{2728} RAREST DUCKS OF " .. string.upper(w.Name) .. " \u{2728}", Color3.fromRGB(255, 230, 80))
	for i, r in {6, 7, 8, 9, 10} do
		local x = (i - 3) * 22
		local base = o + Vector3.new(x, 0, z)
		local tier = Rarity.List[r]
		part(m, Vector3.new(2.2, 9, 9), CFrame.new(base + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, RAD(90)), tier.Color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Marble, "cyl", "Pedestal")
		decorate(part(m, Vector3.new(0.4, 9.6, 9.6), CFrame.new(base + Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, RAD(90)), tier.Glow, Enum.Material.Neon, "cyl"), true)
		local ids = DuckData.Pools[id][r]
		local duck = ids and DuckData.List[ids[#ids]]
		if duck then
			local dm = DuckModelBuilder.Build(duck, {Scale = 1.7})
			dm:PivotTo(CFrame.new(base + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, 0))
			dm.Name = "Showcase_" .. duck.Name
			dm.Parent = m
			billboard(dm:FindFirstChild("Head") or dm.PrimaryPart, duck.Name, tier.Glow, 3.5)
		end
		local oneIn = if r >= 4 then tier.OneIn / w.Boost else tier.OneIn
		local sign = part(m, Vector3.new(9, 3.6, 0.6), CFrame.new(base + Vector3.new(0, 2.2, -6)) * CFrame.Angles(RAD(-15), 0, 0), Color3.fromRGB(40, 25, 15), Enum.Material.Wood, nil, "OddsSign")
		decorate(sign, true)
		sign:SetAttribute("ShowcaseTier", r)
		sign:SetAttribute("WorldId", id)
		label(sign, Enum.NormalId.Front, string.upper(tier.Name) .. "\n1 in " .. string.format("%s", math.floor(oneIn + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), tier.Glow)
	end
	return m
end

-- Everything the hub offers, built for any world (shop, museum, NPCs, leaderboards, altar, arena, portals)
function M.Facilities(f, id, o, theme, avoid)
	local hub = id == 1
	local R = WorldData.IslandRadius(id)
	local c1 = if hub then Color3.fromRGB(60, 140, 255) else theme.Canopy1
	local c2 = if hub then Color3.fromRGB(240, 240, 255) else theme.Canopy2
	-- net shop
	local shop = M.Booth(f, CFrame.new(o + Vector3.new(-100, 0, -8)) * CFrame.Angles(0, RAD(-90), 0), 22, 12, c1, c2, "NET SHOP")
	local first = math.clamp(id, 1, #Config.Rods - 4)
	for i = first, first + 4 do
		local rod = Config.Rods[i]
		if rod then
			local k = i - first + 1
			local rm = RodModelBuilder.Build(rod, false)
			rm:PivotTo(CFrame.new(o + Vector3.new(-104.5, 6 + k * 0.1, -8 - 7 + k * 2.8)) * CFrame.Angles(RAD(80), RAD(90), 0))
			rm.Parent = shop
		end
	end
	M.NPC(f, CFrame.new(o + Vector3.new(-92, 0, -8)) * CFrame.Angles(0, RAD(-90), 0), "Jungle Ranger Duck", "Shopkeeper Mallory", "Shop", "Open Shop", 1.8)
	-- duck museum: the rarest duck of every tier in this world
	local hall = M.Booth(f, CFrame.new(o + Vector3.new(100, 0, -8)) * CFrame.Angles(0, RAD(90), 0), 24, 14, if hub then Color3.fromRGB(175, 80, 255) else theme.Trim, Color3.fromRGB(245, 240, 255), "DUCK MUSEUM")
	for r = 1, 10 do
		local pool = DuckData.Pools[id][r]
		local d = pool and DuckData.List[pool[#pool]]
		if d then
			local x = o.X + 94 + ((r - 1) % 2) * 6 - 3
			local z = o.Z - 8 - 10 + math.floor((r - 1) / 2) * 5
			part(hall, Vector3.new(3, 2.5, 3), CFrame.new(x + 4, o.Y + 1.25, z), Rarity.List[r].Color, Enum.Material.Marble)
			local dm = DuckModelBuilder.Build(d, {Scale = 0.55})
			dm:PivotTo(CFrame.new(x + 4, o.Y + 2.6, z) * CFrame.Angles(0, RAD(-90), 0))
			dm.Parent = hall
		end
	end
	M.NPC(f, CFrame.new(o + Vector3.new(90, 0, 4)) * CFrame.Angles(0, RAD(90), 0), "Magician Duck", "Curator Quackington", "Collection", "View Collection", 1.8)
	-- PvP arena
	local arena = model(f, "PvPArena")
	local ac = o + Vector3.new(-95, 0, 80)
	local ringC = if hub then Color3.fromRGB(220, 60, 70) else theme.Canopy1
	part(arena, Vector3.new(1.5, 40, 40), CFrame.new(ac + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, RAD(90)), ringC, Enum.Material.SmoothPlastic, "cyl")
	part(arena, Vector3.new(1.7, 30, 30), CFrame.new(ac + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic, "cyl")
	for i = 1, 16 do
		local ang = i / 16 * math.pi * 2
		if i % 4 ~= 1 then
			part(arena, Vector3.new(9, 3, 4), CFrame.new(ac + Vector3.new(math.cos(ang) * 22, 1.5, math.sin(ang) * 22)) * CFrame.Angles(0, -ang + math.pi / 2, 0), Color3.fromRGB(80, 80, 110), Enum.Material.Concrete)
			part(arena, Vector3.new(9, 3, 3), CFrame.new(ac + Vector3.new(math.cos(ang) * 25, 4, math.sin(ang) * 25)) * CFrame.Angles(0, -ang + math.pi / 2, 0), Color3.fromRGB(70, 70, 100), Enum.Material.Concrete)
		end
		if i % 2 == 0 then
			decorate(part(arena, Vector3.new(1, 1, 1), CFrame.new(ac + Vector3.new(math.cos(ang) * 20, 6, math.sin(ang) * 20)), if i % 4 == 0 then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(80, 160, 255), Enum.Material.Neon, "ball"), true)
		end
	end
	local crest = part(arena, Vector3.new(0.3, 12, 12), CFrame.new(ac + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, "cyl", "ArenaCore")
	crest.Transparency = 0.4
	prompt(crest, "PvP", "Duel", "PvP Arena")
	local arenaSign = part(arena, Vector3.new(16, 3, 0.6), CFrame.new(ac + Vector3.new(0, 10, 0)), ringC)
	decorate(arenaSign, true)
	arenaSign.CFrame = CFrame.lookAt(arenaSign.Position, o + Vector3.new(0, 10, 55))
	label(arenaSign, Enum.NormalId.Front, "PVP ARENA", Color3.fromRGB(255, 240, 120))
	-- boss portal
	local bosses = WorldData.BossesByWorld[id]
	M.Portal(f, CFrame.lookAt(o + Vector3.new(95, 0, 80), o + Vector3.new(0, 0, 55)), Color3.fromRGB(255, 60, 60), "BOSS PORTAL",
		if hub then "Giant Slime awaits" else (#bosses .. " boss" .. (#bosses > 1 and "es" or "")), "Boss", {WorldId = id})
	-- rebirth altar
	local alt = model(f, "RebirthAltar")
	local rc = o + Vector3.new(0, 0, if hub then 160 else 135)
	for i = 0, 2 do
		part(alt, Vector3.new(1.2, 22 - i * 5, 22 - i * 5), CFrame.new(rc + Vector3.new(0, 0.6 + i * 1.2, 0)) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(250 - i * 30, 245 - i * 20, 255), Enum.Material.Marble, "cyl")
	end
	local crys = part(alt, Vector3.new(3, 7, 3), CFrame.new(rc + Vector3.new(0, 9, 0)) * CFrame.Angles(0, RAD(45), 0), Color3.fromRGB(255, 120, 255), Enum.Material.Neon, nil, "Crystal")
	crys.CanCollide = false
	crys:SetAttribute("Float", true)
	local l = Instance.new("PointLight"); l.Color = crys.Color; l.Range = 25; l.Brightness = 2; l.Parent = crys
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(255, 150, 255), Color3.fromRGB(150, 220, 255)); pe.LightEmission = 1; pe.Rate = 20; pe.Speed = NumberRange.new(2, 4); pe.Size = NumberSequence.new(0.6, 0); pe.Parent = crys
	for i = 1, 6 do
		local ang = i / 6 * math.pi * 2
		part(alt, Vector3.new(1.4, 8, 1.4), CFrame.new(rc + Vector3.new(math.cos(ang) * 9, 4, math.sin(ang) * 9)), Color3.fromRGB(255, 255, 255), Enum.Material.Marble)
		decorate(part(alt, Vector3.new(1.5, 1.5, 1.5), CFrame.new(rc + Vector3.new(math.cos(ang) * 9, 8.8, math.sin(ang) * 9)), Color3.fromRGB(150, 220, 255), Enum.Material.Neon, "ball"), true)
	end
	prompt(crys, "Rebirth", "Rebirth", "Rebirth Altar").MaxActivationDistance = 18
	billboard(crys, "REBIRTH", Color3.fromRGB(255, 150, 255), 6)
	-- leaderboards (every copy is filled by LeaderboardService)
	local lz = if hub then 0 else -4
	M.Leaderboard(f, CFrame.new(o + Vector3.new(-34, 0, 118 + lz)) * CFrame.Angles(0, RAD(200), 0), "Rebirths", "TOP REBIRTHS", Color3.fromRGB(200, 80, 255))
	M.Leaderboard(f, CFrame.new(o + Vector3.new(0, 0, 122 + lz)) * CFrame.Angles(0, RAD(180), 0), "Caught", "MOST DUCKS CAUGHT", Color3.fromRGB(255, 170, 40))
	M.Leaderboard(f, CFrame.new(o + Vector3.new(34, 0, 118 + lz)) * CFrame.Angles(0, RAD(160), 0), "PvP", "TOP PVP RATING", Color3.fromRGB(255, 70, 90))
	-- quest + daily NPCs
	M.NPC(f, CFrame.new(o + Vector3.new(-24, 0, 32)) * CFrame.Angles(0, RAD(200), 0), "Ringmaster Duck", "Quest Master Quackers", "Quests", "Quests", 2)
	M.NPC(f, CFrame.new(o + Vector3.new(24, 0, 32)) * CFrame.Angles(0, RAD(160), 0), "Party Duck", "Daily Dottie", "Daily", "Daily Reward", 2)
	-- portals: the hub has one per world behind the pond; other worlds get home + worlds + coop portals there
	if hub then
		for wid = 2, #WorldData.List do
			local ww = WorldData.List[wid]
			local x = -132 + (wid - 2) * 44
			local pos = o + Vector3.new(x, 0, -192 + math.abs(x) * 0.25)
			local req = if ww.Rebirth > 0 then ("Rebirth " .. ww.Rebirth .. " + ") else ""
			M.Portal(f, CFrame.lookAt(pos, o + Vector3.new(0, 0, 0)), M.Themes[wid].Canopy1:Lerp(Color3.new(1, 1, 1), 0.15), string.upper(ww.Name), req .. ww.Cost .. " coins", "World", {WorldId = wid})
		end
		M.Portal(f, CFrame.lookAt(o + Vector3.new(150, 0, 40), o + Vector3.new(0, 0, 50)), Color3.fromRGB(230, 160, 80), "COOP FIELD", "Your coop & Feathers", "Coop", {})
	else
		M.Portal(f, CFrame.lookAt(o + Vector3.new(-44, 0, -148), o + Vector3.new(0, 0, -60)), Color3.fromRGB(255, 220, 80), "CARNIVAL HUB", "Return home", "World", {WorldId = 1})
		M.Portal(f, CFrame.lookAt(o + Vector3.new(0, 0, -152), o + Vector3.new(0, 0, -60)), Color3.fromRGB(120, 200, 255), "WORLDS", "Travel anywhere", "Worlds", {})
		M.Portal(f, CFrame.lookAt(o + Vector3.new(44, 0, -148), o + Vector3.new(0, 0, -60)), Color3.fromRGB(230, 160, 80), "COOP FIELD", "Your coop & Feathers", "Coop", {})
	end
	M.Showcase(f, id, o, theme)
	-- areas the decor must stay out of
	for _, box in {
		{o + Vector3.new(-100, 0, -8), Vector3.new(36, 0, 36)}, {o + Vector3.new(100, 0, -8), Vector3.new(36, 0, 36)},
		{o + Vector3.new(-95, 0, 80), Vector3.new(62, 0, 62)}, {o + Vector3.new(95, 0, 80), Vector3.new(28, 0, 28)},
		{o + Vector3.new(0, 0, 135), Vector3.new(100, 0, 70)}, {o + Vector3.new(0, 0, 92), Vector3.new(130, 0, 30)},
		{o + Vector3.new(0, 0, 32), Vector3.new(70, 0, 20)},
		{o + Vector3.new(0, 0, if hub then -178 else -150), Vector3.new(if hub then 330 else 130, 0, 50)},
		{o + Vector3.new(150, 0, 40), Vector3.new(30, 0, 30)},
	} do table.insert(avoid, box) end
end

---------------------------------------------------------------- TERRAIN + NATURE
-- Hills are smooth Terrain (walkable); trees, plants, rocks and the waterfall are Blender props (Assets.Meshes.Props).
local C3 = Color3.fromRGB
local MAT = Enum.Material
M.TerrainStyle = {
	[1] = {Main = MAT.Grass, Edge = MAT.Sand, Hill = MAT.Rock},
	[2] = {Main = MAT.LeafyGrass, Edge = MAT.Sand, Hill = MAT.Rock},
	[3] = {Main = MAT.Snow, Edge = MAT.Glacier, Hill = MAT.Glacier},
	[4] = {Main = MAT.Basalt, Edge = MAT.Basalt, Hill = MAT.CrackedLava},
	[5] = {Main = MAT.Mud, Edge = MAT.Mud, Hill = MAT.Ground},
	[6] = {Main = MAT.Salt, Edge = MAT.Salt, Hill = MAT.Limestone},
	[7] = {Main = MAT.Sandstone, Edge = MAT.Sandstone, Hill = MAT.Pavement},
	[8] = {Main = MAT.Asphalt, Edge = MAT.Asphalt, Hill = MAT.Slate},
}
M.TerrainColors = {
	[MAT.Grass] = C3(104, 168, 70), [MAT.Sand] = C3(235, 215, 165), [MAT.Rock] = C3(128, 122, 114),
	[MAT.LeafyGrass] = C3(92, 178, 80), [MAT.Snow] = C3(240, 248, 255), [MAT.Glacier] = C3(170, 215, 240),
	[MAT.Basalt] = C3(55, 42, 40), [MAT.CrackedLava] = C3(255, 100, 30), [MAT.Mud] = C3(72, 66, 50), [MAT.Ground] = C3(86, 96, 60),
	[MAT.Salt] = C3(214, 204, 255), [MAT.Limestone] = C3(250, 190, 235), [MAT.Sandstone] = C3(255, 246, 228), [MAT.Pavement] = C3(255, 224, 150),
	[MAT.Asphalt] = C3(42, 26, 66), [MAT.Slate] = C3(26, 16, 42),
}
-- prop palettes per world: trees, small plants, colours for the Blender slots
local NATURE = {
	[1] = {trees = {{"Cypress", 3, 1.0}, {"RoundTree", 4, 1.0}}, small = {{"Bush", 3, 1.1}, {"Fern", 3, 1.2}, {"Hosta", 2, 1.2}, {"FlowerBush", 3, 1.1}},
		style = {Leaves = {C3(78, 158, 58), MAT.Grass}, Leaves2 = {C3(205, 232, 178), MAT.SmoothPlastic}, Flower = {C3(255, 120, 170), MAT.SmoothPlastic}}},
	[2] = {trees = {{"Palm", 5, 1.0}, {"RoundTree", 2, 1.0}}, small = {{"Fern", 4, 1.3}, {"FlowerBush", 3, 1.1}, {"Hosta", 2, 1.2}},
		style = {Leaves = {C3(60, 180, 70), MAT.Grass}, Leaves2 = {C3(180, 235, 120), MAT.SmoothPlastic}, Flower = {C3(255, 90, 150), MAT.SmoothPlastic}}},
	[3] = {trees = {{"Cypress", 5, 1.0}, {"RoundTree", 2, 1.0}}, small = {{"Bush", 3, 1.0}}, snow = true,
		style = {Leaves = {C3(58, 108, 92), MAT.Grass}}},
	[4] = {trees = {{"FlameTree", 6, 1.0}}, small = {{"Bush", 3, 1.0}}, fire = true,
		style = {Trunk = {C3(40, 26, 22), MAT.Basalt, true}, Leaves = {C3(70, 40, 30), MAT.Basalt}, Flame = {C3(255, 110, 20), MAT.Neon}, Flame2 = {C3(255, 220, 80), MAT.Neon}}},
	[5] = {trees = {{"RoundTree", 3, 1.1}, {"DeadTree", 3, 1.2}, {"Cypress", 1, 0.9}}, small = {{"Fern", 4, 1.3}, {"Hosta", 3, 1.2}, {"Mushroom", 2, 1.4}},
		style = {Leaves = {C3(60, 86, 44), MAT.Grass}, Leaves2 = {C3(120, 140, 80), MAT.SmoothPlastic}, Trunk = {C3(70, 55, 40), MAT.Wood, true}}},
	[6] = {trees = {{"CrystalTree", 6, 1.1}, {"RoundTree", 2, 1.0}}, small = {{"FlowerBush", 4, 1.1}},
		style = {Leaves = {C3(180, 160, 255), MAT.SmoothPlastic}, Flower = {C3(255, 150, 240), MAT.Neon}, Crystal = {C3(255, 140, 240), MAT.Glass}, Crystal2 = {C3(140, 220, 255), MAT.Glass}, Trunk = {C3(200, 190, 230), MAT.Marble, true}}},
	[7] = {trees = {{"RoundTree", 4, 1.0}, {"Cypress", 2, 1.0}}, small = {{"FlowerBush", 3, 1.1}, {"Bush", 2, 1.1}},
		style = {Leaves = {C3(255, 214, 110), MAT.SmoothPlastic}, Flower = {C3(255, 255, 255), MAT.Neon}, Trunk = {C3(240, 225, 200), MAT.Marble, true}}},
	[8] = {trees = {{"VoidTree", 6, 1.0}}, small = {{"Fern", 3, 1.2}},
		style = {Trunk = {C3(30, 18, 48), MAT.Slate, true}, Orb = {C3(200, 80, 255), MAT.Neon}, Leaves = {C3(150, 60, 230), MAT.Neon}}},
}
local FALL = {
	water = {C3(120, 195, 255), MAT.SmoothPlastic, 0.2}, lava = {C3(255, 110, 20), MAT.Neon, 0}, swamp = {C3(110, 140, 80), MAT.SmoothPlastic, 0.2},
	void = {C3(170, 60, 255), MAT.Neon, 0.25},
}
local ROCKC = {[1] = C3(140, 138, 132), [2] = C3(160, 150, 130), [3] = C3(190, 215, 235), [4] = C3(45, 34, 32), [5] = C3(95, 95, 80), [6] = C3(210, 195, 245), [7] = C3(250, 244, 230), [8] = C3(40, 26, 62)}

-- Smooth terrain sits on a 4-stud voxel grid: a full voxel row ending at y=0 renders its surface at y=+2.
-- So the ground is filled up to y=-4 and the top voxel row (-4..0) is written at half occupancy,
-- which puts the walkable surface exactly at y=0 where every building stands.
local function groundLayer(o, radius, edgeMat, mainMat, innerR, pondC, pondR)
	local T = workspace.Terrain
	local region = Region3.new(o + Vector3.new(-radius, -4, -radius), o + Vector3.new(radius, 0, radius)):ExpandToGrid(4)
	local mats, occ = T:ReadVoxels(region, 4)
	local minC = region.CFrame.Position - region.Size / 2
	for x = 1, mats.Size.X do
		local wx = minC.X + (x - 0.5) * 4
		for z = 1, mats.Size.Z do
			local wz = minC.Z + (z - 0.5) * 4
			local d = math.sqrt((wx - o.X) ^ 2 + (wz - o.Z) ^ 2)
			local m, oc = Enum.Material.Air, 0
			if d < radius - 1 then
				m = if d < innerR then mainMat else edgeMat
				oc = 0.5
				if pondC and math.sqrt((wx - pondC.X) ^ 2 + (wz - pondC.Z) ^ 2) < pondR then oc = 0.38 end
			end
			for y = 1, mats.Size.Y do mats[x][y][z] = m; occ[x][y][z] = oc end
		end
	end
	T:WriteVoxels(region, 4, mats, occ)
end
M.GroundLayer = groundLayer

local function boxDist(p, box)
	local dx = math.max(math.abs(p.X - box[1].X) - box[2].X / 2, 0)
	local dz = math.max(math.abs(p.Z - box[1].Z) - box[2].Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

local function groundY(pos)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = {workspace.Terrain}
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 80, pos.Z), Vector3.new(0, -140, 0), rp)
	return if hit then hit.Position.Y else pos.Y, hit and hit.Normal or Vector3.yAxis
end

function M.Terrain(id, o, radius, avoid)
	local T = workspace.Terrain
	local st = M.TerrainStyle[id]
	for mat, col in M.TerrainColors do pcall(function() T:SetMaterialColor(mat, col) end) end
	-- wipe this island's old terrain, then lay the ground
	T:FillBlock(CFrame.new(o + Vector3.new(0, 30, 0)), Vector3.new(radius * 2 + 60, 120, radius * 2 + 60), MAT.Air)
	T:FillCylinder(CFrame.new(o + Vector3.new(0, -10, 0)), 12, radius - 1, st.Edge)
	T:FillCylinder(CFrame.new(o + Vector3.new(0, -10, 0)), 12.2, radius - 14, st.Main)
	groundLayer(o, radius, st.Edge, st.Main, radius - 14, PoolSim.Center(id), PoolSim.Radius(id) + 1)
	-- hills: around the island edge and in the gaps between buildings, never on paths/buildings/the pond
	local rng = Random.new(id * 313)
	local hills = {}
	local pc = PoolSim.Center(id)
	local pondR = PoolSim.Radius(id)
	local function free(p, r)
		if (Vector3.new(p.X, 0, p.Z) - Vector3.new(pc.X, 0, pc.Z)).Magnitude < pondR + r + 6 then return false end
		for _, box in avoid do if boxDist(p, box) < r * 0.8 + 4 then return false end end
		for _, h in hills do if (h[1] - p).Magnitude < (h[2] + r) * 0.55 then return false end end
		return true
	end
	for _ = 1, 260 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(14, 30) * (radius / 170)
		local dist = rng:NextNumber(0.45, 1) * (radius - r - 6)
		local p = o + Vector3.new(math.cos(a) * dist, 0, math.sin(a) * dist)
		if free(p, r) then
			table.insert(hills, {p, r})
			local h = rng:NextNumber(0.42, 0.62)
			T:FillBall(p - Vector3.new(0, r * (1 - h), 0), r, st.Main)
			-- rocky crown / cliff face on bigger hills
			if r > 18 or id == 4 then
				local off = Vector3.new(rng:NextNumber(-0.3, 0.3) * r, 0, rng:NextNumber(-0.3, 0.3) * r)
				T:FillBall(p + off - Vector3.new(0, r * (1 - h) + r * 0.25, 0), r * 0.6, st.Hill)
			end
		end
		if #hills >= 14 then break end
	end
	-- waterfall hill on the back-right of the pond, its rocks pouring into the water
	local th = -1.05
	local dir = Vector3.new(math.cos(th), 0, math.sin(th))
	-- the ball's front slope meets the ground ~9 studs behind the shore, right behind the waterfall rocks
	local hillPos = Vector3.new(pc.X, o.Y, pc.Z) + dir * (PoolSim.EdgeR(id, th) + 25)
	T:FillBall(hillPos - Vector3.new(0, 6, 0), 17, st.Main)
	T:FillBall(hillPos + dir * 3 - Vector3.new(0, 8, 0), 12, st.Hill)
	-- keep the pond floor clean of terrain
	return hills, {pos = Vector3.new(pc.X, o.Y, pc.Z) + dir * (PoolSim.EdgeR(id, th) + 3.2), th = th}
end

local function pick(list, rng)
	local total = 0
	for _, e in list do total += e[2] end
	local x = rng:NextNumber(0, total)
	for _, e in list do x -= e[2]; if x <= 0 then return e end end
	return list[1]
end

-- shared by builds and live patches: cliff behind the waterfall + flowing streak particles on the water
function M.WaterfallDressing(id, wf, fall, fs)
	if not wf then return end
	local T = workspace.Terrain
	local st = M.TerrainStyle[id]
	-- "back" = away from the pond (the model's pivot has no useful orientation)
	local pc = PoolSim.Center(id)
	local base = Vector3.new(fall.pos.X, fall.pos.Y, fall.pos.Z)
	local back = (Vector3.new(base.X, 0, base.Z) - Vector3.new(pc.X, 0, pc.Z)).Unit
	local cf = CFrame.lookAt(base, base - back)
	-- stepped cliff: lower ledge + upper ledge, both behind the water sheet
	T:FillBall(base + back * 6.5 + Vector3.new(0, 1.5, 0), 5.5, st.Hill)
	T:FillBall(base + back * 9.5 + Vector3.new(0, 7.5, 0), 5.5, st.Hill)
	T:FillBall(base + back * 12 + Vector3.new(0, 4, 0), 7, st.Hill)
	for _, side in {-1, 1} do
		T:FillBall(base + back * 7 + cf.RightVector * side * 6 + Vector3.new(0, 3, 0), 5, st.Hill)
	end
	local water = wf:FindFirstChild("fall")
	if water then
		water.Material = fs[2]
		water.Transparency = fs[3]
		local flow = Instance.new("ParticleEmitter")
		flow.Name = "Flow"
		flow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		flow.Color = ColorSequence.new(Color3.new(1, 1, 1), fs[1]:Lerp(Color3.new(1, 1, 1), 0.4))
		flow.LightEmission = if fs[2] == MAT.Neon then 0.8 else 0.25
		flow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
		flow.Size = NumberSequence.new(0.7, 0.35)
		flow.Squash = NumberSequence.new(-1.2) -- long vertical streaks
		flow.Orientation = Enum.ParticleOrientation.VelocityParallel
		flow.EmissionDirection = Enum.NormalId.Bottom
		flow.Speed = NumberRange.new(10, 14)
		flow.Lifetime = NumberRange.new(0.5, 0.8)
		flow.Rate = 70
		flow.SpreadAngle = Vector2.new(4, 4)
		flow.Parent = water
	end
end

function M.Nature(f, id, o, radius, avoid, fall)
	local pal = NATURE[id]
	local theme = M.Themes[id]
	local nat = folder(f, "Nature")
	local rng = Random.new(id * 7717)
	local style = table.clone(pal.style or {})
	style.Rock = {ROCKC[id], MAT.Slate, true}
	style.Rock2 = {Color3.new(ROCKC[id].R * 0.8, ROCKC[id].G * 0.8, ROCKC[id].B * 0.8), MAT.Slate, true}
	local fs = FALL[theme.Liquid] or FALL.water
	if id == 3 then fs = {C3(200, 235, 255), MAT.Ice, 0.15} elseif id == 6 then fs = {C3(170, 150, 255), MAT.SmoothPlastic, 0.2} elseif id == 7 then fs = {C3(255, 240, 190), MAT.Neon, 0.2} end
	style.Fall = {fs[1], fs[2]}
	style.Foam = {if id == 4 then C3(255, 220, 90) else C3(245, 250, 255), if id == 4 then MAT.Neon else MAT.SmoothPlastic}
	-- waterfall into the pond
	local wf = propMesh(nat, "Waterfall", CFrame.lookAt(fall.pos, PoolSim.Center(id) * Vector3.new(1, 0, 1) + Vector3.new(0, fall.pos.Y, 0)), 1.25, style)
	if wf then
		local lip = wf:FindFirstChild("lip")
		if lip then lip.Transparency = fs[3] end
		local water = wf:FindFirstChild("fall")
		if water then
			water.Transparency = fs[3]
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(fs[1]:Lerp(Color3.new(1, 1, 1), 0.5)); pe.LightEmission = 0.5
			pe.Rate = 18; pe.Lifetime = NumberRange.new(0.5, 0.9); pe.Speed = NumberRange.new(2, 4)
			pe.Size = NumberSequence.new(0.5, 0); pe.SpreadAngle = Vector2.new(30, 30); pe.Acceleration = Vector3.new(0, -12, 0)
			pe.Parent = water
		end
	end
	M.WaterfallDressing(id, wf, fall, fs)
	table.insert(avoid, {fall.pos, Vector3.new(24, 0, 24)})
	local function plant(entry, pos, sizeMul)
		local y, n = groundY(pos)
		local cf = CFrame.new(pos.X, y - 0.15, pos.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		local scale = entry[3] * (sizeMul or 1) * rng:NextNumber(0.8, 1.25)
		local m = propMesh(nat, entry[1], cf, scale, style)
		if not m then return end
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") and p:GetAttribute("Slot") == "Snow" and not pal.snow then p:Destroy() end
		end
		if pal.fire and entry[1] == "FlameTree" and rng:NextNumber() < 0.35 then
			local crown = m:FindFirstChild("flame")
			if crown then
				local pe = Instance.new("ParticleEmitter")
				pe.Texture = "rbxasset://textures/particles/fire_main.dds"
				pe.Color = ColorSequence.new(C3(255, 200, 80), C3(255, 70, 20)); pe.LightEmission = 1
				pe.Rate = 10; pe.Lifetime = NumberRange.new(0.6, 1.1); pe.Speed = NumberRange.new(2, 4)
				pe.Size = NumberSequence.new(1.4, 0.2); pe.Parent = crown
			end
		end
		return m
	end
	-- trees: spread over the island, clustered a bit on hills
	local nTrees = math.floor(46 * (radius / 170) ^ 2)
	scatter(nTrees, rng, o, 28, radius - 12, function(p) plant(pick(pal.trees, rng), p) end, avoid)
	-- small plants everywhere + a garden ring around the pond like the reference picture
	scatter(math.floor(60 * (radius / 170) ^ 2), rng, o, 20, radius - 8, function(p) plant(pick(pal.small, rng), p) end, avoid)
	local pc = PoolSim.Center(id)
	for k = 1, 22 do
		local th = rng:NextNumber(0, math.pi * 2)
		local d = PoolSim.EdgeR(id, th) + rng:NextNumber(7, 11)
		local p = Vector3.new(pc.X + math.cos(th) * d, o.Y, pc.Z + math.sin(th) * d)
		local ok = true
		for _, box in avoid do
			if box ~= avoid[1] and math.abs(p.X - box[1].X) < box[2].X / 2 and math.abs(p.Z - box[1].Z) < box[2].Z / 2 then ok = false break end
		end
		if ok then plant(if k % 4 == 0 then pick(pal.trees, rng) else pick(pal.small, rng), p, if k % 4 == 0 then 0.8 else 1) end
	end
	-- a few trees next to the waterfall
	for k = 1, 3 do
		local side = Vector3.new(math.cos(fall.th + math.pi / 2), 0, math.sin(fall.th + math.pi / 2)) * (k - 2) * 8
		plant(pick(pal.trees, rng), fall.pos + side * 1.6 + Vector3.new(math.cos(fall.th), 0, math.sin(fall.th)) * 14, 0.9)
	end
	return nat
end

function M.BuildWorld(id: number)
	local map = workspace:FindFirstChild("Map") or Instance.new("Folder")
	map.Name = "Map"; map.Parent = workspace
	local old = map:FindFirstChild("World_" .. id)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "World_" .. id
	f:SetAttribute("WorldId", id)
	local w = WorldData.List[id]
	local o = w.Origin
	local theme = M.Themes[id]
	local radius = WorldData.IslandRadius(id)
	island(f, o, radius, theme)
	M.Border(f, o, radius - 3, theme)
	local arrival = part(f, Vector3.new(4, 1, 4), CFrame.new(o + Vector3.new(0, 0.5, 52)), WHITE, nil, nil, "Arrival")
	arrival.Transparency = 1; arrival.CanCollide = false
	local poolCenter = o + WorldData.POOL_OFFSET
	M.Pond(f, id, theme)
	local pr = PoolSim.Radius(id) * 2 + 18
	local avoid = {{poolCenter, Vector3.new(pr, 0, pr)}, {o + Vector3.new(0, 0, 50), Vector3.new(60, 0, 60)}}
	local SR = radius / 115
	local rng = Random.new(id * 977)
	local decor = folder(f, "Decor")
	M.Facilities(f, id, o, theme, avoid)
	-- hills + waterfall (terrain), then trees/plants grounded on it
	local hills, fall = M.Terrain(id, o, radius, avoid)
	M.Nature(f, id, o, radius, table.clone(avoid), fall)
	table.insert(avoid, {fall.pos, Vector3.new(26, 0, 26)})
	for _, h in hills do table.insert(avoid, {h[1], Vector3.new(h[2] * 2, 0, h[2] * 2)}) end
	if id == 1 then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "HubSpawn"; spawn.Anchored = true; spawn.Size = Vector3.new(10, 1, 10); spawn.Duration = 0
		spawn.CFrame = CFrame.new(o + Vector3.new(0, 0.5, 55))
		spawn.Color = Color3.fromRGB(255, 220, 80); spawn.Material = Enum.Material.Neon; spawn.Transparency = 0.3
		spawn.Neutral = true; spawn.Parent = f
		local tentAvoid = avoid
		-- carnival decor: tents, balloons, lights, plush duck stacks
		local tentCols = {{Color3.fromRGB(235, 50, 60), WHITE}, {Color3.fromRGB(60, 140, 255), WHITE}, {Color3.fromRGB(255, 190, 40), WHITE}, {Color3.fromRGB(80, 200, 100), WHITE}}
		local tentAvoid = table.clone(avoid)
		table.insert(tentAvoid, {o + Vector3.new(-100, 0, -8), Vector3.new(36, 0, 36)})
		table.insert(tentAvoid, {o + Vector3.new(100, 0, -8), Vector3.new(36, 0, 36)})
		table.insert(tentAvoid, {o + Vector3.new(-95, 0, 80), Vector3.new(62, 0, 62)})
		table.insert(tentAvoid, {o + Vector3.new(95, 0, 80), Vector3.new(28, 0, 28)})
		table.insert(tentAvoid, {o + Vector3.new(0, 0, 140), Vector3.new(100, 0, 70)})
		table.insert(tentAvoid, {o + Vector3.new(0, 0, -178), Vector3.new(330, 0, 50)})
		table.insert(tentAvoid, {o + Vector3.new(150, 0, -110), Vector3.new(30, 0, 30)})
		local ti = 0
		scatter(12, rng, o, 70, 195, function(pos)
			ti += 1
			local c = tentCols[ti % #tentCols + 1]
			if propMesh(decor, "Tent", CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), 0.95,
				{TentA = {c[1], Enum.Material.Fabric, true}, TentB = {c[2], Enum.Material.Fabric, true}}) then return end
			local tf = model(decor, "Tent")
			for j = 0, 11 do
				local a = j / 12 * math.pi * 2
				wedge(tf, Vector3.new(4.3, 9, 8), CFrame.new(pos) * CFrame.Angles(0, a, 0) * CFrame.new(0, 4.5, -4) * CFrame.Angles(0, math.pi, 0), if j % 2 == 0 then c[1] else c[2], Enum.Material.Fabric)
			end
			decorate(part(tf, Vector3.new(0.4, 3, 0.4), CFrame.new(pos + Vector3.new(0, 10, 0)), WHITE))
			decorate(part(tf, Vector3.new(0.1, 1.4, 2), CFrame.new(pos + Vector3.new(1, 11, 0)), c[1], Enum.Material.Fabric), true)
		end, tentAvoid)
		scatter(20, rng, o, 45, 200, function(pos)
			local cols = {Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 120, 220), Color3.fromRGB(120, 255, 140)}
			for j = 1, 3 do
				local h = 9 + j * 1.5
				decorate(part(decor, Vector3.new(0.06, h, 0.06), CFrame.new(pos + Vector3.new(j - 2, h / 2, 0)), WHITE), true)
				local b = decorate(part(decor, Vector3.new(2, 2.4, 2), CFrame.new(pos + Vector3.new(j - 2, h + 1, 0)), cols[rng:NextInteger(1, 5)], Enum.Material.SmoothPlastic), true)
				b.Reflectance = 0.15
				local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Sphere; sm.Parent = b
				b:SetAttribute("Float", true)
			end
		end, tentAvoid)
		scatter(16, rng, o, 50, 200, function(pos) lantern(decor, pos, Color3.fromRGB(255, 220, 140)) end, tentAvoid)
		-- giant decorative rubber duck statue
		local statue = DuckModelBuilder.Build(DuckData.List[1], {Scale = 6, Lite = true})
		statue:PivotTo(CFrame.new(o + Vector3.new(0, 0, -150 + 20)) * CFrame.Angles(0, 0, 0))
		statue.Name = "GiantDuckStatue"
		statue.Parent = decor
		statue:PivotTo(CFrame.new(o + Vector3.new(150, 0, -110)) * CFrame.Angles(0, RAD(-130), 0))
	else
		-- a giant statue of this world's signature duck + a few signature props
		local statue = DuckModelBuilder.Build(DuckData.List[DuckData.Pools[id][1][1]], {Scale = 5, Lite = true})
		statue.Name = "GiantDuckStatue"
		local sp = o + Vector3.new(120, 0, -95)
		statue:PivotTo(CFrame.new(sp.X, groundY(sp), sp.Z) * CFrame.Angles(0, RAD(-130), 0))
		statue.Parent = decor
		table.insert(avoid, {sp, Vector3.new(26, 0, 26)})
		if id == 2 then
			scatter(8, rng, o, 30, 105 * SR, function(p) umbrella(decor, p, rng) end, avoid)
			scatter(10, rng, o, 30, 105 * SR, function(p) tikiTorch(decor, p) end, avoid)
		elseif id == 3 then
			scatter(6, rng, o, 30, 100 * SR, function(p) snowman(decor, p) end, avoid)
			scatter(8, rng, o, 30, 110 * SR, function(p) crystal(decor, p, rng, Color3.fromRGB(180, 235, 255), Enum.Material.Ice) end, avoid)
		elseif id == 4 then
			scatter(10, rng, o, 30, 110 * SR, function(p) rock(decor, p, rng, Color3.fromRGB(40, 30, 30), Enum.Material.Basalt) end, avoid)
			scatter(8, rng, o, 30, 110 * SR, function(p) crystal(decor, p, rng, Color3.fromRGB(255, 100, 20), Enum.Material.Neon) end, avoid)
		elseif id == 5 then
			scatter(14, rng, o, 30, 110 * SR, function(p) gravestone(decor, p, rng) end, avoid)
			scatter(8, rng, o, 30, 105 * SR, function(p) lantern(decor, p, Color3.fromRGB(150, 255, 120)) end, avoid)
		elseif id == 6 then
			scatter(12, rng, o, 30, 110 * SR, function(p) crystal(decor, p, rng, if rng:NextNumber() < 0.5 then Color3.fromRGB(255, 140, 240) else Color3.fromRGB(140, 220, 255), Enum.Material.Glass) end, avoid)
			scatter(12, rng, o, 30, 110 * SR, function(p) coral(decor, p, rng) end, avoid)
		elseif id == 7 then
			scatter(10, rng, o, 35, 110 * SR, function(p) pillar(decor, p, Color3.fromRGB(255, 250, 235)) end, avoid)
			scatter(14, rng, o, 20, 140 * SR, function(p) cloud(decor, p + Vector3.new(0, rng:NextNumber(10, 30), 0), rng) end, avoid)
			scatter(8, rng, o, 30, 105 * SR, function(p) lantern(decor, p, Color3.fromRGB(255, 230, 140)) end, avoid)
		elseif id == 8 then
			scatter(30, rng, o, 20, 130 * SR, function(p) floatingCube(decor, p + Vector3.new(0, 8, 0), rng, Color3.fromRGB(200, 80, 255)) end, avoid)
		end
	end
	f.Parent = map
	return f
end

---------------------------------------------------------------- COOP FIELD
-- A separate meadow island with one coop plot per player (assigned by CoopService) and the cosmetics shop.
local CoopData = require(Shared.CoopData)
M.CoopTheme = {Water = Color3.fromRGB(40, 150, 240), Ground = Color3.fromRGB(112, 178, 78), GroundMat = Enum.Material.Grass,
	Plaza = Color3.fromRGB(196, 160, 110), Trim = Color3.fromRGB(255, 245, 225), Canopy1 = Color3.fromRGB(240, 140, 50), Canopy2 = Color3.fromRGB(255, 240, 200),
	Liquid = "water"}
local COOP_STYLE = {
	WoodA = {Color3.fromRGB(205, 150, 95), Enum.Material.WoodPlanks}, WoodB = {Color3.fromRGB(150, 100, 58), Enum.Material.Wood},
	Roof = {Color3.fromRGB(190, 75, 55), Enum.Material.WoodPlanks}, Dark = {Color3.fromRGB(35, 20, 12), Enum.Material.SmoothPlastic},
	Straw = {Color3.fromRGB(240, 205, 105), Enum.Material.Grass}, Basket = {Color3.fromRGB(215, 165, 95), Enum.Material.Fabric},
}
local function cloneLib(folder, parent, cf, style, scaleX)
	local out = {}
	for _, src in folder:GetChildren() do
		local p = src:Clone()
		local lp = src.CFrame
		if scaleX then
			p.Size = Vector3.new(src.Size.X * scaleX, src.Size.Y, src.Size.Z)
			p.CFrame = cf * CFrame.new(lp.X * scaleX, lp.Y, lp.Z) * lp.Rotation
		else
			p.CFrame = cf * lp
		end
		local st = style and style[src:GetAttribute("Slot")]
		if st then p.Color = st[1]; p.Material = st[2] end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Parent = parent
		out[src.Name] = p
	end
	return out
end

function M.CoopPlot(parent, i)
	local cf = CoopData.PlotCFrame(i)
	local m = model(parent, "Plot_" .. i)
	m:SetAttribute("PlotIndex", i)
	local W, D = 44, 36
	part(m, Vector3.new(W, 0.3, D), cf * CFrame.new(0, 0.15, 0), Color3.fromRGB(150, 115, 75), Enum.Material.Ground, nil, "Yard")
	part(m, Vector3.new(W - 6, 0.32, D - 6), cf * CFrame.new(0, 0.17, 0), Color3.fromRGB(120, 175, 80), Enum.Material.Grass, nil, "Lawn")
	-- coop at the back of the plot, door facing the path
	local coopF = folder(m, "Coop")
	local lib = RS.Assets.Meshes:FindFirstChild("Coop")
	local parts = lib and cloneLib(lib, coopF, cf * CFrame.new(0, 0, 8), COOP_STYLE) or {}
	-- invisible solid floor/legs so players can climb the ramp into the coop
	local floor = part(m, Vector3.new(10.6, 0.5, 8.6), cf * CFrame.new(0, 3.95, 8), WHITE, nil, nil, "CoopFloor")
	floor.Transparency = 1
	for _, sx in {-1, 1} do
		local wall = part(m, Vector3.new(0.6, 8, 8.6), cf * CFrame.new(sx * 5.2, 8, 8), WHITE, nil, nil, "CoopWall"); wall.Transparency = 1
	end
	local back = part(m, Vector3.new(10.6, 8, 0.6), cf * CFrame.new(0, 8, 12.2), WHITE, nil, nil, "CoopWall"); back.Transparency = 1
	local ramp = part(m, Vector3.new(2.8, 0.4, 7.4), cf * CFrame.new(1.2, 2.0, 1) * CFrame.Angles(math.atan2(4, 6), 0, 0), WHITE, nil, nil, "CoopRamp")
	ramp.Transparency = 1
	-- collect basket (the Blender basket in front of the coop)
	local basket = parts.basket
	if basket then
		basket.Name = "FeatherBasket"
		basket.CanQuery = true
		local pp = prompt(basket, "CoopCollect", "Collect Feathers", "Feather Basket")
		pp.MaxActivationDistance = 12
		local glow = Instance.new("ParticleEmitter")
		glow.Name = "FeatherGlow"; glow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		glow.Color = ColorSequence.new(Color3.fromRGB(255, 190, 210)); glow.LightEmission = 0.6; glow.Rate = 0
		glow.Size = NumberSequence.new(0.5, 0); glow.Speed = NumberRange.new(1, 2); glow.Parent = basket
	end
	-- rustic fence around the yard with an opening at the front
	local fl = RS.Assets.Meshes:FindFirstChild("CoopFence")
	if fl then
		local function edge(a: Vector3, b: Vector3, gapCenter)
			local len = (b - a).Magnitude
			local n = math.max(1, math.floor(len / 8 + 0.5))
			local step = len / n
			local dir = (b - a).Unit
			for k = 0, n - 1 do
				local mid = a + dir * (step * (k + 0.5))
				if gapCenter and math.abs((mid - gapCenter).Magnitude) < 6 then continue end
				local scf = cf * CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.pi / 2, 0)
				cloneLib(fl, m, scf, COOP_STYLE, step / 8)
			end
		end
		local hw, hd = W / 2, D / 2
		edge(Vector3.new(-hw, 0, hd), Vector3.new(hw, 0, hd))
		edge(Vector3.new(-hw, 0, -hd), Vector3.new(-hw, 0, hd))
		edge(Vector3.new(hw, 0, hd), Vector3.new(hw, 0, -hd))
		edge(Vector3.new(hw, 0, -hd), Vector3.new(-hw, 0, -hd), Vector3.new(0, 0, -hd))
	end
	-- owner sign at the gate
	local sp = cf * CFrame.new(-9, 0, -D / 2 - 1)
	for _, dx in {-3.2, 3.2} do part(m, Vector3.new(0.5, 6.5, 0.5), sp * CFrame.new(dx, 3.25, 0), Color3.fromRGB(150, 100, 58), Enum.Material.Wood) end
	local board = part(m, Vector3.new(7.6, 2.8, 0.4), sp * CFrame.new(0, 5.2, 0), Color3.fromRGB(205, 150, 95), Enum.Material.WoodPlanks, nil, "OwnerSign")
	decorate(board, true)
	local t = label(board, Enum.NormalId.Front, "Free plot", Color3.fromRGB(255, 240, 200))
	t.Name = "OwnerText"
	local pp2 = prompt(board, "Coop", "Manage Coop", "Coop")
	pp2.MaxActivationDistance = 12
	folder(m, "Ducks")
	return m
end

function M.BuildCoopField()
	local map = workspace:FindFirstChild("Map") or Instance.new("Folder")
	map.Name = "Map"; map.Parent = workspace
	local old = map:FindFirstChild("CoopField")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "CoopField"
	local o = CoopData.FIELD_ORIGIN
	local theme = M.CoopTheme
	island(f, o, 160, theme)
	M.Border(f, o, 157, theme)
	local T = workspace.Terrain
	pcall(function() T:SetMaterialColor(MAT.Grass, M.TerrainColors[MAT.Grass]) end)
	T:FillBlock(CFrame.new(o + Vector3.new(0, 30, 0)), Vector3.new(380, 120, 380), MAT.Air)
	T:FillCylinder(CFrame.new(o + Vector3.new(0, -10, 0)), 12, 159, MAT.Grass)
	groundLayer(o, 160, MAT.Grass, MAT.Grass, 160)
	for k = 1, 10 do
		local a = k / 10 * math.pi * 2 + 0.3
		local p = o + Vector3.new(math.cos(a) * 138, 0, math.sin(a) * 138)
		T:FillBall(p - Vector3.new(0, 9, 0), 18, MAT.Grass)
	end
	-- central dirt path and a crossing path to the shop
	part(f, Vector3.new(230, 0.25, 12), CFrame.new(o + Vector3.new(0, 0.12, 0)), theme.Plaza, Enum.Material.Ground, nil, "Path")
	part(f, Vector3.new(12, 0.25, 230), CFrame.new(o + Vector3.new(0, 0.12, 0)), theme.Plaza, Enum.Material.Ground, nil, "Path")
	local plots = folder(f, "Plots")
	for i = 1, CoopData.PLOTS do M.CoopPlot(plots, i) end
	-- cosmetics shop
	local shop = M.Booth(f, CFrame.new(o + Vector3.new(0, 0, 112)) * CFrame.Angles(0, math.pi, 0), 26, 14, Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 240, 250), "STYLE SHOP")
	M.NPC(f, CFrame.new(o + Vector3.new(0, 0, 100)) * CFrame.Angles(0, math.pi, 0), "Party Duck", "Stylist Feathers", "Style", "Browse Cosmetics", 2)
	-- way back
	M.Portal(f, CFrame.lookAt(o + Vector3.new(0, 0, -112), o), Color3.fromRGB(120, 200, 255), "BACK TO THE PONDS", "Return to your world", "LeaveCoop", {})
	local rng = Random.new(4242)
	local avoid = {{o, Vector3.new(240, 0, 16)}, {o, Vector3.new(16, 0, 240)}, {o + Vector3.new(0, 0, 108), Vector3.new(40, 0, 30)}, {o + Vector3.new(0, 0, -112), Vector3.new(30, 0, 20)}}
	for i = 1, CoopData.PLOTS do
		table.insert(avoid, {CoopData.PlotCFrame(i).Position, Vector3.new(50, 0, 42)})
	end
	local decor = folder(f, "Decor")
	scatter(26, rng, o, 30, 150, function(p) pine(decor, p, rng, false) end, avoid)
	scatter(14, rng, o, 30, 150, function(p) rock(decor, p, rng, Color3.fromRGB(140, 135, 125), Enum.Material.Slate) end, avoid)
	scatter(10, rng, o, 20, 140, function(p) lantern(decor, p, Color3.fromRGB(255, 220, 140)) end, avoid)
	f.Parent = map
	return f
end
return M
