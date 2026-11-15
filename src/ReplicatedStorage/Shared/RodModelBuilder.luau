-- Builds fishing rod Tools (and display models) from Config.Rods entries.
-- The pole extends along the Handle's -Z axis; a part named "Tip" marks where the line starts.
local Builder = {}
local RAD = math.rad

local function weldPart(handle: BasePart, parent: Instance, shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material)
	local p = Instance.new("Part")
	if shape == "cyl" then p.Shape = Enum.PartType.Cylinder elseif shape == "ball" then p.Shape = Enum.PartType.Ball end
	p.Size = size
	p.Color = color
	p.Material = mat
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CFrame = handle.CFrame * cf
	if mat == Enum.Material.Glass then p.Transparency = 0.15 end
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = p
	w.Parent = p
	p.Parent = parent
	return p
end

function Builder.Lib()
	local a = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local m = a and (a:FindFirstChild("Meshes") or a:WaitForChild("Meshes", 5))
	return m and m:FindFirstChild("Rod") and m
end

local function meshPart(src: MeshPart, handle: BasePart?, parent: Instance, cf: CFrame, color: Color3, mat: Enum.Material)
	local p = src:Clone()
	p.Color = color
	p.Material = mat
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CFrame = (if handle then handle.CFrame * cf else cf)
	if handle then
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = parent
	return p
end

-- Blender rod: cork handle, metal reel, tapered pole with guides. Pole length grows with tier.
function Builder.BuildMesh(rod, asTool, container, lib, mat, tier)
	local R = lib.Rod
	local handleSrc = R:FindFirstChild("handle__Cork")
	local handle = meshPart(handleSrc, nil, container, CFrame.new(), Color3.fromRGB(196, 150, 100), Enum.Material.Fabric)
	handle.Name = "Handle"
	handle.Anchored = not asTool
	local function rel(src: BasePart, cf: CFrame?)
		return handleSrc.CFrame:Inverse() * (cf or src.CFrame)
	end
	local len = 5 + tier * 0.15
	local s = len / 5.6
	local START = -0.9
	local function stretched(src: BasePart)
		local c = src.Position
		return CFrame.new(c.X, c.Y, START + (c.Z - START) * s) * src.CFrame.Rotation, Vector3.new(src.Size.X, src.Size.Y, src.Size.Z * s)
	end
	local reel = meshPart(R["reel__Metal"], handle, container, rel(R["reel__Metal"]), Color3.fromRGB(80, 82, 95), Enum.Material.Metal)
	reel.Name = "Reel"
	local pcf, psize = stretched(R["pole__RodColor"])
	local pole = meshPart(R["pole__RodColor"], handle, container, rel(R["pole__RodColor"], pcf), rod.Color, mat)
	pole.Size = psize
	pole.Name = "Pole"
	if mat == Enum.Material.Glass then pole.Transparency = 0.15 end
	local gcf, gsize = stretched(R["guides__Metal"])
	local guides = meshPart(R["guides__Metal"], handle, container, rel(R["guides__Metal"], gcf), if tier >= 6 then rod.Tip else Color3.fromRGB(210, 212, 220), if tier >= 6 then Enum.Material.Neon else Enum.Material.Metal)
	guides.Size = gsize
	guides.Name = "Guides"
	local function wp(shape, size, cf, color, m)
		return weldPart(handle, container, shape, size, rel(handleSrc, cf), color, m)
	end
	local tipZ = START - len
	local tip = wp("ball", Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0, tipZ), rod.Tip, if tier >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	tip.Name = "Tip"
	local att = Instance.new("Attachment"); att.Name = "LineAttachment"; att.Parent = tip
	if tier >= 3 then
		for i = 1, math.min(tier - 1, 6) do
			wp("cyl", Vector3.new(0.06, 0.28, 0.28), CFrame.new(0, 0, START - 0.2 - i * (len / 7)) * CFrame.Angles(0, RAD(90), 0), rod.Tip, if tier >= 6 then Enum.Material.Neon else Enum.Material.Metal)
		end
	end
	if tier >= 5 then
		local gem = wp("ball", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 0, 1.05), rod.Tip, Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = rod.Tip; l.Range = 6; l.Brightness = 1; l.Parent = gem
	end
	if tier >= 6 then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(rod.Tip, rod.Color)
		pe.LightEmission = 0.8
		pe.Rate = 4 + tier
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Speed = NumberRange.new(0.2, 0.6)
		pe.Size = NumberSequence.new(0.25, 0)
		pe.Parent = tip
	end
	if tier >= 9 then
		for i = 1, 3 do
			wp("ball", Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.cos(i * 2.1) * 0.35, math.sin(i * 2.1) * 0.35, tipZ), rod.Tip, Enum.Material.Neon)
		end
	end
	if not asTool then (container :: Model).PrimaryPart = handle end
	return container
end

-- Catching net (Blender): grip + pole along -Z, horizontal hoop at the end with a hanging mesh bag.
-- Parts: Handle (grip), Pole, Hoop (named "Tip" for compatibility), Bag. Higher tiers glow and sparkle.
function Builder.BuildNet(rod, asTool, container, lib, mat, tier)
	local N = lib.Net
	local gripSrc = N["grip__Grip"]
	local handle = meshPart(gripSrc, nil, container, CFrame.new(), Color3.fromRGB(45, 45, 52), Enum.Material.Rubber)
	handle.Name = "Handle"
	handle.Anchored = not asTool
	local function rel(src)
		return gripSrc.CFrame:Inverse() * src.CFrame
	end
	local pole = meshPart(N["pole__RodColor"], handle, container, rel(N["pole__RodColor"]), rod.Color, mat)
	pole.Name = "Pole"
	if mat == Enum.Material.Glass then pole.Transparency = 0.1 end
	local metal = if tier >= 4 then Color3.fromRGB(255, 205, 70) else Color3.fromRGB(200, 204, 215)
	meshPart(N["collar__Metal"], handle, container, rel(N["collar__Metal"]), metal, Enum.Material.Metal).Name = "Collar"
	meshPart(N["cap__Metal"], handle, container, rel(N["cap__Metal"]), metal, Enum.Material.Metal).Name = "Cap"
	local hoop = meshPart(N["hoop__Tip"], handle, container, rel(N["hoop__Tip"]), rod.Tip, if tier >= 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	hoop.Name = "Tip"
	local att = Instance.new("Attachment"); att.Name = "LineAttachment"; att.Parent = hoop
	local bag = meshPart(N["bag__Mesh"], handle, container, rel(N["bag__Mesh"]), if tier >= 6 then rod.Tip:Lerp(Color3.new(1, 1, 1), 0.55) else Color3.fromRGB(245, 245, 240), if tier >= 8 then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	bag.Name = "Bag"
	if tier >= 8 then bag.Transparency = 0.25 end
	if tier >= 5 then
		local gem = weldPart(handle, container, "ball", Vector3.new(0.28, 0.28, 0.28), rel(N["cap__Metal"]) * CFrame.new(0, 0, 0.12), rod.Tip, Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = rod.Tip; l.Range = 6; l.Brightness = 1; l.Parent = gem
	end
	if tier >= 6 then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(rod.Tip, rod.Color)
		pe.LightEmission = 0.8
		pe.Rate = 4 + tier
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Speed = NumberRange.new(0.2, 0.6)
		pe.Size = NumberSequence.new(0.25, 0)
		pe.Parent = hoop
	end
	if not asTool then (container :: Model).PrimaryPart = handle end
	return container
end

function Builder.Build(rod, asTool: boolean)
	local container: Instance
	if asTool then
		local tool = Instance.new("Tool")
		tool.Name = rod.Name
		tool.CanBeDropped = false
		tool.RequiresHandle = true
		tool.ToolTip = "Wade in and scoop a duck, then escape Mom!"
		tool.Grip = CFrame.new(0, 0, 0.6) * CFrame.Angles(RAD(-55), 0, 0)
		tool:SetAttribute("RodId", rod.Id)
		container = tool
	else
		local m = Instance.new("Model")
		m.Name = rod.Name
		container = m
	end
	local mat = Enum.Material[rod.Mat] or Enum.Material.SmoothPlastic
	local lib = Builder.Lib()
	if lib and lib:FindFirstChild("Net") then
		return Builder.BuildNet(rod, asTool, container, lib, mat, rod.Id)
	elseif lib then
		return Builder.BuildMesh(rod, asTool, container, lib, mat, rod.Id)
	end
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.35, 1.6)
	handle.Color = Color3.fromRGB(40, 40, 45)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Anchored = not asTool
	handle.CFrame = CFrame.new()
	handle.Parent = container
	local tier = rod.Id
	-- reel
	weldPart(handle, container, "cyl", Vector3.new(0.3, 0.6, 0.6), CFrame.new(0.3, -0.1, -0.2), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
	weldPart(handle, container, "cyl", Vector3.new(0.05, 0.4, 0.4), CFrame.new(0.47, -0.1, -0.2), rod.Tip, Enum.Material.SmoothPlastic)
	-- pole (tapering segments)
	local len = 5 + tier * 0.15
	local segs = 4
	for i = 0, segs - 1 do
		local r = 0.22 - i * 0.04
		weldPart(handle, container, "cyl", Vector3.new(len / segs + 0.02, r, r),
			CFrame.new(0, 0, -0.8 - len / segs * (i + 0.5)) * CFrame.Angles(0, RAD(90), 0), rod.Color, mat)
		-- line guides
		weldPart(handle, container, "cyl", Vector3.new(0.04, 0.16, 0.16), CFrame.new(0, -0.1, -0.8 - len / segs * (i + 0.9)) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
	end
	local tip = weldPart(handle, container, "ball", Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0, -0.8 - len), rod.Tip, if tier >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	tip.Name = "Tip"
	local att = Instance.new("Attachment"); att.Name = "LineAttachment"; att.Parent = tip
	-- tier decorations
	if tier >= 3 then
		for i = 1, math.min(tier - 1, 6) do
			weldPart(handle, container, "cyl", Vector3.new(0.06, 0.3, 0.3), CFrame.new(0, 0, -1 - i * (len / 7)) * CFrame.Angles(0, RAD(90), 0), rod.Tip, if tier >= 6 then Enum.Material.Neon else Enum.Material.Metal)
		end
	end
	if tier >= 5 then
		local gem = weldPart(handle, container, "ball", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 0, 0.9), rod.Tip, Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = rod.Tip; l.Range = 6; l.Brightness = 1; l.Parent = gem
	end
	if tier >= 6 then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(rod.Tip, rod.Color)
		pe.LightEmission = 0.8
		pe.Rate = 4 + tier
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Speed = NumberRange.new(0.2, 0.6)
		pe.Size = NumberSequence.new(0.25, 0)
		pe.Parent = tip
	end
	if tier >= 9 then
		for i = 1, 3 do
			weldPart(handle, container, "ball", Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.cos(i * 2.1) * 0.35, math.sin(i * 2.1) * 0.35, -0.8 - len), rod.Tip, Enum.Material.Neon)
		end
	end
	if not asTool then (container :: Model).PrimaryPart = handle end
	return container
end

-- Bobber model used for casting visuals
function Builder.Bobber(color: Color3)
	local lib = Builder.Lib()
	local B = lib and lib:FindFirstChild("Bobber")
	if B then
		local m = Instance.new("Model")
		m.Name = "Bobber"
		local function mk(src, name, c)
			local p = src:Clone()
			p.Name = name; p.Color = c; p.Material = Enum.Material.SmoothPlastic
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Reflectance = 0.08
			p.Parent = m
			return p
		end
		local top = mk(B["top__Cap"], "Top", color)
		mk(B["bottom__TentB"], "Bottom", Color3.new(1, 1, 1))
		local att = Instance.new("Attachment"); att.Name = "LineAttachment"; att.Position = Vector3.new(0, top.Size.Y / 2, 0); att.Parent = top
		m.PrimaryPart = top
		return m
	end
	local m = Instance.new("Model")
	m.Name = "Bobber"
	local top = Instance.new("Part")
	top.Shape = Enum.PartType.Ball
	top.Size = Vector3.new(0.7, 0.7, 0.7)
	top.Color = color
	top.Material = Enum.Material.SmoothPlastic
	top.Anchored = true
	top.CanCollide = false
	top.CanQuery = false
	top.Name = "Top"
	top.Parent = m
	local bot = top:Clone()
	bot.Color = Color3.new(1, 1, 1)
	bot.Size = Vector3.new(0.72, 0.72, 0.72)
	bot.CFrame = top.CFrame * CFrame.new(0, -0.25, 0)
	bot.Name = "Bottom"
	bot.Parent = m
	local att = Instance.new("Attachment"); att.Name = "LineAttachment"; att.Position = Vector3.new(0, 0.35, 0); att.Parent = top
	m.PrimaryPart = top
	return m
end

return Builder
