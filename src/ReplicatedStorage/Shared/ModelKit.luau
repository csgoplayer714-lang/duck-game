-- Procedural modeling helpers shared by duck, boss, rod and environment builders.
-- Builds a welded assembly on an anchored invisible Root so the whole model moves by setting Root.CFrame.
local Kit = {}
Kit.__index = Kit

local MATERIALS = {
	P = Enum.Material.SmoothPlastic, M = Enum.Material.Foil, G = Enum.Material.Glass,
	N = Enum.Material.SmoothPlastic, I = Enum.Material.Ice, F = Enum.Material.ForceField,
}
Kit.MaterialCodes = MATERIALS

function Kit.new(name: string, rootSize: Vector3?)
	local self = setmetatable({}, Kit)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = rootSize or Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	self.Model = model
	self.Root = root
	self.Count = 0
	return self
end

local function setupPart(p: BasePart)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
end

-- shape: "ball" (ellipsoid via SpecialMesh), "sphere" (true Ball), "cyl" (axis X), "block", "wedge", "corner"
function Kit:Part(shape: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, parent: BasePart?)
	local p: BasePart
	if shape == "wedge" then
		p = Instance.new("WedgePart")
	elseif shape == "corner" then
		p = Instance.new("CornerWedgePart")
	else
		p = Instance.new("Part")
		if shape == "cyl" then (p :: Part).Shape = Enum.PartType.Cylinder
		elseif shape == "sphere" then (p :: Part).Shape = Enum.PartType.Ball end
	end
	setupPart(p)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	if shape == "ball" then
		-- ellipsoid: block part sized to the bounds, sphere mesh fills it
		p.Size = size
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	else
		p.Size = size
	end
	local attach = parent or self.Root
	p.CFrame = attach.CFrame * cf
	if p.Material == Enum.Material.Glass then p.Transparency = 0.12 end
	local w = Instance.new("WeldConstraint")
	w.Part0 = attach
	w.Part1 = p
	w.Parent = p
	p.Parent = self.Model
	self.Count += 1
	return p
end

-- Mesh library (Blender-made MeshParts, authored in model space: duck/boss space with feet at y=0, facing -Z)
local meshRoot
function Kit.Meshes(): Folder
	if not meshRoot then
		meshRoot = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Meshes")
	end
	return meshRoot
end

-- Clone a library MeshPart into the model. `cf` defaults to the part's library CFrame (model space).
-- `weldTo` is the part it's rigidly attached to (default Root); the weld keeps the current relative offset.
function Kit:Mesh(src: MeshPart, color: Color3, material: Enum.Material?, weldTo: BasePart?, cf: CFrame?)
	local p = src:Clone()
	setupPart(p)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = self.Root.CFrame * (cf or src.CFrame)
	if p.Material == Enum.Material.Glass then p.Transparency = 0.15 end
	local w = Instance.new("WeldConstraint")
	w.Part0 = weldTo or self.Root
	w.Part1 = p
	w.Parent = p
	p.Parent = self.Model
	self.Count += 1
	return p
end

-- Invisible pivot part driven by a Motor6D (for animation). `pivot` is in model space.
function Kit:Joint(name: string, pivot: CFrame, parentJoint: BasePart?)
	local j = Instance.new("Part")
	setupPart(j)
	j.Name = name
	j.Size = Vector3.new(0.05, 0.05, 0.05)
	j.Transparency = 1
	j.CFrame = self.Root.CFrame * pivot
	local p0 = parentJoint or self.Root
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = j
	m.C0 = p0.CFrame:ToObjectSpace(j.CFrame)
	m.C1 = CFrame.new()
	m.Parent = j
	j.Parent = self.Model
	return j, m
end

-- A spinning hub (invisible). Children attached with Kit:Part(..., hub). Client animators rotate it.
function Kit:Hub(cf: CFrame, spinSpeed: number, axis: string?)
	local hub = Instance.new("Part")
	setupPart(hub)
	hub.Name = "SpinHub"
	hub.Size = Vector3.new(0.1, 0.1, 0.1)
	hub.Transparency = 1
	hub.CFrame = self.Root.CFrame * cf
	local w = Instance.new("Weld")
	w.Name = "SpinWeld"
	w.Part0 = self.Root
	w.Part1 = hub
	w.C0 = cf
	w.Parent = hub
	hub:SetAttribute("Spin", spinSpeed)
	hub:SetAttribute("Axis", axis or "Y")
	hub:SetAttribute("BaseC0", cf)
	hub.Parent = self.Model
	return hub
end

-- Approximated cone from stacked cylinders, base at cf (pointing along cf.UpVector)
function Kit:Cone(cf: CFrame, height: number, radius: number, color: Color3, mat: Enum.Material?, tiers: number?, parent: BasePart?)
	tiers = tiers or 5
	local parts = {}
	for i = 0, tiers - 1 do
		local f = 1 - i / tiers
		local h = height / tiers
		local r = radius * f
		local p = self:Part("cyl", Vector3.new(h * 1.02, r * 2, r * 2), cf * CFrame.new(0, h * (i + 0.5), 0) * CFrame.Angles(0, 0, math.pi / 2), color, mat, parent)
		table.insert(parts, p)
	end
	return parts
end

-- Ring of small balls around cf's Y axis
function Kit:Ring(cf: CFrame, radius: number, count: number, ballSize: number, color: Color3 | {Color3}, mat: Enum.Material?, parent: BasePart?)
	local parts = {}
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local c = if typeof(color) == "table" then (color :: {Color3})[(i - 1) % #(color :: {Color3}) + 1] else color :: Color3
		local p = self:Part("ball", Vector3.new(ballSize, ballSize, ballSize), cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius), c, mat, parent)
		table.insert(parts, p)
	end
	return parts
end

-- Curved chain of balls (horns, tentacles, tails). bend in radians per segment around X.
function Kit:Chain(cf: CFrame, segments: number, startSize: number, endSize: number, segLen: number, bend: number, color: Color3, mat: Enum.Material?, parent: BasePart?)
	local cur = cf
	for i = 0, segments - 1 do
		local f = i / math.max(1, segments - 1)
		local s = startSize + (endSize - startSize) * f
		self:Part("ball", Vector3.new(s, s * 1.3, s), cur, color, mat, parent)
		cur = cur * CFrame.Angles(bend, 0, 0) * CFrame.new(0, segLen, 0)
	end
end

function Kit:Particles(parentPart: BasePart, props: {[string]: any})
	local pe = Instance.new("ParticleEmitter")
	pe.LightEmission = 0.6
	pe.Rate = 12
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)})
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	for k, v in props do (pe :: any)[k] = v end
	pe.Parent = parentPart
	return pe
end

function Kit:Light(parentPart: BasePart, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parentPart
	return l
end

function Kit.Darken(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end
function Kit.Lighten(c: Color3, f: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), f)
end

Kit.Textures = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Star = "rbxasset://textures/particles/sparkles_main.dds",
}

return Kit
