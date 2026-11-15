-- Procedural 3D boss models. Each faces -Z with feet at y=0. A part named "Head" marks the focus point.
local Kit = require(script.Parent.ModelKit)
local DuckModelBuilder = require(script.Parent.DuckModelBuilder)

local B = {}
local RAD = math.rad
local SP, NEON, METAL, GLASS, ICE = Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Foil, Enum.Material.Glass, Enum.Material.Ice
local WHITE, BLACK, GOLD = Color3.new(1, 1, 1), Color3.fromRGB(15, 15, 20), Color3.fromRGB(255, 200, 50)

local function eyes(k, cf, spacing, size, color, mat)
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(size, size, size * 0.6), cf * CFrame.new(s * spacing, 0, 0), WHITE)
		k:Part("ball", Vector3.new(size * 0.55, size * 0.6, size * 0.4), cf * CFrame.new(s * spacing, 0, -size * 0.2), color or BLACK, mat or SP)
	end
end

B[1] = function(k) -- Giant Slime
	local g = Color3.fromRGB(110, 255, 100)
	local body = k:Part("ball", Vector3.new(13, 10, 13), CFrame.new(0, 5, 0), g, GLASS)
	body.Transparency = 0.35
	k:Part("ball", Vector3.new(9, 7, 9), CFrame.new(0, 4.5, 0), Color3.fromRGB(60, 190, 60), SP).Transparency = 0.2
	k:Part("cyl", Vector3.new(0.3, 16, 16), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, RAD(90)), g, GLASS).Transparency = 0.4
	local head = k:Part("ball", Vector3.new(1, 1, 1), CFrame.new(0, 7, -5), g); head.Name = "Head"; head.Transparency = 1
	eyes(k, CFrame.new(0, 7, -5.8), 2, 2.4)
	k:Part("ball", Vector3.new(4, 1.2, 0.6), CFrame.new(0, 4.5, -6.2), BLACK)
	for i = 1, 6 do -- goo drips on top
		local a = i / 6 * math.pi * 2
		k:Part("ball", Vector3.new(1.6, 2.2, 1.6), CFrame.new(math.cos(a) * 3.5, 9.5, math.sin(a) * 3.5), g, GLASS).Transparency = 0.3
	end
	k:Particles(body, {Color = ColorSequence.new(Color3.fromRGB(180, 255, 160)), Rate = 8, Size = NumberSequence.new(0.6, 0), Speed = NumberRange.new(1, 3)})
end

B[2] = function(k) -- Pirate Captain (a hulking walrus pirate)
	local coat, skin = Color3.fromRGB(30, 40, 90), Color3.fromRGB(170, 120, 90)
	k:Part("ball", Vector3.new(9, 10, 7), CFrame.new(0, 6, 0), coat)
	for i = 0, 3 do k:Part("sphere", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 3.5 + i * 1.5, -3.4), GOLD, METAL) end
	k:Part("cyl", Vector3.new(0.8, 9.2, 7.2), CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(90, 50, 25))
	local head = k:Part("ball", Vector3.new(6, 5.5, 5.5), CFrame.new(0, 12.5, -0.5), skin); head.Name = "Head"
	k:Part("ball", Vector3.new(3.5, 2, 2), CFrame.new(0, 11.5, -3), Color3.fromRGB(200, 160, 130))
	for _, s in {-1, 1} do k:Part("block", Vector3.new(0.5, 3, 0.5), CFrame.new(s * 1.2, 9.8, -3.4) * CFrame.Angles(RAD(-10), 0, 0), WHITE) end -- tusks
	eyes(k, CFrame.new(0, 13.4, -3), 1.3, 1.1)
	k:Part("cyl", Vector3.new(0.2, 1.2, 1.2), CFrame.new(1.3, 13.4, -3.4) * CFrame.Angles(0, RAD(90), 0), BLACK)
	k:Part("ball", Vector3.new(9, 2, 6), CFrame.new(0, 15.3, -0.3), BLACK)
	k:Part("ball", Vector3.new(5, 2.8, 4.5), CFrame.new(0, 16.2, 0), BLACK)
	k:Part("sphere", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 16.2, -2.4), WHITE)
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(2.5, 6, 2.5), CFrame.new(s * 5.3, 7, -0.5) * CFrame.Angles(RAD(20), 0, RAD(s * 15)), coat)
	end
	k:Part("block", Vector3.new(0.4, 1.5, 0.4), CFrame.new(6.3, 3.7, -1.8), Color3.fromRGB(190, 190, 200), METAL)
	k:Part("block", Vector3.new(0.4, 0.4, 1.4), CFrame.new(6.3, 3, -2.4), Color3.fromRGB(190, 190, 200), METAL)
	k:Part("block", Vector3.new(0.5, 7, 0.25), CFrame.new(-6.2, 6, -3) * CFrame.Angles(RAD(-30), 0, 0), Color3.fromRGB(210, 210, 220), METAL) -- cutlass
	k:Part("cyl", Vector3.new(3, 1.4, 1.4), CFrame.new(-2, 1.5, 0) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(120, 80, 40)) -- peg
	k:Part("ball", Vector3.new(2.5, 3, 3), CFrame.new(2, 1.5, -0.5), BLACK)
end

B[3] = function(k) -- Ice Titan
	local ice = Color3.fromRGB(160, 220, 255)
	k:Part("block", Vector3.new(9, 8, 6), CFrame.new(0, 10, 0) * CFrame.Angles(0, RAD(8), 0), ice, ICE)
	k:Part("block", Vector3.new(6, 4, 5), CFrame.new(0, 5, 0), Color3.fromRGB(130, 200, 245), ICE)
	local head = k:Part("block", Vector3.new(4.5, 4, 4), CFrame.new(0, 16, -0.5) * CFrame.Angles(0, RAD(-6), 0), ice, ICE); head.Name = "Head"
	for _, s in {-1, 1} do
		k:Part("block", Vector3.new(1, 0.6, 0.3), CFrame.new(s * 1, 16.4, -2.6), Color3.fromRGB(80, 220, 255), NEON)
		k:Part("block", Vector3.new(3, 7, 3), CFrame.new(s * 6.5, 9, 0) * CFrame.Angles(0, 0, RAD(s * 10)), ice, ICE)
		k:Part("block", Vector3.new(4, 4, 4), CFrame.new(s * 7.2, 4.5, -0.5) * CFrame.Angles(RAD(20), RAD(30), 0), Color3.fromRGB(190, 235, 255), ICE)
		k:Part("block", Vector3.new(3, 5, 3), CFrame.new(s * 2.2, 1.5, 0), Color3.fromRGB(130, 200, 245), ICE)
		for i = 1, 3 do
			k:Part("block", Vector3.new(0.9, 3 - i * 0.5, 0.9), CFrame.new(s * (4.5 + i * 0.8), 14 + i * 0.4, i * 0.6 - 1) * CFrame.Angles(RAD(45), RAD(45), RAD(s * -20)), Color3.fromRGB(210, 245, 255), GLASS)
		end
	end
	k:Particles(head, {Color = ColorSequence.new(WHITE), Rate = 20, Size = NumberSequence.new(0.4, 0), Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(180, 180)})
	k:Light(head, Color3.fromRGB(120, 220, 255), 2, 20)
end

B[4] = function(k) -- Fire Dragon
	local red, belly = Color3.fromRGB(200, 40, 25), Color3.fromRGB(255, 190, 70)
	k:Part("ball", Vector3.new(8, 7, 12), CFrame.new(0, 6, 1), red)
	k:Part("ball", Vector3.new(6, 5, 9), CFrame.new(0, 5, 0), belly)
	k:Chain(CFrame.new(0, 8, -3) * CFrame.Angles(RAD(-30), 0, 0), 5, 2.6, 2.0, 1.4, RAD(8), red, SP)
	local head = k:Part("ball", Vector3.new(4, 3.4, 5), CFrame.new(0, 14, -6), red); head.Name = "Head"
	k:Part("ball", Vector3.new(2.8, 2, 3.5), CFrame.new(0, 13.3, -8.5), red)
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(0.8, 0.7, 0.4), CFrame.new(s * 1.2, 15, -8), Color3.fromRGB(255, 230, 50), NEON)
		k:Chain(CFrame.new(s * 1.2, 15.5, -5) * CFrame.Angles(RAD(40), 0, RAD(-s * 15)), 4, 0.8, 0.25, 0.7, RAD(25), Color3.fromRGB(60, 30, 20), SP)
		for i = 0, 3 do
			k:Part("wedge", Vector3.new(0.3, 7 - i * 1.2, 4), CFrame.new(s * (5 + i * 2.6), 11 + i * 0.6, 2) * CFrame.Angles(RAD(10), RAD(s * 90), RAD(180 + s * 10)), Color3.fromRGB(150, 25, 20))
		end
		k:Part("ball", Vector3.new(2.4, 4, 2.4), CFrame.new(s * 3.2, 2, -2), red)
		k:Part("ball", Vector3.new(2.4, 4, 2.4), CFrame.new(s * 3.2, 2, 4), red)
	end
	k:Chain(CFrame.new(0, 5, 7) * CFrame.Angles(RAD(95), 0, 0), 7, 2.2, 0.6, 1.4, RAD(-10), red, SP)
	local mouth = k:Part("ball", Vector3.new(1, 1, 1), CFrame.new(0, 13, -10.3), red); mouth.Transparency = 1; mouth.Name = "Mouth"
	k:Particles(mouth, {Texture = Kit.Textures.Fire, Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 60, 20)), Rate = 25, Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(20, 20), Size = NumberSequence.new(1.2, 0), EmissionDirection = Enum.NormalId.Front})
	k:Light(head, Color3.fromRGB(255, 120, 40), 2, 20)
end

B[5] = function(k) -- Shadow Monster
	local dark, glow = Color3.fromRGB(25, 10, 40), Color3.fromRGB(180, 80, 255)
	k:Part("ball", Vector3.new(8, 13, 7), CFrame.new(0, 8, 0), dark)
	local head = k:Part("ball", Vector3.new(6, 5, 5), CFrame.new(0, 15.5, -0.5), dark); head.Name = "Head"
	for i, off in {Vector3.new(-1.2, 16, -2.7), Vector3.new(1.2, 16, -2.7), Vector3.new(0, 17.3, -2.4), Vector3.new(-2, 14.8, -2.3), Vector3.new(2, 14.8, -2.3)} do
		k:Part("ball", Vector3.new(0.9, 0.9, 0.5) * (i <= 2 and 1.2 or 0.8), CFrame.new(off), glow, NEON)
	end
	k:Part("ball", Vector3.new(3, 0.8, 0.5), CFrame.new(0, 13.8, -2.8), glow, NEON)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		k:Chain(CFrame.new(math.cos(a) * 3, 6 + (i % 3), math.sin(a) * 3) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, RAD(-70)), 6, 1.4, 0.3, 1.1, RAD(18), Color3.fromRGB(40, 15, 60), SP)
	end
	k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(30, 0, 50), glow), Transparency = NumberSequence.new(0.3, 1), Rate = 25, Size = NumberSequence.new(3, 7), Speed = NumberRange.new(1, 3), LightEmission = 0.3})
	k:Light(head, glow, 3, 24)
end

B[6] = function(k) -- Golden Guardian
	local gold, dgold = GOLD, Color3.fromRGB(200, 140, 30)
	k:Part("block", Vector3.new(7, 7, 4.5), CFrame.new(0, 10, 0), gold, METAL)
	k:Part("block", Vector3.new(6, 2, 4), CFrame.new(0, 6, 0), dgold, METAL)
	local head = k:Part("ball", Vector3.new(4, 4.5, 4), CFrame.new(0, 15.5, 0), gold, METAL); head.Name = "Head"
	k:Part("block", Vector3.new(3, 0.5, 0.4), CFrame.new(0, 15.6, -2), Color3.fromRGB(120, 230, 255), NEON)
	k:Part("ball", Vector3.new(0.8, 3, 3.5), CFrame.new(0, 18.2, 0.5), Color3.fromRGB(220, 40, 40))
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(3.5, 2.5, 3.5), CFrame.new(s * 4.5, 13, 0), dgold, METAL)
		k:Part("block", Vector3.new(2, 6, 2), CFrame.new(s * 4.8, 9, 0), gold, METAL)
		k:Part("block", Vector3.new(2.4, 6, 2.4), CFrame.new(s * 1.8, 2.5, 0), dgold, METAL)
	end
	k:Part("cyl", Vector3.new(0.6, 7, 7), CFrame.new(-6.2, 9, -1.5) * CFrame.Angles(0, RAD(10), 0), gold, METAL)
	k:Part("cyl", Vector3.new(0.7, 4, 4), CFrame.new(-6.4, 9, -1.5) * CFrame.Angles(0, RAD(10), 0), Color3.fromRGB(120, 230, 255), NEON)
	k:Part("block", Vector3.new(0.5, 16, 0.5), CFrame.new(6, 10, -1), dgold, METAL)
	k:Part("wedge", Vector3.new(0.3, 2.5, 1.5), CFrame.new(6, 19.2, -1), Color3.fromRGB(120, 230, 255), NEON)
	k:Part("block", Vector3.new(6, 9, 0.3), CFrame.new(0, 8, 2.6) * CFrame.Angles(RAD(10), 0, 0), Color3.fromRGB(200, 30, 40))
	k:Particles(head, {Color = ColorSequence.new(Color3.fromRGB(255, 240, 150)), Rate = 15, Size = NumberSequence.new(0.5, 0)})
	k:Light(head, Color3.fromRGB(255, 220, 120), 2, 20)
end

B[7] = function(k) -- Demon King
	local skin, glow = Color3.fromRGB(150, 15, 25), Color3.fromRGB(255, 120, 20)
	k:Part("ball", Vector3.new(8, 10, 6), CFrame.new(0, 9, 0), skin)
	k:Part("ball", Vector3.new(6, 4, 5), CFrame.new(0, 4, 0), BLACK)
	local head = k:Part("ball", Vector3.new(4.5, 4.5, 4.5), CFrame.new(0, 16, -0.3), skin); head.Name = "Head"
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(1, 0.6, 0.4), CFrame.new(s * 0.9, 16.4, -2.3), glow, NEON)
		k:Chain(CFrame.new(s * 1.6, 17.5, 0) * CFrame.Angles(0, 0, RAD(-s * 40)), 5, 1.2, 0.3, 1, RAD(-20), BLACK, SP)
		k:Part("ball", Vector3.new(2.6, 7, 2.6), CFrame.new(s * 5, 9, -0.5) * CFrame.Angles(RAD(15), 0, RAD(s * 15)), skin)
		k:Part("ball", Vector3.new(2.6, 4.5, 2.6), CFrame.new(s * 2, 1.8, 0), BLACK)
		for i = 0, 3 do
			k:Part("wedge", Vector3.new(0.3, 8 - i * 1.5, 4.5), CFrame.new(s * (5 + i * 3), 13 + i * 0.6, 3) * CFrame.Angles(0, RAD(s * 90), RAD(180)), Color3.fromRGB(50, 0, 10))
		end
	end
	k:Part("cyl", Vector3.new(0.9, 3.5, 3.5), CFrame.new(0, 18.3, -0.3) * CFrame.Angles(0, 0, RAD(90)), GOLD, METAL)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		k:Part("block", Vector3.new(0.4, 1.4, 0.4), CFrame.new(math.cos(a) * 1.6, 19.3, math.sin(a) * 1.6 - 0.3), GOLD, METAL)
	end
	k:Part("block", Vector3.new(7, 11, 0.3), CFrame.new(0, 8, 3.2) * CFrame.Angles(RAD(10), 0, 0), BLACK)
	local f = Instance.new("Fire"); f.Size = 10; f.Heat = 10; f.Color = glow; f.Parent = k.Root
	k:Light(head, glow, 3, 24)
end

B[8] = function(k) -- Cosmic Beast
	local purple, star = Color3.fromRGB(70, 30, 160), Color3.fromRGB(255, 240, 200)
	k:Part("ball", Vector3.new(9, 7, 14), CFrame.new(0, 8, 1), purple)
	local head = k:Part("ball", Vector3.new(6, 5.5, 6), CFrame.new(0, 11, -7), purple); head.Name = "Head"
	k:Part("ball", Vector3.new(4, 2.5, 3.5), CFrame.new(0, 9.6, -9.5), Color3.fromRGB(50, 20, 120))
	for i, x in {-1.6, 0, 1.6} do
		k:Part("ball", Vector3.new(1, 1, 0.5), CFrame.new(x, 12 + (i == 2 and 1 or 0), -9.8), Color3.fromRGB(120, 240, 255), NEON)
	end
	for _, s in {-1, 1} do
		k:Chain(CFrame.new(s * 2, 13, -6.5) * CFrame.Angles(RAD(-20), 0, RAD(-s * 25)), 4, 1.2, 0.3, 1.2, RAD(-15), Color3.fromRGB(255, 220, 120), NEON)
		for _, z in {-3, 5} do k:Part("ball", Vector3.new(2.4, 7, 2.4), CFrame.new(s * 3.5, 3, z), purple) end
	end
	local rng = Random.new(8)
	for _ = 1, 30 do
		k:Part("sphere", Vector3.new(0.25, 0.25, 0.25), CFrame.new(rng:NextNumber(-4, 4), rng:NextNumber(6, 11.5), rng:NextNumber(-5, 7)), star, NEON)
	end
	local hub = k:Hub(CFrame.new(0, 12, 1), 0.6)
	for i, c in {Color3.fromRGB(255, 120, 80), Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 220, 120)} do
		local a = i / 3 * math.pi * 2
		k:Part("sphere", Vector3.new(1.8, 1.8, 1.8), CFrame.new(math.cos(a) * 10, math.sin(a) * 1.5, math.sin(a) * 10), c, NEON, hub)
	end
	k:Particles(k.Root, {Color = ColorSequence.new(star, Color3.fromRGB(255, 120, 220)), Rate = 25, Size = NumberSequence.new(0.6, 0), Speed = NumberRange.new(2, 5)})
	k:Light(head, Color3.fromRGB(160, 120, 255), 3, 24)
end

B[9] = function(k) -- Void Destroyer
	local void, glow = Color3.fromRGB(10, 0, 20), Color3.fromRGB(220, 60, 255)
	local core = k:Part("sphere", Vector3.new(11, 11, 11), CFrame.new(0, 11, 0), void, SP); core.Name = "Head"
	k:Part("ball", Vector3.new(5, 5, 1.5), CFrame.new(0, 11, -5.2), WHITE)
	k:Part("ball", Vector3.new(2.6, 3.4, 1), CFrame.new(0, 11, -5.8), glow, NEON)
	local hub = k:Hub(CFrame.new(0, 11, 0) * CFrame.Angles(RAD(20), 0, 0), 1.2)
	k:Ring(CFrame.new(), 9, 28, 0.8, glow, NEON, hub)
	local hub2 = k:Hub(CFrame.new(0, 11, 0) * CFrame.Angles(RAD(-30), 0, RAD(40)), -0.9)
	k:Ring(CFrame.new(), 10.5, 28, 0.6, Color3.fromRGB(120, 255, 240), NEON, hub2)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		k:Part("block", Vector3.new(1.2, 5, 1.2), CFrame.new(math.cos(a) * 6.5, 11 + math.sin(a) * 6.5, 1) * CFrame.Angles(0, 0, a - math.pi / 2) * CFrame.Angles(0, RAD(45), 0), Color3.fromRGB(60, 0, 90), GLASS)
	end
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		k:Chain(CFrame.new(math.cos(a) * 3, 6, math.sin(a) * 3) * CFrame.Angles(RAD(180), 0, 0) * CFrame.Angles(0, a, RAD(20)), 6, 1.2, 0.3, 0.9, RAD(15), Color3.fromRGB(40, 0, 60), SP)
	end
	k:Particles(core, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(40, 0, 60), glow), Transparency = NumberSequence.new(0.2, 1), Rate = 30, Size = NumberSequence.new(4, 8), LightEmission = 0.4})
	k:Light(core, glow, 4, 30)
end

B[10] = function(k) -- Transcendent Duck King: a giant crowned rubber duck
	local def = {Id = 0, Name = "Transcendent Duck King", Rarity = 10, Body = Color3.fromRGB(255, 225, 80), Accent = Color3.fromRGB(255, 120, 60),
		Material = "M", Accessories = {"crown", "angelWings", "cape", "scepter", "orbitShards", "halo"}, Scale = 1}
	local duck = DuckModelBuilder.Build(def, {Scale = 4.2, NoEffects = true})
	duck:PivotTo(CFrame.new())
	local w = Instance.new("WeldConstraint")
	local droot = duck.PrimaryPart
	droot.Anchored = false
	droot.CFrame = k.Root.CFrame
	w.Part0 = k.Root; w.Part1 = droot; w.Parent = droot
	for _, c in duck:GetChildren() do c.Parent = k.Model end
	droot.Name = "DuckRoot"
	local head = k.Model:FindFirstChild("Head")
	if head then
		k:Light(head, Color3.fromRGB(255, 200, 255), 4, 30)
		k:Particles(head, {Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 120, 255)), Rate = 30, Size = NumberSequence.new(1.2, 0), Speed = NumberRange.new(3, 6)})
	end
	duck:Destroy()
	k.Model:SetAttribute("Rig", "Boss")
end

----------------------------------------------------------------------------
-- Mesh bosses (Blender). Each group folder carries a Joint attribute (model space pivot).
----------------------------------------------------------------------------
local PALETTE = {
	Green = {Color3.fromRGB(110, 255, 100), GLASS, 0.3}, DarkGreen = {Color3.fromRGB(45, 160, 55), SP},
	Navy = {Color3.fromRGB(30, 40, 95), Enum.Material.Fabric}, Gold = {GOLD, METAL}, Silver = {Color3.fromRGB(205, 210, 220), METAL},
	Tan = {Color3.fromRGB(175, 125, 92), SP}, Black = {BLACK, SP}, White = {WHITE, SP}, Bone = {Color3.fromRGB(240, 230, 205), SP},
	Ice = {Color3.fromRGB(165, 225, 255), ICE}, IceDeep = {Color3.fromRGB(95, 170, 235), ICE},
	Red = {Color3.fromRGB(205, 40, 28), SP}, DarkRed = {Color3.fromRGB(110, 18, 14), SP}, Yellow = {Color3.fromRGB(255, 230, 60), NEON},
	Orange = {Color3.fromRGB(255, 140, 40), SP}, Purple = {Color3.fromRGB(45, 18, 70), SP}, Violet = {Color3.fromRGB(190, 90, 255), NEON},
	Crimson = {Color3.fromRGB(150, 15, 25), SP}, Cosmic = {Color3.fromRGB(70, 30, 160), SP}, Cyan = {Color3.fromRGB(120, 240, 255), NEON},
	Pink = {Color3.fromRGB(255, 120, 220), NEON}, Void = {Color3.fromRGB(12, 0, 22), SP}, Glow = {Color3.fromRGB(120, 230, 255), NEON},
}
local GLOW_BY_BOSS = {[3] = Color3.fromRGB(80, 220, 255), [6] = Color3.fromRGB(120, 230, 255), [9] = Color3.fromRGB(220, 60, 255)}
-- which group each group hangs from (default: Root)
local PARENT = {Head = "Torso", ArmL = "Torso", ArmR = "Torso", WingL = "Torso", WingR = "Torso", Jaw = "Head", Face = "Body"}
local BODY_PARENT = {Head = "Body", WingL = "Body", WingR = "Body", Tail = "Body", ArmL = "Body", ArmR = "Body",
	Tendril1 = "Body", Tendril2 = "Body", Tendril3 = "Body", Tendril4 = "Body", Tendril5 = "Body", Tendril6 = "Body"}

local FX = {}
FX[1] = function(k, g) k:Particles(g.Body or k.Root, {Color = ColorSequence.new(Color3.fromRGB(180, 255, 160)), Rate = 8, Size = NumberSequence.new(0.6, 0), Speed = NumberRange.new(1, 3)}) end
FX[3] = function(k, g, head)
	k:Particles(head, {Color = ColorSequence.new(WHITE), Rate = 20, Size = NumberSequence.new(0.4, 0), Speed = NumberRange.new(1, 4)})
	k:Light(head, Color3.fromRGB(120, 220, 255), 2, 20)
end
FX[4] = function(k, g, head, def, folder)
	local mp = folder:GetAttribute("Mouth") or Vector3.new(0, 12, -10)
	local mouth = k:Part("block", Vector3.new(1, 1, 1), CFrame.new(mp), Color3.new(1, 0.4, 0.1))
	mouth.Transparency = 1; mouth.Name = "Mouth"
	mouth:FindFirstChildOfClass("WeldConstraint").Part0 = g.Jaw or head
	local pe = k:Particles(mouth, {Texture = Kit.Textures.Fire, Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 60, 20)), Rate = 18, Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(20, 20), Size = NumberSequence.new(1.2, 0), EmissionDirection = Enum.NormalId.Front})
	pe.Name = "Breath"
	k:Light(head, Color3.fromRGB(255, 120, 40), 2, 20)
end
FX[5] = function(k, g, head)
	k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(30, 0, 50), Color3.fromRGB(180, 80, 255)), Transparency = NumberSequence.new(0.3, 1), Rate = 22, Size = NumberSequence.new(3, 7), Speed = NumberRange.new(1, 3), LightEmission = 0.3})
	k:Light(head, Color3.fromRGB(180, 80, 255), 3, 24)
end
FX[6] = function(k, g, head)
	k:Particles(head, {Color = ColorSequence.new(Color3.fromRGB(255, 240, 150)), Rate = 15, Size = NumberSequence.new(0.5, 0)})
	k:Light(head, Color3.fromRGB(255, 220, 120), 2, 20)
end
FX[7] = function(k, g, head)
	local f = Instance.new("Fire"); f.Size = 10; f.Heat = 10; f.Color = Color3.fromRGB(255, 120, 20); f.Parent = g.Torso or k.Root
	k:Light(head, Color3.fromRGB(255, 120, 20), 3, 24)
end
FX[8] = function(k, g, head)
	local hub = k:Hub(CFrame.new(0, 12, 1), 0.6)
	for i, c in {Color3.fromRGB(255, 120, 80), Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 220, 120)} do
		local a = i / 3 * math.pi * 2
		k:Part("sphere", Vector3.new(1.8, 1.8, 1.8), CFrame.new(math.cos(a) * 10, math.sin(a) * 1.5, math.sin(a) * 10), c, NEON, hub)
	end
	k:Particles(k.Root, {Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 120, 220)), Rate = 25, Size = NumberSequence.new(0.6, 0), Speed = NumberRange.new(2, 5)})
	k:Light(head, Color3.fromRGB(160, 120, 255), 3, 24)
end
FX[9] = function(k, g, head)
	k:Particles(head, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(40, 0, 60), Color3.fromRGB(220, 60, 255)), Transparency = NumberSequence.new(0.2, 1), Rate = 26, Size = NumberSequence.new(4, 8), LightEmission = 0.4})
	k:Light(head, Color3.fromRGB(220, 60, 255), 4, 30)
end

local function buildMesh(k, id, def)
	local ok, M = pcall(Kit.Meshes)
	local folder = ok and M and M:FindFirstChild("Boss_" .. id)
	if not folder then return false end
	local groups = {}
	local order = {}
	for _, g in folder:GetChildren() do table.insert(order, g) end
	-- parents first
	local function depth(name)
		local d, n = 0, name
		while true do
			local p = PARENT[n] or BODY_PARENT[n]
			if not p or not folder:FindFirstChild(p) then break end
			n = p; d += 1
		end
		return d
	end
	table.sort(order, function(a, b) return depth(a.Name) < depth(b.Name) end)
	local head
	for _, g in order do
		local pname = PARENT[g.Name]
		if not (pname and groups[pname]) then pname = BODY_PARENT[g.Name] end
		local parentJoint = pname and groups[pname] or nil
		local j = k:Joint("J_" .. g.Name, CFrame.new(g:GetAttribute("Joint") or Vector3.zero), parentJoint)
		groups[g.Name] = j
		for _, src in g:GetChildren() do
			local slot = src:GetAttribute("Slot")
			local st = PALETTE[slot] or {WHITE, SP}
			local color, mat = st[1], st[2]
			if slot == "Glow" and GLOW_BY_BOSS[id] then color = GLOW_BY_BOSS[id] end
			if (src.Name:find("eyes") or src.Name:find("visor")) and slot ~= "White" and slot ~= "Black" then mat = NEON end
			local p = k:Mesh(src, color, mat, j)
			if st[3] then p.Transparency = st[3] end
			if g.Name == "Head" and (src.Name:find("^head") or src.Name:find("^skull") or src.Name:find("^helm")) and not head then
				head = p
			end
		end
	end
	-- focus part used by the battle camera / effects
	local focusParent = groups.Head or groups.Core or groups.Face or groups.Body
	if not head then
		for _, c in k.Model:GetChildren() do
			local w = c:FindFirstChildOfClass("WeldConstraint")
			if w and w.Part0 == focusParent and c:IsA("MeshPart") then head = c break end
		end
	end
	if head then head.Name = "Head" end
	if FX[id] then FX[id](k, groups, head or k.Root, def, folder) end
	k.Model:SetAttribute("Rig", "Boss")
	return true
end

function B.Build(bossDef)
	local k = Kit.new(bossDef.Name)
	local fn = B[bossDef.Id]
	if not buildMesh(k, bossDef.Id, bossDef) and fn then fn(k) end
	if not k.Model:FindFirstChild("Head") then
		local h = k:Part("block", Vector3.new(1, 1, 1), CFrame.new(0, 12, 0), WHITE); h.Name = "Head"; h.Transparency = 1
	end
	k.Model:SetAttribute("BossId", bossDef.Id)
	return k.Model
end

return B
