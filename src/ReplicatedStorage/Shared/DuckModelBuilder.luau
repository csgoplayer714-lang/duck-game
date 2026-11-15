-- Builds a procedural 3D rubber duck from a DuckData entry.
-- Duck faces -Z. Root sits at the waterline (body bottom ~ y=0).
local Kit = require(script.Parent.ModelKit)
local Rarity = require(script.Parent.Rarity)

local Builder = {}

local SP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Foil
local GLASS = Enum.Material.Glass
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(20, 20, 25)
local GOLD = Color3.fromRGB(255, 200, 50)
local SILVER = Color3.fromRGB(200, 205, 215)
local BROWN = Color3.fromRGB(110, 70, 40)
local RAD = math.rad

local HEAD = CFrame.new(0, 2.35, -0.85)
local HEADTOP = CFrame.new(0, 3.12, -0.85)
local FACE = CFrame.new(0, 2.45, -1.62)
local NECK = CFrame.new(0, 1.72, -0.8)
local BACK = CFrame.new(0, 1.7, 1.0)
local SIDE_R = CFrame.new(1.3, 1.2, -0.1)
local SIDE_L = CFrame.new(-1.3, 1.2, -0.1)

-- Each accessory: function(k: Kit, d: duck, accent, body)
local A = {}

function A.partyHat(k, d, ac)
	k:Cone(HEADTOP * CFrame.new(0.1, -0.15, 0) * CFrame.Angles(0, 0, RAD(-12)), 1.4, 0.5, ac, SP, 5)
	k:Part("sphere", Vector3.new(0.3, 0.3, 0.3), HEADTOP * CFrame.new(-0.2, 1.25, 0), WHITE)
end
function A.balloon(k, d, ac)
	k:Part("block", Vector3.new(0.04, 3, 0.04), CFrame.new(1.35, 2.7, 0.2), WHITE)
	k:Part("ball", Vector3.new(1.4, 1.7, 1.4), CFrame.new(1.35, 4.9, 0.2), ac, SP).Reflectance = 0.15
	k:Part("ball", Vector3.new(0.25, 0.2, 0.25), CFrame.new(1.35, 4.05, 0.2), ac)
end
function A.popcorn(k, d, ac)
	k:Part("cyl", Vector3.new(0.9, 1.1, 1.1), HEADTOP * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
	k:Part("cyl", Vector3.new(0.92, 1.02, 0.5), HEADTOP * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, RAD(90)), WHITE)
	for i = 1, 6 do
		local a = i * 1.05
		k:Part("ball", Vector3.new(0.4, 0.35, 0.4), HEADTOP * CFrame.new(math.cos(a) * 0.3, 0.85 + (i % 2) * 0.12, math.sin(a) * 0.3), Color3.fromRGB(255, 245, 200))
	end
end
function A.clownNose(k, d, ac)
	k:Part("sphere", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 2.25, -2.05), Color3.fromRGB(255, 30, 30)).Reflectance = 0.2
end
function A.afro(k, d, ac)
	local cols = {ac, Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 255, 120), Color3.fromRGB(255, 230, 60)}
	for i = 1, 7 do
		local a = i * 0.9
		k:Part("ball", Vector3.new(0.75, 0.75, 0.75), HEAD * CFrame.new(math.cos(a) * 0.65, 0.55 + (i % 3) * 0.15, math.sin(a) * 0.55 + 0.25), cols[i % 4 + 1])
	end
end
function A.tophat(k, d, ac)
	k:Part("cyl", Vector3.new(0.12, 1.7, 1.7), HEADTOP * CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, RAD(90)), BLACK)
	k:Part("cyl", Vector3.new(1.1, 1.1, 1.1), HEADTOP * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, RAD(90)), BLACK)
	k:Part("cyl", Vector3.new(0.22, 1.13, 1.13), HEADTOP * CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
end
function A.cape(k, d, ac)
	k:Part("block", Vector3.new(2.4, 2.2, 0.1), CFrame.new(0, 1.4, 1.55) * CFrame.Angles(RAD(18), 0, 0), ac)
	k:Part("cyl", Vector3.new(0.2, 1.7, 1.7), NECK * CFrame.Angles(0, 0, RAD(90)), Kit.Darken(ac, 0.7))
end
function A.orbitBalls(k, d, ac, body)
	local hub = k:Hub(CFrame.new(0, 4.0, -0.4), 2.5)
	k:Ring(CFrame.new(), 0.9, 3, 0.45, {ac, Kit.Lighten(body, 0.4), WHITE}, SP, hub)
end
function A.jesterHat(k, d, ac, body)
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(0.5, 1.4, 0.5), HEADTOP * CFrame.new(s * 0.5, 0.3, 0) * CFrame.Angles(0, 0, RAD(-s * 45)), if s > 0 then ac else body)
		k:Part("sphere", Vector3.new(0.28, 0.28, 0.28), HEADTOP * CFrame.new(s * 1.0, 0.75, 0), GOLD, METAL)
	end
end
function A.visor(k, d, ac)
	k:Part("cyl", Vector3.new(0.25, 1.85, 1.85), HEAD * CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
	k:Part("ball", Vector3.new(1.4, 0.12, 0.9), HEAD * CFrame.new(0, 0.42, -0.95), ac)
end
function A.cloudHat(k, d, ac)
	for i = 1, 5 do
		k:Part("ball", Vector3.new(0.8, 0.65, 0.8), HEADTOP * CFrame.new((i - 3) * 0.35, 0.1 + (i % 2) * 0.2, (i % 2) * 0.2), Kit.Lighten(ac, 0.3))
	end
end
function A.pirateHat(k, d, ac)
	k:Part("ball", Vector3.new(2.2, 0.55, 1.6), HEADTOP * CFrame.new(0, 0.05, 0), BLACK)
	k:Part("ball", Vector3.new(1.3, 0.8, 1.1), HEADTOP * CFrame.new(0, 0.35, 0.05), BLACK)
	k:Part("block", Vector3.new(1.8, 0.5, 0.12), HEADTOP * CFrame.new(0, 0.3, -0.62) * CFrame.Angles(RAD(-20), 0, 0), BLACK)
	k:Part("sphere", Vector3.new(0.3, 0.3, 0.3), HEADTOP * CFrame.new(0, 0.35, -0.7), WHITE)
	k:Part("block", Vector3.new(1.85, 0.06, 0.14), HEADTOP * CFrame.new(0, 0.55, -0.66) * CFrame.Angles(RAD(-20), 0, 0), GOLD, METAL)
end
function A.eyepatch(k)
	k:Part("cyl", Vector3.new(0.08, 0.5, 0.5), CFrame.new(0.43, 2.62, -1.7) * CFrame.Angles(0, RAD(90), 0), BLACK)
	k:Part("cyl", Vector3.new(0.08, 1.78, 1.78), HEAD * CFrame.new(0, 0.28, 0) * CFrame.Angles(RAD(-15), 0, RAD(80)), BLACK)
end
function A.sword(k, d, ac)
	local base = SIDE_R * CFrame.new(0.25, 0.2, -0.3) * CFrame.Angles(RAD(-60), 0, RAD(-10))
	k:Part("block", Vector3.new(0.12, 0.6, 0.12), base, BROWN)
	k:Part("block", Vector3.new(0.18, 0.12, 0.7), base * CFrame.new(0, 0.35, 0), GOLD, METAL)
	k:Part("block", Vector3.new(0.08, 2.2, 0.3), base * CFrame.new(0, 1.5, 0), SILVER, METAL)
	k:Part("wedge", Vector3.new(0.08, 0.35, 0.3), base * CFrame.new(0, 2.77, 0), SILVER, METAL)
end
function A.ninjaMask(k, d, ac)
	k:Part("cyl", Vector3.new(0.35, 1.78, 1.78), HEAD * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
	k:Part("block", Vector3.new(0.1, 0.25, 0.9), HEAD * CFrame.new(0.15, 0.2, 1.1) * CFrame.Angles(RAD(-30), RAD(15), 0), ac)
	k:Part("block", Vector3.new(0.1, 0.25, 0.9), HEAD * CFrame.new(-0.15, 0.1, 1.1) * CFrame.Angles(RAD(-40), RAD(-15), 0), ac)
end
function A.katana(k, d, ac)
	local base = BACK * CFrame.new(0, 0.3, 0.3) * CFrame.Angles(0, 0, RAD(40))
	k:Part("block", Vector3.new(0.15, 3.2, 0.06), base, SILVER, METAL)
	k:Part("block", Vector3.new(0.18, 0.9, 0.12), base * CFrame.new(0, -2.0, 0), BLACK)
	k:Part("cyl", Vector3.new(0.08, 0.45, 0.45), base * CFrame.new(0, -1.55, 0) * CFrame.Angles(0, 0, RAD(90)), GOLD, METAL)
end
function A.wand(k, d, ac)
	local base = SIDE_R * CFrame.new(0.3, 0.5, -0.4) * CFrame.Angles(RAD(-40), 0, RAD(-15))
	k:Part("block", Vector3.new(0.12, 1.6, 0.12), base, BLACK)
	local tip = k:Part("block", Vector3.new(0.14, 0.3, 0.14), base * CFrame.new(0, 0.9, 0), WHITE, NEON)
	k:Particles(tip, {Color = ColorSequence.new(GOLD), Rate = 8, Size = NumberSequence.new(0.2, 0)})
end
function A.sparkle(k, d, ac)
	k:Particles(k.Root, {Color = ColorSequence.new(Kit.Lighten(ac, 0.5)), Rate = 10, Speed = NumberRange.new(0.3, 1), Size = NumberSequence.new(0.35, 0)})
end
function A.armor(k, d, ac)
	k:Part("ball", Vector3.new(2.3, 1.9, 1.5), CFrame.new(0, 1.2, -0.62), SILVER, METAL)
	k:Part("cyl", Vector3.new(0.15, 2.1, 2.1), CFrame.new(0, 1.7, -0.62) * CFrame.Angles(0, 0, RAD(90)), ac, METAL)
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(0.9, 0.7, 1.1), CFrame.new(s * 1.15, 1.75, -0.1), SILVER, METAL)
		k:Part("sphere", Vector3.new(0.25, 0.25, 0.25), CFrame.new(s * 1.35, 2.0, -0.1), ac, NEON)
	end
end
function A.helmet(k, d, ac)
	k:Part("ball", Vector3.new(1.9, 1.3, 1.9), HEAD * CFrame.new(0, 0.42, 0.05), SILVER, METAL)
	k:Part("block", Vector3.new(1.95, 0.12, 0.2), HEAD * CFrame.new(0, 0.2, -0.85), Kit.Darken(SILVER, 0.7), METAL)
	k:Part("ball", Vector3.new(0.3, 0.9, 1.3), HEADTOP * CFrame.new(0, 0.3, 0.2), ac)
end
function A.lance(k, d, ac)
	local base = SIDE_R * CFrame.new(0.2, 0, 0) * CFrame.Angles(RAD(-80), 0, 0)
	k:Cone(base, 4.5, 0.35, SILVER, METAL, 6)
	k:Part("cyl", Vector3.new(0.2, 0.9, 0.9), base * CFrame.Angles(0, 0, RAD(90)), ac, METAL)
end
function A.crown(k, d, ac)
	k:Part("cyl", Vector3.new(0.4, 1.2, 1.2), HEADTOP * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, RAD(90)), GOLD, METAL)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k:Part("block", Vector3.new(0.2, 0.45, 0.2), HEADTOP * CFrame.new(math.cos(a) * 0.52, 0.4, math.sin(a) * 0.52) * CFrame.Angles(0, -a, RAD(45)), GOLD, METAL)
		k:Part("sphere", Vector3.new(0.16, 0.16, 0.16), HEADTOP * CFrame.new(math.cos(a) * 0.6, 0.05, math.sin(a) * 0.6), if i % 2 == 0 then ac else Color3.fromRGB(255, 50, 80), NEON)
	end
end
function A.scepter(k, d, ac)
	local base = SIDE_L * CFrame.new(-0.3, 0.3, -0.3) * CFrame.Angles(RAD(-20), 0, RAD(15))
	k:Part("block", Vector3.new(0.15, 2.4, 0.15), base, GOLD, METAL)
	k:Part("sphere", Vector3.new(0.45, 0.45, 0.45), base * CFrame.new(0, 1.35, 0), ac, NEON)
end
function A.tiara(k, d, ac)
	for i = -3, 3 do
		local a = i * 0.32
		k:Part("sphere", Vector3.new(0.2, 0.2, 0.2) * (if i == 0 then 1.6 else 1), HEAD * CFrame.new(math.sin(a) * 0.75, 0.62 + (3 - math.abs(i)) * 0.04, -math.cos(a) * 0.55), if i == 0 then ac else WHITE, if i == 0 then NEON else GLASS)
	end
end
function A.coinOrbit(k)
	local hub = k:Hub(CFrame.new(0, 1.4, 0), 1.8)
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2
		k:Part("cyl", Vector3.new(0.12, 0.6, 0.6), CFrame.new(math.cos(a) * 2.1, 0, math.sin(a) * 2.1) * CFrame.Angles(0, -a, 0), GOLD, METAL, hub)
	end
end
function A.halo(k, d, ac)
	local hub = k:Hub(HEADTOP * CFrame.new(0, 0.75, 0.1), 1.2)
	k:Ring(CFrame.new(), 0.7, 12, 0.22, Color3.fromRGB(255, 240, 140), NEON, hub)
	k:Light(hub, Color3.fromRGB(255, 240, 160), 1, 6)
end
local function wings(k, color, mat, flame)
	for _, s in {-1, 1} do
		local base = BACK * CFrame.new(s * 0.7, 0.4, -0.1) * CFrame.Angles(RAD(-10), RAD(s * 20), RAD(-s * 35))
		for i = 1, 3 do
			local p = k:Part("ball", Vector3.new(0.2, 2.6 - i * 0.45, 1.1), base * CFrame.new(s * 0.2 * i, 0.9 + i * 0.15, i * 0.25) * CFrame.Angles(0, 0, RAD(-s * i * 12)), if i == 2 then Kit.Lighten(color, 0.25) else color, mat)
			if flame and i == 1 then
				k:Particles(p, {Texture = Kit.Textures.Fire, Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 20)), Rate = 15, Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(15, 15), Acceleration = Vector3.new(0, 3, 0), Size = NumberSequence.new(0.6, 0)})
			end
		end
	end
end
function A.angelWings(k) wings(k, Color3.fromRGB(255, 255, 250), SP) end
function A.wings(k, d, ac) wings(k, ac, SP) end
function A.wingsFire(k) wings(k, Color3.fromRGB(255, 140, 30), NEON, true) end
function A.batWings(k, d, ac)
	for _, s in {-1, 1} do
		local base = BACK * CFrame.new(s * 0.9, 0.5, 0) * CFrame.Angles(0, RAD(s * 15), RAD(-s * 25))
		k:Part("block", Vector3.new(0.12, 0.12, 0.12) + Vector3.new(0, 2.0, 0), base * CFrame.new(s * 0.4, 0.9, 0), BLACK)
		for i = 0, 2 do
			k:Part("wedge", Vector3.new(0.08, 1.4 - i * 0.3, 0.9), base * CFrame.new(s * (0.6 + i * 0.5), 0.6 - i * 0.2, 0) * CFrame.Angles(0, RAD(s * 90), RAD(180)), Kit.Darken(ac, 0.45))
		end
	end
end
function A.orbitRings(k, d, ac)
	local hub = k:Hub(CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(18), 0, RAD(10)), 1.5)
	k:Ring(CFrame.new(), 2.2, 18, 0.22, ac, NEON, hub)
	local hub2 = k:Hub(CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(-25), 0, RAD(-20)), -1.1)
	k:Ring(CFrame.new(), 2.5, 18, 0.16, Kit.Lighten(ac, 0.5), NEON, hub2)
end
function A.glitch(k, d, ac, body)
	local rng = Random.new(#d.Name)
	for i = 1, 7 do
		local s = rng:NextNumber(0.2, 0.55)
		k:Part("block", Vector3.new(s, s, s), CFrame.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0.6, 3.4), rng:NextNumber(-1.6, 1.6)), if i % 2 == 0 then ac else body, NEON).Transparency = 0.2
	end
	k:Particles(k.Root, {Texture = "", Color = ColorSequence.new(ac, body), Rate = 14, Size = NumberSequence.new(0.18, 0.18), Lifetime = NumberRange.new(0.15, 0.4), Speed = NumberRange.new(3, 6), LightEmission = 1})
end
function A.staff(k, d, ac)
	local base = SIDE_L * CFrame.new(-0.4, 0.6, -0.4) * CFrame.Angles(RAD(-10), 0, RAD(8))
	k:Part("block", Vector3.new(0.18, 3.6, 0.18), base, Kit.Darken(ac, 0.5), METAL)
	local orb = k:Part("sphere", Vector3.new(0.65, 0.65, 0.65), base * CFrame.new(0, 2.05, 0), ac, NEON)
	k:Ring(base * CFrame.new(0, 2.05, 0), 0.42, 4, 0.18, GOLD, METAL)
	k:Light(orb, ac, 1.5, 8)
end
function A.orbitShards(k, d, ac)
	local hub = k:Hub(CFrame.new(0, 2.0, 0), 1.0)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		k:Part("block", Vector3.new(0.35, 0.9, 0.35), CFrame.new(math.cos(a) * 2.6, math.sin(a * 2) * 0.4, math.sin(a) * 2.6) * CFrame.Angles(RAD(45), a, RAD(45)), if i % 2 == 0 then ac else WHITE, NEON, hub)
	end
end
function A.sunglasses(k)
	for _, s in {-1, 1} do
		k:Part("cyl", Vector3.new(0.08, 0.5, 0.6), CFrame.new(s * 0.42, 2.6, -1.78) * CFrame.Angles(0, RAD(90 + s * 15), 0), BLACK).Reflectance = 0.4
	end
	k:Part("block", Vector3.new(0.4, 0.07, 0.07), CFrame.new(0, 2.65, -1.86), BLACK)
end
function A.surfboard(k, d, ac)
	local base = BACK * CFrame.new(0, 0.6, 0.5) * CFrame.Angles(RAD(-15), 0, RAD(25))
	k:Part("ball", Vector3.new(0.9, 3.6, 0.18), base, ac)
	k:Part("ball", Vector3.new(0.2, 3.3, 0.2), base, WHITE)
end
function A.lei(k, d, ac)
	k:Ring(NECK * CFrame.new(0, -0.05, 0) * CFrame.Angles(RAD(-12), 0, 0), 0.92, 12, 0.32, {ac, Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 240, 120)}, SP)
end
function A.flower(k, d, ac)
	local c = HEAD * CFrame.new(0.65, 0.55, -0.1) * CFrame.Angles(0, 0, RAD(-30))
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k:Part("ball", Vector3.new(0.3, 0.12, 0.3), c * CFrame.new(math.cos(a) * 0.22, 0, math.sin(a) * 0.22), Color3.fromRGB(255, 120, 190))
	end
	k:Part("sphere", Vector3.new(0.18, 0.18, 0.18), c * CFrame.new(0, 0.05, 0), Color3.fromRGB(255, 230, 60))
end
function A.skirt(k)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		k:Part("block", Vector3.new(0.18, 0.9, 0.05), CFrame.new(math.cos(a) * 1.25, 0.55, math.sin(a) * 1.45 + 0.2) * CFrame.Angles(0, -a + math.pi / 2, RAD(8)), Color3.fromRGB(120, 200, 80))
	end
end
function A.goggles(k, d, ac)
	k:Part("cyl", Vector3.new(0.2, 1.8, 1.8), HEAD * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, RAD(90)), BLACK)
	for _, s in {-1, 1} do
		k:Part("cyl", Vector3.new(0.25, 0.55, 0.55), HEAD * CFrame.new(s * 0.33, 0.48, -0.78) * CFrame.Angles(0, RAD(90), 0), ac, GLASS)
	end
end
function A.crest(k, d, ac)
	for i = -1, 1 do
		k:Part("ball", Vector3.new(0.25, 1.3, 0.45), HEADTOP * CFrame.new(i * 0.2, 0.4, 0.2) * CFrame.Angles(RAD(-30), 0, RAD(i * 20)), if i == 0 then ac else Kit.Lighten(ac, 0.3))
	end
end
function A.tikiMask(k, d, ac)
	k:Part("block", Vector3.new(1.3, 1.4, 0.2), FACE * CFrame.new(0, 0.05, -0.1), BROWN)
	for _, s in {-1, 1} do k:Part("block", Vector3.new(0.3, 0.2, 0.1), FACE * CFrame.new(s * 0.3, 0.2, -0.22), ac, NEON) end
	k:Part("block", Vector3.new(0.7, 0.15, 0.1), FACE * CFrame.new(0, -0.35, -0.22), ac)
	k:Part("block", Vector3.new(1.5, 0.4, 0.15), FACE * CFrame.new(0, 0.8, -0.05), ac)
end
function A.leafCrown(k)
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2
		k:Part("ball", Vector3.new(0.3, 1.1, 0.12), HEADTOP * CFrame.new(math.cos(a) * 0.2, 0.4, math.sin(a) * 0.2) * CFrame.Angles(0, -a, RAD(30)), Color3.fromRGB(70, 180, 60))
	end
end
function A.shellHat(k, d, ac)
	k:Part("ball", Vector3.new(1.3, 0.7, 1.2), HEADTOP * CFrame.new(0, 0.05, 0), ac)
	for i = -2, 2 do k:Part("block", Vector3.new(0.08, 0.5, 1.0), HEADTOP * CFrame.new(i * 0.22, 0.2, 0) * CFrame.Angles(0, 0, RAD(i * 15)), Kit.Darken(ac, 0.85)) end
end
function A.gasAura(k, d, ac)
	k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(140, 255, 60)), Transparency = NumberSequence.new(0.5, 1), Rate = 8, Size = NumberSequence.new(1, 2.5), Speed = NumberRange.new(0.3, 0.8), LightEmission = 0.3})
end
function A.rangerHat(k)
	local kh = Color3.fromRGB(190, 160, 100)
	k:Part("cyl", Vector3.new(0.1, 2.3, 2.3), HEADTOP * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, RAD(90)), kh)
	k:Part("ball", Vector3.new(1.2, 0.8, 1.2), HEADTOP * CFrame.new(0, 0.2, 0), kh)
end
function A.spear(k, d, ac)
	local base = SIDE_R * CFrame.new(0.3, 0.3, -0.2) * CFrame.Angles(RAD(-15), 0, RAD(-10))
	k:Part("block", Vector3.new(0.14, 4, 0.14), base, BROWN)
	k:Part("wedge", Vector3.new(0.1, 0.6, 0.35), base * CFrame.new(0, 2.3, 0), SILVER, METAL)
	k:Part("wedge", Vector3.new(0.1, 0.6, 0.35), base * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, RAD(180), 0), SILVER, METAL)
end
function A.fireAura(k)
	local f = Instance.new("Fire")
	f.Size = 4; f.Heat = 6; f.Color = Color3.fromRGB(255, 120, 30); f.SecondaryColor = Color3.fromRGB(255, 220, 60)
	f.Parent = k.Root
	k:Light(k.Root, Color3.fromRGB(255, 140, 50), 1.5, 9)
end
function A.finHelmet(k, d, ac)
	A.helmet(k, d, ac)
	k:Part("wedge", Vector3.new(0.15, 1.0, 1.2), HEADTOP * CFrame.new(0, 0.6, 0.3), Color3.fromRGB(110, 140, 165))
end
function A.trident(k, d, ac)
	local base = SIDE_R * CFrame.new(0.4, 0.5, -0.2) * CFrame.Angles(RAD(-8), 0, RAD(-8))
	k:Part("block", Vector3.new(0.15, 4, 0.15), base, GOLD, METAL)
	k:Part("block", Vector3.new(0.9, 0.15, 0.15), base * CFrame.new(0, 2.0, 0), GOLD, METAL)
	for i = -1, 1 do k:Part("block", Vector3.new(0.12, 0.8, 0.12), base * CFrame.new(i * 0.4, 2.45 + (i == 0 and 0.15 or 0), 0), GOLD, METAL) end
end
function A.sunHalo(k, d, ac)
	local hub = k:Hub(HEAD * CFrame.new(0, 0.2, 0.9) * CFrame.Angles(RAD(90), 0, 0), 0.8)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		k:Part("block", Vector3.new(0.2, 0.7, 0.1), CFrame.new(math.cos(a) * 1.4, 0, math.sin(a) * 1.4) * CFrame.Angles(0, -a, RAD(90)), Color3.fromRGB(255, 200, 40), NEON, hub)
	end
	k:Light(hub, Color3.fromRGB(255, 210, 90), 2, 10)
end
function A.waveAura(k, d, ac)
	k:Particles(k.Root, {Color = ColorSequence.new(Color3.fromRGB(120, 220, 255)), Rate = 16, Acceleration = Vector3.new(0, 2, 0), Speed = NumberRange.new(0.5, 1.5), Size = NumberSequence.new(0.4, 0)})
	k:Ring(CFrame.new(0, 0.15, 0), 1.9, 14, 0.4, Color3.fromRGB(150, 230, 255), GLASS)
end
function A.horns(k, d, ac)
	for _, s in {-1, 1} do
		k:Chain(HEAD * CFrame.new(s * 0.45, 0.6, 0.15) * CFrame.Angles(RAD(-10), 0, RAD(-s * 25)), 4, 0.35, 0.12, 0.28, RAD(-22), Kit.Darken(ac, 0.8), SP)
	end
end
function A.crystalSpikes(k, d, ac)
	for i = 1, 5 do
		local s = 1.2 - math.abs(i - 3) * 0.25
		k:Part("block", Vector3.new(0.35, s, 0.35), BACK * CFrame.new(0, 0.2 + s * 0.3, (i - 3) * 0.4 - 0.4) * CFrame.Angles(RAD(-20 + i * 4), RAD(45), 0), ac, GLASS)
	end
end
function A.rainbow(k)
	local cols = {Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 240, 70), Color3.fromRGB(90, 230, 90), Color3.fromRGB(70, 170, 255), Color3.fromRGB(160, 90, 255)}
	for ci, c in cols do
		local r = 2.0 + ci * 0.22
		for i = 0, 8 do
			local a = math.pi * i / 8
			k:Part("sphere", Vector3.new(0.24, 0.24, 0.24), CFrame.new(math.cos(a) * r, 1.2 + math.sin(a) * r, 1.2), c, NEON)
		end
	end
end
function A.earmuffs(k, d, ac)
	k:Part("cyl", Vector3.new(0.12, 2.0, 2.0), HEAD * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, RAD(90), 0) * CFrame.Angles(0, 0, 0), ac)
	for _, s in {-1, 1} do k:Part("ball", Vector3.new(0.5, 0.75, 0.75), HEAD * CFrame.new(s * 0.88, 0, 0), Kit.Lighten(ac, 0.4)) end
end
function A.scarf(k, d, ac)
	k:Part("cyl", Vector3.new(0.45, 1.85, 1.85), NECK * CFrame.Angles(0, 0, RAD(90)), ac)
	k:Part("block", Vector3.new(0.4, 1.0, 0.15), NECK * CFrame.new(0.5, -0.4, -0.75) * CFrame.Angles(RAD(10), 0, RAD(10)), ac)
end
function A.beanie(k, d, ac)
	k:Part("ball", Vector3.new(1.8, 1.2, 1.8), HEAD * CFrame.new(0, 0.45, 0.05), ac)
	k:Part("cyl", Vector3.new(0.3, 1.86, 1.86), HEAD * CFrame.new(0, 0.3, 0.05) * CFrame.Angles(0, 0, RAD(90)), Kit.Lighten(ac, 0.5))
	k:Part("sphere", Vector3.new(0.45, 0.45, 0.45), HEADTOP * CFrame.new(0, 0.25, 0), WHITE)
end
function A.iceAura(k)
	k:Particles(k.Root, {Color = ColorSequence.new(Color3.fromRGB(200, 245, 255)), Rate = 14, Speed = NumberRange.new(0.3, 1), Size = NumberSequence.new(0.3, 0)})
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		k:Part("block", Vector3.new(0.3, 0.9, 0.3), CFrame.new(math.cos(a) * 1.9, 0.3, math.sin(a) * 1.9) * CFrame.Angles(RAD(20), a, RAD(45)), Color3.fromRGB(190, 240, 255), Enum.Material.Ice)
	end
	k:Light(k.Root, Color3.fromRGB(160, 230, 255), 1, 8)
end
function A.bowtie(k)
	for _, s in {-1, 1} do k:Part("ball", Vector3.new(0.45, 0.35, 0.2), NECK * CFrame.new(s * 0.22, 0, -0.85) * CFrame.Angles(0, 0, RAD(s * 20)), Color3.fromRGB(220, 30, 40)) end
	k:Part("sphere", Vector3.new(0.18, 0.18, 0.18), NECK * CFrame.new(0, 0, -0.9), Color3.fromRGB(180, 20, 30))
end
function A.furCollar(k)
	k:Ring(NECK, 0.9, 14, 0.5, WHITE, SP)
end
function A.bow(k, d, ac)
	local base = BACK * CFrame.new(0, 0.4, 0.4) * CFrame.Angles(0, RAD(90), RAD(30))
	for i = -4, 4 do
		local a = i * 0.18
		k:Part("ball", Vector3.new(0.18, 0.4, 0.18), base * CFrame.new(math.cos(a) * 1.5 - 1.5, math.sin(a) * 1.5, 0), BROWN)
	end
	k:Part("block", Vector3.new(0.03, 2.4, 0.03), base * CFrame.new(-0.12, 0, 0), WHITE)
end
function A.hood(k, d, ac)
	k:Part("ball", Vector3.new(2.0, 2.0, 2.0), HEAD * CFrame.new(0, 0.15, 0.25), Kit.Darken(ac, 0.35))
	k:Part("ball", Vector3.new(2.6, 1.6, 2.6), CFrame.new(0, 1.3, 0.3), Kit.Darken(ac, 0.3))
end
function A.hammer(k, d, ac)
	local base = SIDE_R * CFrame.new(0.3, 0.4, -0.2) * CFrame.Angles(RAD(-25), 0, RAD(-10))
	k:Part("block", Vector3.new(0.2, 2.6, 0.2), base, BROWN)
	k:Part("block", Vector3.new(1.2, 0.7, 0.7), base * CFrame.new(0, 1.4, 0), SILVER, METAL)
	k:Part("block", Vector3.new(1.25, 0.15, 0.75), base * CFrame.new(0, 1.4, 0), ac, METAL)
end
function A.torch(k)
	local base = SIDE_R * CFrame.new(0.3, 0.4, -0.3) * CFrame.Angles(RAD(-15), 0, RAD(-10))
	k:Part("block", Vector3.new(0.18, 1.6, 0.18), base, BROWN)
	local top = k:Part("cyl", Vector3.new(0.3, 0.35, 0.35), base * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(60, 60, 60))
	local f = Instance.new("Fire"); f.Size = 1.5; f.Heat = 4; f.Parent = top
	k:Light(top, Color3.fromRGB(255, 160, 60), 1.2, 8)
end
function A.smoke(k)
	k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(120, 120, 120)), Transparency = NumberSequence.new(0.4, 1), Rate = 6, Size = NumberSequence.new(1, 3), LightEmission = 0, Acceleration = Vector3.new(0, 1.5, 0)})
end
function A.pumpkinHat(k)
	for i = -1, 1 do k:Part("ball", Vector3.new(0.75, 1.0, 1.2), HEADTOP * CFrame.new(i * 0.35, 0.25, 0), Color3.fromRGB(255, 130, 20)) end
	k:Part("block", Vector3.new(0.15, 0.4, 0.15), HEADTOP * CFrame.new(0, 0.85, 0), Color3.fromRGB(60, 140, 50))
end
function A.bandage(k)
	for i = 1, 3 do
		k:Part("cyl", Vector3.new(0.18, 2.5 - i * 0.2, 2.9 - i * 0.2), CFrame.new(0, 0.6 + i * 0.4, 0.2) * CFrame.Angles(RAD(i * 8 - 12), 0, RAD(90)), Color3.fromRGB(240, 235, 215))
	end
	k:Part("cyl", Vector3.new(0.2, 1.75, 1.75), HEAD * CFrame.new(0, 0.1, 0) * CFrame.Angles(RAD(15), 0, RAD(90)), Color3.fromRGB(240, 235, 215))
end
function A.witchHat(k, d, ac)
	k:Part("cyl", Vector3.new(0.1, 2.3, 2.3), HEADTOP * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, RAD(90)), BLACK)
	k:Cone(HEADTOP * CFrame.Angles(RAD(-12), 0, 0), 1.8, 0.6, BLACK, SP, 6)
	k:Part("cyl", Vector3.new(0.2, 1.22, 1.22), HEADTOP * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
end
function A.fangs(k)
	for _, s in {-1, 1} do k:Part("wedge", Vector3.new(0.1, 0.3, 0.12), CFrame.new(s * 0.22, 1.85, -1.6) * CFrame.Angles(RAD(180), 0, 0), WHITE) end
end
function A.shadowAura(k, d, ac)
	k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Kit.Darken(ac, 0.5), ac), Transparency = NumberSequence.new(0.3, 1), Rate = 10, Size = NumberSequence.new(1, 2.4), LightEmission = 0.4, Acceleration = Vector3.new(0, 1, 0)})
	k:Light(k.Root, ac, 1.2, 8)
end
function A.ears(k, d, ac, body)
	for _, s in {-1, 1} do k:Part("wedge", Vector3.new(0.15, 0.7, 0.5), HEAD * CFrame.new(s * 0.5, 0.8, 0.1) * CFrame.Angles(0, 0, RAD(-s * 15)), Kit.Darken(body, 0.8)) end
end
function A.claws(k)
	for _, s in {-1, 1} do for i = -1, 1 do
		k:Part("wedge", Vector3.new(0.08, 0.35, 0.15), CFrame.new(s * 1.45, 0.8, -0.7 + i * 0.2) * CFrame.Angles(RAD(180), 0, 0), WHITE)
	end end
end
function A.diverHelmet(k)
	k:Part("ball", Vector3.new(2.3, 2.3, 2.3), HEAD * CFrame.new(0, 0, -0.1), Color3.fromRGB(200, 240, 255), GLASS).Transparency = 0.6
	k:Part("cyl", Vector3.new(0.35, 1.7, 1.7), NECK * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, RAD(90)), Color3.fromRGB(200, 150, 60), METAL)
end
function A.tentacles(k, d, ac)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		k:Chain(CFrame.new(math.cos(a) * 1.0, 0.3, math.sin(a) * 1.1 + 0.2) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(RAD(-110), 0, 0), 4, 0.4, 0.15, 0.32, RAD(25), ac, SP)
	end
end
function A.starHat(k, d, ac)
	local c = HEADTOP * CFrame.new(0, 0.5, 0) * CFrame.Angles(RAD(90), 0, 0)
	k:Part("cyl", Vector3.new(0.2, 0.5, 0.5), c * CFrame.Angles(0, RAD(90), 0), Color3.fromRGB(255, 220, 60), NEON)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k:Part("wedge", Vector3.new(0.15, 0.5, 0.3), c * CFrame.new(math.cos(a) * 0.38, 0, math.sin(a) * 0.38) * CFrame.Angles(0, -a + math.pi / 2, RAD(90)), Color3.fromRGB(255, 220, 60), NEON)
	end
end
function A.moonHat(k)
	for i = -3, 3 do
		local a = i * 0.3
		k:Part("sphere", Vector3.new(0.3, 0.3, 0.3) * (1 - math.abs(i) * 0.1), HEADTOP * CFrame.new(math.sin(a) * 0.5, 0.6 + math.cos(a) * 0.5, 0), Color3.fromRGB(255, 245, 190), NEON)
	end
end
function A.sailorHat(k, d, ac)
	k:Part("cyl", Vector3.new(0.5, 1.3, 1.3), HEADTOP * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, RAD(90)), WHITE)
	k:Part("cyl", Vector3.new(0.15, 1.33, 1.33), HEADTOP * CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, RAD(90)), ac)
end
function A.fishTail(k, d, ac)
	for _, s in {-1, 1} do k:Part("wedge", Vector3.new(0.12, 0.9, 1.2), CFrame.new(s * 0.4, 1.4, 2.0) * CFrame.Angles(RAD(-30), 0, RAD(s * 35)), ac) end
end
function A.prism(k)
	local hub = k:Hub(HEADTOP * CFrame.new(0, 1.2, 0), 1.5)
	local p = k:Part("block", Vector3.new(0.7, 0.7, 0.7), CFrame.Angles(RAD(45), 0, RAD(45)), WHITE, GLASS, hub)
	k:Particles(p, {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))}), Rate = 12})
end
function A.shield(k, d, ac)
	local c = SIDE_L * CFrame.new(-0.25, 0, -0.2)
	k:Part("cyl", Vector3.new(0.18, 1.7, 1.7), c, GOLD, METAL)
	k:Part("cyl", Vector3.new(0.22, 1.2, 1.2), c, ac, METAL)
	k:Part("sphere", Vector3.new(0.35, 0.35, 0.35), c * CFrame.new(-0.12, 0, 0), WHITE, NEON)
end
function A.harp(k)
	local base = SIDE_L * CFrame.new(-0.3, 0.3, -0.3)
	for i = 0, 6 do
		local a = i / 6 * math.pi * 0.9
		k:Part("sphere", Vector3.new(0.16, 0.16, 0.16), base * CFrame.new(0, math.sin(a) * 0.8, math.cos(a) * 0.6), GOLD, METAL)
	end
	for i = 1, 4 do k:Part("block", Vector3.new(0.02, 0.6, 0.02), base * CFrame.new(0, 0.35, -0.35 + i * 0.15), WHITE) end
end
function A.galaxy(k, d, ac)
	local rng = Random.new(#d.Name * 3)
	for _ = 1, 10 do
		local a, h = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0.5, 1.6)
		k:Part("sphere", Vector3.new(0.1, 0.1, 0.1), CFrame.new(math.cos(a) * 1.2, h, math.sin(a) * 1.45 + 0.2), WHITE, NEON)
	end
	k:Particles(k.Root, {Color = ColorSequence.new(ac, WHITE), Rate = 10, Size = NumberSequence.new(0.25, 0)})
end
function A.monocle(k)
	k:Ring(CFrame.new(-0.43, 2.62, -1.76) * CFrame.Angles(RAD(90), 0, 0), 0.25, 8, 0.07, GOLD, METAL)
	k:Part("block", Vector3.new(0.03, 0.8, 0.03), CFrame.new(-0.6, 2.2, -1.65), GOLD, METAL)
end
Builder.Accessories = A

-- Fallback: fully part-built duck (used only if the mesh library is missing)
function Builder.BuildLegacy(duck, opts)
	opts = opts or {}
	local k = Kit.new(duck.Name)
	local body = duck.Body
	local accent = duck.Accent
	local code = duck.Material or "P"
	local mat = Kit.MaterialCodes[code] or Enum.Material.SmoothPlastic

	local bodyPart = k:Part("ball", Vector3.new(2.5, 1.8, 3.1), CFrame.new(0, 0.85, 0.25), body, mat)
	bodyPart.Name = "Body"
	bodyPart.Reflectance = if code == "P" then 0.06 else 0
	k:Part("ball", Vector3.new(2.2, 1.8, 1.7), CFrame.new(0, 1.15, -0.5), body, mat)
	k:Part("ball", Vector3.new(1.3, 1.0, 1.1), CFrame.new(0, 1.45, 1.5) * CFrame.Angles(RAD(-40), 0, 0), body, mat)
	local head = k:Part("ball", Vector3.new(1.75, 1.7, 1.75), HEAD, body, mat)
	head.Name = "Head"
	-- beak (two flattened halves)
	local beakMat = if code == "N" then NEON else SP
	k:Part("ball", Vector3.new(0.95, 0.34, 1.0), CFrame.new(0, 2.22, -1.72), accent, beakMat)
	k:Part("ball", Vector3.new(0.78, 0.22, 0.75), CFrame.new(0, 2.06, -1.62), Kit.Darken(accent, 0.85), beakMat)
	-- eyes
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(0.44, 0.48, 0.3), CFrame.new(s * 0.42, 2.62, -1.58), WHITE)
		local pupil = k:Part("ball", Vector3.new(0.26, 0.3, 0.16), CFrame.new(s * 0.44, 2.63, -1.7), if duck.Rarity >= 9 then duck.Accent else BLACK, if duck.Rarity >= 9 then NEON else SP)
		pupil.Name = "Pupil"
		k:Part("ball", Vector3.new(0.08, 0.08, 0.05), CFrame.new(s * 0.4, 2.7, -1.77), WHITE, NEON)
	end
	-- wing nubs
	for _, s in {-1, 1} do
		k:Part("ball", Vector3.new(0.4, 0.9, 1.5), CFrame.new(s * 1.18, 1.0, 0.25) * CFrame.Angles(RAD(-10), 0, RAD(s * 8)), Kit.Darken(body, 0.92), mat)
	end
	if code == "N" then
		-- neon trim line around the body for glowing ducks
		k:Ring(CFrame.new(0, 0.55, 0.25), 1.25, 16, 0.18, accent, NEON)
	end
	if code == "F" then
		-- forcefield ducks get an inner core so they still read as solid
		k:Part("ball", Vector3.new(2.2, 1.5, 2.7), CFrame.new(0, 0.85, 0.25), Kit.Darken(body, 0.6), SP).Transparency = 0.3
	end

	for _, key in duck.Accessories do
		local fn = A[key]
		if fn then
			if not (opts.Lite and (key == "sparkle" or key == "gasAura" or key == "smoke" or key == "shadowAura" or key == "waveAura" or key == "galaxy" or key == "fireAura" or key == "iceAura")) then
				fn(k, duck, accent, body)
			end
		else
			warn("[DuckModelBuilder] Unknown accessory:", key)
		end
	end

	-- rarity effects
	local r = duck.Rarity
	local tier = Rarity.List[r]
	if not opts.Lite and not opts.NoEffects then
		if r >= 5 then
			k:Particles(k.Root, {Color = ColorSequence.new(tier.Glow, tier.Color), Rate = 6 + r * 2, Size = NumberSequence.new(0.3 + r * 0.03, 0), Speed = NumberRange.new(0.5, 2)})
			k:Light(head, tier.Glow, 0.6 + r * 0.1, 6 + r)
		end
		if r >= 6 then
			local disc = k:Part("cyl", Vector3.new(0.1, 4.6, 4.6), CFrame.new(0, 0.05, 0.2) * CFrame.Angles(0, 0, RAD(90)), tier.Color, NEON)
			disc.Transparency = 0.55
			disc.Name = "AuraDisc"
		end
		if r >= 7 then
			local beam = k:Part("cyl", Vector3.new(9, 1.2, 1.2), CFrame.new(0, 4.5, 0.2) * CFrame.Angles(0, 0, RAD(90)), tier.Glow, NEON)
			beam.Transparency = 0.85
			beam.Name = "LightPillar"
		end
		if r >= 9 then
			k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(40, 0, 50), tier.Glow), Transparency = NumberSequence.new(0.4, 1), Rate = 8, Size = NumberSequence.new(1.5, 3), LightEmission = 0.5})
		end
		if r >= 10 then
			k:Particles(k.Root, {Color = Rarity.Gradient(10), Rate = 30, Size = NumberSequence.new(0.5, 0), Speed = NumberRange.new(2, 4), Lifetime = NumberRange.new(1, 2)})
		end
	end

	k.Model:SetAttribute("DuckId", duck.Id)
	k.Model:SetAttribute("Rarity", r)
	if duck.Scale and duck.Scale ~= 1 then
		k.Model:ScaleTo(duck.Scale * (opts.Scale or 1))
	elseif opts.Scale then
		k.Model:ScaleTo(opts.Scale)
	end
	return k.Model
end

----------------------------------------------------------------------------
-- Mesh-based duck (Blender models in ReplicatedStorage.Assets.Meshes)
----------------------------------------------------------------------------
local NECK_PIVOT = CFrame.new(0, 1.75, -0.8)
local WING_PIVOT = {L = CFrame.new(-1.08, 1.5, 0.15), R = CFrame.new(1.08, 1.5, 0.15)}

-- accessory keys whose (legacy, part-built) pieces ride on the head
local HEAD_KEYS = {
	popcorn = true, clownNose = true, afro = true, jesterHat = true, visor = true, cloudHat = true, ninjaMask = true,
	sunglasses = true, crest = true, tikiMask = true, leafCrown = true, shellHat = true, rangerHat = true, finHelmet = true,
	earmuffs = true, diverHelmet = true, ears = true, fangs = true, starHat = true, moonHat = true, sailorHat = true,
	monocle = true, pumpkinHat = true, flower = true,
}
local LITE_SKIP = {sparkle = true, gasAura = true, smoke = true, shadowAura = true, waveAura = true, galaxy = true, fireAura = true, iceAura = true}

local function slotStyle(slot, ac, body, bodyMat)
	if slot == "Gold" then return GOLD, METAL
	elseif slot == "Silver" then return SILVER, METAL
	elseif slot == "Accent" then return ac, SP
	elseif slot == "Gem" then return Kit.Lighten(ac, 0.15), NEON
	elseif slot == "Black" then return BLACK, SP
	elseif slot == "White" then return WHITE, SP
	elseif slot == "Brown" then return BROWN, Enum.Material.Wood
	elseif slot == "Dark" then return Kit.Darken(ac, 0.45), SP
	elseif slot == "AccentDark" then return Kit.Darken(ac, 0.35), SP
	elseif slot == "Body" then return body, bodyMat
	end
	return ac, SP
end

-- Mesh accessories. ctx = {k, ac, body, mat, neck, accFolder, wings = {}}
local MA = {}
local function acc(ctx, name, weldTo, color, mat)
	local src = ctx.lib:FindFirstChild(name)
	if not src then return nil end
	local c, m = slotStyle(src:GetAttribute("Slot"), ctx.ac, ctx.body, ctx.mat)
	return ctx.k:Mesh(src, color or c, mat or m, weldTo)
end
local function headSet(...)
	local names = {...}
	return function(ctx)
		for _, n in names do acc(ctx, n, ctx.neck) end
	end
end
local function bodySet(...)
	local names = {...}
	return function(ctx)
		for _, n in names do acc(ctx, n) end
	end
end
MA.crown = function(ctx)
	acc(ctx, "crown__Gold", ctx.neck)
	local g = acc(ctx, "crown_gems__Gem", ctx.neck)
	if g then g.Color = Color3.fromRGB(255, 60, 90) end
end
MA.tophat = headSet("tophat__Black", "tophat_band__Accent")
MA.partyHat = headSet("partyhat__Accent", "partyhat_pom__White")
MA.witchHat = headSet("witchhat__Black", "witchhat_band__Accent")
MA.pirateHat = headSet("piratehat__Black", "piratehat_trim__Gold", "piratehat_skull__White")
MA.beanie = headSet("beanie__Accent", "beanie_cuff__White")
MA.helmet = headSet("helmet__Silver", "helmet_plume__Accent", "helmet_visor__Silver")
MA.finHelmet = function(ctx)
	MA.helmet(ctx)
	local k = ctx.k
	local fin = k:Part("wedge", Vector3.new(0.15, 1.0, 1.2), HEADTOP * CFrame.new(0, 0.55, 0.3), Color3.fromRGB(110, 140, 165), METAL)
	fin:FindFirstChildOfClass("WeldConstraint").Part0 = ctx.neck
end
MA.tiara = function(ctx)
	acc(ctx, "tiara__Gold", ctx.neck)
	acc(ctx, "tiara_gem__Gem", ctx.neck)
end
MA.goggles = function(ctx)
	acc(ctx, "goggles__Black", ctx.neck)
	local l = acc(ctx, "goggles_lens__Gem", ctx.neck, ctx.ac, GLASS)
	if l then l.Transparency = 0.25; l.Reflectance = 0.3 end
end
MA.eyepatch = headSet("eyepatch__Black")
MA.horns = function(ctx) acc(ctx, "horns__Dark", ctx.neck, Kit.Darken(ctx.ac, 0.8)) end
MA.hood = bodySet("hood__AccentDark")
MA.armor = bodySet("armor__Silver", "armor_trim__Accent")
MA.cape = bodySet("cape__Accent", "cape_clasp__Gold")
MA.crystalSpikes = function(ctx)
	local p = acc(ctx, "crystalspikes__Gem", nil, Kit.Lighten(ctx.ac, 0.2), GLASS)
	if p then p.Transparency = 0.2; p.Reflectance = 0.25 end
end
MA.sword = bodySet("sword_blade__Silver", "sword_hilt__Gold")
MA.scythe = bodySet("scythe_blade__Silver", "scythe_pole__Black")
MA.trident = bodySet("trident__Gold")
MA.hammer = bodySet("hammer_head__Silver", "hammer_handle__Brown")
MA.spear = bodySet("spear__Brown", "spear_tip__Silver")
MA.shield = bodySet("shield__Gold", "shield_face__Accent")
MA.scepter = bodySet("scepter__Gold", "scepter_gem__Gem")
MA.staff = function(ctx)
	acc(ctx, "staff__Brown", nil, Kit.Darken(ctx.ac, 0.5), METAL)
	local orb = acc(ctx, "staff_orb__Gem")
	if orb and not ctx.lite then ctx.k:Light(orb, ctx.ac, 1.5, 8) end
end
local function bigWings(ctx, prefix, color, mat, flame)
	local k = ctx.k
	for _, side in {"L", "R"} do
		local src = ctx.lib:FindFirstChild(prefix .. side .. (if prefix == "batwing" then "__Dark" else "__White"))
		if src then
			local s = if side == "L" then -1 else 1
			local inner = src.Position.X - s * src.Size.X / 2
			local pivot = CFrame.new(inner, src.Position.Y - 0.1, src.Position.Z - 0.1)
			local j = k:Joint("J_BigWing" .. side, pivot)
			local p = k:Mesh(src, color, mat, j)
			if flame and not ctx.lite then
				k:Particles(p, {Texture = Kit.Textures.Fire, Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 20)), Rate = 14, Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(15, 15), Acceleration = Vector3.new(0, 3, 0), Size = NumberSequence.new(0.6, 0)})
			end
		end
	end
end
MA.angelWings = function(ctx) bigWings(ctx, "wing", Color3.fromRGB(255, 255, 250), SP) end
MA.wings = function(ctx) bigWings(ctx, "wing", ctx.ac, SP) end
MA.wingsFire = function(ctx) bigWings(ctx, "wing", Color3.fromRGB(255, 140, 30), NEON, true) end
MA.batWings = function(ctx) bigWings(ctx, "batwing", Kit.Darken(ctx.ac, 0.45), SP) end
MA.halo = function(ctx)
	local src = ctx.lib:FindFirstChild("halo__Gold")
	if not src then return end
	local hub = ctx.k:Hub(CFrame.new(src.Position), 1.2)
	ctx.k:Mesh(src, Color3.fromRGB(255, 236, 130), NEON, hub)
	if not ctx.lite then ctx.k:Light(hub, Color3.fromRGB(255, 240, 160), 1, 6) end
end
MA.sunHalo = function(ctx)
	local src = ctx.lib:FindFirstChild("sunhalo__Gold")
	if not src then return end
	local at = HEAD * CFrame.new(0, 0.2, 0.95) * CFrame.Angles(RAD(90), 0, 0)
	local hub = ctx.k:Hub(at, 0.8)
	ctx.k:Mesh(src, Color3.fromRGB(255, 200, 40), NEON, hub, at)
	if not ctx.lite then ctx.k:Light(hub, Color3.fromRGB(255, 210, 90), 2, 10) end
end
MA.orbitShards = function(ctx)
	local src = ctx.lib:FindFirstChild("orbitshard__Gem")
	if not src then return end
	local base = CFrame.new(0, 2.0, 0)
	local hub = ctx.k:Hub(base, 1.0)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local cf = base * CFrame.new(math.cos(a) * 2.6, math.sin(a * 2) * 0.4, math.sin(a) * 2.6) * CFrame.Angles(RAD(25), a, RAD(20))
		ctx.k:Mesh(src, if i % 2 == 0 then ctx.ac else WHITE, NEON, hub, cf)
	end
end
MA.orbitRings = function(ctx)
	local src = ctx.lib:FindFirstChild("orbitring__Gem")
	if not src then return end
	local c1 = CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(18), 0, RAD(10))
	local h1 = ctx.k:Hub(c1, 1.5)
	ctx.k:Mesh(src, ctx.ac, NEON, h1, c1)
	local c2 = CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(-25), 0, RAD(-20))
	local h2 = ctx.k:Hub(c2, -1.1)
	local r2 = ctx.k:Mesh(src, Kit.Lighten(ctx.ac, 0.5), NEON, h2, c2)
	r2.Size *= 1.12
end
Builder.MeshAccessories = MA

----------------------------------------------------------------------------
-- Unique looks. Every duck gets its own mix of head tuft, tail, markings, face, beak and wing shape
-- (a different combination for every duck id), an element signature, and - for the plain common
-- ducks - a feature themed on its name. Parts are Blender meshes in Assets.Meshes.DuckParts.
----------------------------------------------------------------------------
local rgb = Color3.fromRGB
local V3 = Vector3.new
local TAIL_PIVOT = V3(0, 1.743, 1.913)
local WING_ROOT = V3(0.75, 1.95, 0.55)
local HEAD_TAKEN = {partyHat = true, popcorn = true, afro = true, tophat = true, jesterHat = true, visor = true, cloudHat = true, pirateHat = true, crown = true, helmet = true,
	finHelmet = true, beanie = true, witchHat = true, hood = true, rangerHat = true, leafCrown = true, shellHat = true, crest = true, pumpkinHat = true, starHat = true,
	moonHat = true, sailorHat = true, diverHelmet = true, tiara = true, earmuffs = true}
local TAIL_TAKEN = {fishTail = true, surfboard = true, cape = true, tentacles = true}
local BACK_TAKEN = {crystalSpikes = true, cape = true, katana = true, bow = true, surfboard = true, angelWings = true, wings = true, wingsFire = true, batWings = true}
local FACE_TAKEN = {eyepatch = true, goggles = true, sunglasses = true, ninjaMask = true, tikiMask = true, diverHelmet = true, monocle = true, bandage = true}
local WINGS_ACC = {angelWings = true, wings = true, wingsFire = true, batWings = true}
local ORBIT_ACC = {orbitShards = true, orbitRings = true, orbitBalls = true, coinOrbit = true}
local TUFTS = {"curl", "spikes", "feathers", "swirl", "antenna", "puff", "bow", "sprout", "none"}
local TAILS = {"fan", "curl", "spikes", "puff", "wisp", "none"}
local MARKS = {"belly", "spots", "stripes", "mask", "bellyspots", "none"}
local FACES = {"none", "cheeks", "lashes", "angry", "soft", "lashcheeks"}
local BEAKS = {V3(1, 1, 1), V3(1.3, 0.9, 1), V3(0.82, 1.1, 1.25), V3(0.78, 0.85, 0.8)}
local WINGSZ = {1, 1.25, 0.82}

-- part on the head (follows the neck joint)
local function hp(ctx, shape, size, cf, color, mat)
	local p = ctx.k:Part(shape, size, cf, color, mat)
	p:FindFirstChildOfClass("WeldConstraint").Part0 = ctx.neck
	return p
end

local ELEMENT = {
	Fire = {{tail = "flame", tailCol = rgb(255, 150, 30), tailMat = NEON}, {tuft = "flame", tuftCol = rgb(255, 170, 40), tuftMat = NEON}},
	Water = {{fin = true}, {tuft = "droplet", tuftCol = rgb(150, 220, 255), tuftMat = GLASS}},
	Nature = {{tuft = "sprout", tuftCol = rgb(80, 190, 70)}, {tail = "fan", tailCol = rgb(70, 170, 70)}},
	Ice = {{tuft = "shard", tuftCol = rgb(190, 240, 255), tuftMat = GLASS}, {cap = rgb(245, 250, 255), capMat = Enum.Material.Snow}},
	Light = {{headwings = true}, {tuft = "star", tuftCol = rgb(255, 235, 120), tuftMat = NEON}},
	Shadow = {{tail = "wisp", tailCol = rgb(40, 25, 60)}, {mark = "mask", markCol = rgb(25, 15, 35)}},
	Cosmic = {{tuft = "star", tuftCol = rgb(255, 235, 140), tuftMat = NEON}, {gem = true}},
	Void = {{tuft = "shard", tuftCol = rgb(200, 80, 255), tuftMat = NEON}, {tuft = "antenna", tuftCol = rgb(200, 80, 255), tuftMat = NEON}},
	Normal = {{tuft = "bow"}, {tuft = "curl"}},
}

local GREEN, PINK, ICE = rgb(70, 175, 70), rgb(255, 110, 180), rgb(190, 240, 255)
local SPECIAL = {
	["Classic Yellow Duck"] = {tuft = "curl", face = "cheeks", mark = "belly", tail = "curl"},
	["Blue Duck"] = {tuft = "droplet", tuftCol = rgb(150, 220, 255), tuftMat = GLASS, mark = "belly", fin = true, tail = "none"},
	["Red Duck"] = {tuft = "flame", tuftCol = rgb(255, 170, 40), tuftMat = NEON, tail = "spikes", face = "angry", mark = "none"},
	["Green Duck"] = {tuft = "sprout", tuftCol = GREEN, mark = "spots", tail = "fan", tailCol = GREEN},
	["Pink Duck"] = {tuft = "bow", tuftCol = rgb(255, 60, 150), face = "lashcheeks", mark = "belly", tail = "curl"},
	["Coconut Duck"] = {cap = rgb(96, 60, 30), capMat = Enum.Material.Wood, tuft = "none", mark = "belly", markCol = Color3.new(1, 1, 1), tail = "none"},
	["Palm Duck"] = {tuft = "feathers", tuftCol = GREEN, tail = "fan", tailCol = GREEN, mark = "stripes"},
	["Sandy Duck"] = {tuft = "star", tuftCol = rgb(255, 140, 90), mark = "spots", face = "cheeks", tail = "none"},
	["Mango Duck"] = {tuft = "sprout", tuftCol = GREEN, mark = "belly", markCol = rgb(255, 95, 60), tail = "none"},
	["Lagoon Duck"] = {fin = true, mark = "stripes", tuft = "droplet", tuftCol = rgb(170, 255, 240), tuftMat = GLASS},
	["Snowy Duck"] = {cap = Color3.new(1, 1, 1), capMat = Enum.Material.Snow, tuft = "none", tail = "puff", tailCol = Color3.new(1, 1, 1), face = "cheeks"},
	["Frost Duck"] = {tuft = "shard", tuftCol = ICE, tuftMat = GLASS, mark = "spots", markCol = Color3.new(1, 1, 1), tail = "spikes", tailCol = ICE},
	["Slush Duck"] = {tuft = "swirl", tuftCol = rgb(215, 245, 255), mark = "belly", tail = "curl"},
	["Icicle Duck"] = {tuft = "spikes", tuftCol = ICE, tuftMat = GLASS, tail = "spikes", tailCol = ICE, tailMat = GLASS, mark = "none"},
	["Mitten Duck"] = {cap = rgb(220, 50, 60), tuft = "puff", tuftCol = Color3.new(1, 1, 1), face = "cheeks", extra = function(ctx)
		for _, s in {-1, 1} do
			ctx.k:Part("ball", V3(0.6, 0.65, 0.75), CFrame.new(s * 1.32, 0.78, -0.25), rgb(220, 50, 60))
			ctx.k:Part("ball", V3(0.5, 0.25, 0.6), CFrame.new(s * 1.32, 1.1, -0.25), Color3.new(1, 1, 1))
		end
	end},
	["Ember Duck"] = {tail = "flame", tailCol = rgb(255, 150, 30), tailMat = NEON, face = "cheeks", cheekCol = rgb(255, 150, 40), cheekMat = NEON, tuft = "none"},
	["Ash Duck"] = {mark = "spots", markCol = rgb(60, 60, 65), tail = "wisp", tailCol = rgb(120, 120, 125), tuft = "puff", tuftCol = rgb(120, 120, 125)},
	["Magma Duck"] = {mark = "stripes", markCol = rgb(255, 130, 20), markMat = NEON, tuft = "flame", tuftCol = rgb(255, 170, 40), tuftMat = NEON, tail = "spikes"},
	["Charcoal Duck"] = {mark = "mask", markCol = rgb(20, 20, 22), tuft = "spikes", tuftCol = rgb(20, 20, 22), face = "cheeks", cheekCol = rgb(255, 120, 30), cheekMat = NEON, tail = "spikes", tailCol = rgb(20, 20, 22)},
	["Spark Duck"] = {tuft = "bolt", tuftCol = rgb(255, 235, 60), tuftMat = NEON, tail = "spikes", tailCol = rgb(255, 235, 60), face = "angry"},
	["Murky Duck"] = {mark = "mask", markCol = rgb(50, 40, 25), tail = "wisp", tailCol = rgb(70, 60, 40), tuft = "none"},
	["Moss Duck"] = {cap = rgb(70, 140, 60), capMat = Enum.Material.Grass, mark = "spots", markCol = rgb(70, 140, 60), tuft = "sprout", tuftCol = rgb(120, 210, 90)},
	["Bog Duck"] = {mark = "belly", markCol = rgb(60, 50, 30), tail = "curl", tuft = "antenna", tuftCol = rgb(110, 70, 35)},
	["Lily Pad Duck"] = {tuft = "none", mark = "belly", extra = function(ctx)
		hp(ctx, "cyl", V3(0.12, 1.7, 1.7), HEADTOP * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, RAD(90)), rgb(60, 160, 70))
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			hp(ctx, "ball", V3(0.3, 0.2, 0.3), HEADTOP * CFrame.new(0.3 + math.cos(a) * 0.18, 0.14, math.sin(a) * 0.18), rgb(255, 150, 200))
		end
		hp(ctx, "sphere", V3(0.18, 0.18, 0.18), HEADTOP * CFrame.new(0.3, 0.22, 0), rgb(255, 230, 80))
	end},
	["Mushroom Duck"] = {cap = rgb(215, 45, 45), tuft = "none", tail = "puff", tailCol = Color3.new(1, 1, 1), extra = function(ctx)
		for _, d in {V3(0, 1, 0), V3(0.55, 0.75, 0.2), V3(-0.5, 0.78, -0.15), V3(0.1, 0.72, 0.6), V3(-0.15, 0.8, -0.55)} do
			hp(ctx, "ball", V3(0.3, 0.14, 0.3), CFrame.lookAt(HEAD.Position + d.Unit * 0.93, HEAD.Position + d.Unit * 2) * CFrame.Angles(RAD(90), 0, 0), Color3.new(1, 1, 1))
		end
	end},
	["Bubble Duck"] = {tuft = "droplet", tuftCol = rgb(200, 240, 255), tuftMat = GLASS, mark = "none", extra = function(ctx)
		local b = hp(ctx, "sphere", V3(2.6, 2.6, 2.6), HEAD * CFrame.new(0, 0.1, -0.1), rgb(200, 240, 255), GLASS)
		b.Transparency = 0.72; b.Reflectance = 0.2
		for i, o in {V3(1.5, 2.9, 0.4), V3(-1.4, 3.4, 0.2), V3(0.9, 3.9, 1.0)} do
			local s = 0.5 - i * 0.1
			ctx.k:Part("sphere", V3(s, s, s), CFrame.new(o), rgb(200, 240, 255), GLASS).Transparency = 0.55
		end
	end},
	["Pearl Duck"] = {tuft = "none", mark = "belly", markCol = Color3.new(1, 1, 1), face = "lashes", extra = function(ctx)
		hp(ctx, "sphere", V3(0.55, 0.55, 0.55), HEADTOP * CFrame.new(0, 0.18, 0), rgb(250, 245, 255)).Reflectance = 0.45
	end},
	["Aqua Duck"] = {fin = true, tuft = "swirl", tuftCol = rgb(170, 240, 255), mark = "stripes", tail = "curl"},
	["Kelp Duck"] = {tuft = "feathers", tuftCol = rgb(40, 120, 60), tail = "fan", tailCol = rgb(40, 120, 60), mark = "stripes", markCol = rgb(40, 120, 60)},
	["Coral Duck"] = {tuft = "antenna", tuftCol = PINK, tail = "spikes", tailCol = PINK, mark = "spots", markCol = PINK},
	["Cloud Duck"] = {tuft = "puff", tuftCol = Color3.new(1, 1, 1), tail = "puff", tailCol = Color3.new(1, 1, 1), face = "cheeks", mark = "belly"},
	["Feather Duck"] = {tuft = "feathers", tuftCol = Color3.new(1, 1, 1), tail = "fan", tailCol = Color3.new(1, 1, 1), headwings = true},
	["Sunbeam Duck"] = {tuft = "spikes", tuftCol = rgb(255, 230, 80), tuftMat = NEON, face = "cheeks", mark = "belly", tail = "fan", tailCol = rgb(255, 230, 80)},
	["Dew Duck"] = {tuft = "droplet", tuftCol = rgb(190, 240, 255), tuftMat = GLASS, mark = "spots", markCol = rgb(220, 250, 255), tail = "none"},
	["Breeze Duck"] = {tuft = "swirl", tuftCol = Color3.new(1, 1, 1), tail = "curl", tailCol = Color3.new(1, 1, 1), face = "soft"},
	["Static Duck"] = {tuft = "bolt", tuftCol = rgb(120, 255, 255), tuftMat = NEON, mark = "stripes", markCol = rgb(120, 255, 255), markMat = NEON, tail = "spikes"},
	["Null Duck"] = {mark = "mask", markCol = rgb(10, 10, 14), tuft = "antenna", tuftCol = rgb(10, 10, 14), nopupils = true, tail = "none"},
	["Pixel Duck"] = {tuft = "none", mark = "spots", tail = "spikes", extra = function(ctx)
		for i, o in {V3(0, 0.12, 0), V3(0.34, 0.02, 0.1), V3(-0.3, 0.3, -0.1), V3(0.1, 0.46, 0.15)} do
			hp(ctx, "block", V3(0.3, 0.3, 0.3), HEADTOP * CFrame.new(o), if i % 2 == 0 then ctx.ac else rgb(120, 255, 200), NEON)
		end
	end},
	["Echo Duck"] = {tuft = "antenna", tail = "wisp", mark = "stripes", face = "soft"},
	["Dusk Duck"] = {mark = "mask", markCol = rgb(30, 20, 50), tuft = "star", tuftCol = rgb(255, 220, 130), tuftMat = NEON, tail = "wisp", tailCol = rgb(30, 20, 50)},
	["Obsidian Duck"] = {tuft = "shard", tuftCol = rgb(30, 20, 40), tuftMat = GLASS, tail = "spikes", tailCol = rgb(30, 20, 40), mark = "stripes", markCol = rgb(180, 70, 255), markMat = NEON},
	["Ghost Duck"] = {tail = "wisp", face = "soft", tuft = "curl", mark = "none"},
}

-- Deterministic traits. The base combination index is different for every duck id.
function Builder.Traits(duck)
	local id = duck.Id or 0
	local n = (id * 7919) % 23328
	local t = {}
	t.tuft = TUFTS[n % 9 + 1]; n //= 9
	t.tail = TAILS[n % 6 + 1]; n //= 6
	t.mark = MARKS[n % 6 + 1]; n //= 6
	t.face = FACES[n % 6 + 1]; n //= 6
	t.beak = n % 4 + 1; n //= 4
	t.wing = n % 3 + 1
	t.palette = id % 4
	local el = ELEMENT[duck.Element]
	if el then for key, v in el[id % 2 + 1] do t[key] = v end end
	local sp = SPECIAL[duck.Name]
	if sp then for key, v in sp do t[key] = v end end
	local has = {}
	for _, a in duck.Accessories do
		has[a] = true
		if HEAD_TAKEN[a] then t.tuft = "none"; t.cap = nil end
		if TAIL_TAKEN[a] then t.tail = "none" end
		if BACK_TAKEN[a] then t.fin = nil end
		if FACE_TAKEN[a] then t.face = "none"; if t.mark == "mask" then t.mark = "spots" end end
	end
	if has.armor and (t.mark == "belly" or t.mark == "bellyspots") then t.mark = "stripes" end
	if has.helmet or has.finHelmet or has.diverHelmet or has.hood or has.earmuffs or has.horns then t.headwings = nil end
	if has.halo and t.tuft == "antenna" then t.tuft = "curl" end
	return t, has
end

local function dpart(ctx, name, color, mat, weldTo, cf)
	local src = ctx.parts:FindFirstChild(name)
	if not src then return nil end
	local p = ctx.k:Mesh(src, color, mat or SP, weldTo, cf)
	p.Name = name
	p.CastShadow = false
	return p
end

function Builder._ApplyTraits(ctx, t)
	local body, ac, neck = ctx.body, ctx.ac, ctx.neck
	local pal = {ac, Kit.Lighten(body, 0.4), Kit.Darken(body, 0.68), WHITE}
	local feat = pal[t.palette + 1]
	if t.cap then dpart(ctx, "head_cap", t.cap, t.capMat, neck) end
	if t.tuft and t.tuft ~= "none" then
		local p = dpart(ctx, "tuft_" .. t.tuft, t.tuftCol or feat, t.tuftMat, neck)
		if p and t.cap then p.CFrame += V3(0, 0.07, 0) end
	end
	if t.tail and t.tail ~= "none" then dpart(ctx, "tail_" .. t.tail, t.tailCol or feat, t.tailMat) end
	local mk = t.mark
	if mk == "belly" or mk == "bellyspots" then dpart(ctx, "mark_belly", (mk == "belly" and t.markCol) or Kit.Lighten(body, 0.5), t.markMat) end
	if mk == "spots" or mk == "bellyspots" then dpart(ctx, "mark_spots", (mk == "spots" and t.markCol) or Kit.Darken(body, 0.7), t.markMat) end
	if mk == "stripes" then dpart(ctx, "mark_stripes", t.markCol or Kit.Darken(body, 0.72), t.markMat) end
	if mk == "mask" then dpart(ctx, "mark_mask", t.markCol or Kit.Darken(body, 0.55), t.markMat, neck) end
	local f = t.face
	if f == "cheeks" or f == "lashcheeks" then dpart(ctx, "face_cheeks", t.cheekCol or rgb(255, 120, 150), t.cheekMat, neck) end
	if f == "lashes" or f == "lashcheeks" then dpart(ctx, "face_lashes", BLACK, SP, neck) end
	if f == "angry" then dpart(ctx, "face_brows_angry", BLACK, SP, neck) end
	if f == "soft" then dpart(ctx, "face_brows_soft", BLACK, SP, neck) end
	if t.fin then dpart(ctx, "body_fin", Kit.Darken(body, 0.7), SP) end
	if t.gem then dpart(ctx, "body_gem", ac, NEON) end
	if t.headwings then dpart(ctx, "head_wings", WHITE, SP, neck) end
	ctx.beak.Size *= BEAKS[t.beak]
	for _, w in ctx.wings do w.Size *= WINGSZ[t.wing] end
	if t.nopupils then ctx.pupils.Transparency = 1 end
	if t.extra then t.extra(ctx) end
end

----------------------------------------------------------------------------
-- Top rarities (Divine+): extra model parts on animated joints + signature effects.
-- Joints are driven by Client.RigAnimator: J_Core (whole duck hover/flourish), J_Plume1-3, J_EWingL/R.
----------------------------------------------------------------------------
local SIG_STYLE = {Fire = "ascend", Light = "ascend", Water = "roll", Ice = "roll", Shadow = "glitch", Void = "glitch", Cosmic = "loop", Nature = "loop", Normal = "loop"}
Builder.SigStyle = SIG_STYLE
local NR, NS, CS = NumberRange.new, NumberSequence.new, ColorSequence.new
local ELEMENT_FX = {
	Fire = function(g) return {Texture = Kit.Textures.Fire, Color = CS(rgb(255, 225, 90), rgb(255, 60, 20)), Rate = 14, Speed = NR(1.5, 3), Acceleration = V3(0, 4, 0), Size = NS(0.7, 0), SpreadAngle = Vector2.new(30, 30), Lifetime = NR(0.6, 1.2)} end,
	Ice = function(g) return {Color = CS(Color3.new(1, 1, 1)), Rate = 12, Speed = NR(0.5, 1.5), Acceleration = V3(0, -3, 0), Size = NS(0.3, 0.05), Lifetime = NR(1.2, 2)} end,
	Water = function(g) return {Color = CS(rgb(150, 225, 255)), Rate = 10, Speed = NR(1, 2.5), Acceleration = V3(0, 2, 0), Size = NS(0.25, 0.45), Transparency = NS(0.2, 1)} end,
	Nature = function(g) return {Color = CS(rgb(110, 230, 90), rgb(255, 240, 120)), Rate = 8, Speed = NR(1, 2), RotSpeed = NR(-180, 180), Size = NS(0.35, 0), Acceleration = V3(0, -1.5, 0)} end,
	Light = function(g) return {Color = CS(rgb(255, 250, 200)), Rate = 16, Speed = NR(3, 6), SpreadAngle = Vector2.new(10, 10), EmissionDirection = Enum.NormalId.Top, Size = NS(0.35, 0), LightEmission = 1, Lifetime = NR(0.5, 0.9)} end,
	Shadow = function(g) return {Texture = Kit.Textures.Smoke, Color = CS(rgb(20, 0, 35), g), Rate = 10, Size = NS(1.2, 2.6), Transparency = NS(0.4, 1), Acceleration = V3(0, -1, 0), LightEmission = 0.2} end,
	Cosmic = function(g) return {Color = CS(Color3.new(1, 1, 1), rgb(255, 160, 255)), Rate = 18, Speed = NR(0.2, 0.8), Size = NS(0.4, 0), Lifetime = NR(1, 2), LightEmission = 1} end,
	Void = function(g) return {Texture = "", Color = CS(g, rgb(60, 0, 90)), Rate = 16, Size = NS(0.2, 0.2), Lifetime = NR(0.2, 0.5), Speed = NR(3, 7), LightEmission = 1} end,
	Normal = function(g) return {Color = CS(rgb(255, 225, 110), Color3.new(1, 1, 1)), Rate = 14, Speed = NR(0.5, 1.5), Size = NS(0.4, 0), LightEmission = 1} end,
}

-- glowing rune circle that stays on the water while the duck hovers above it
function Builder._Rune(k, parts, duck, r, tier)
	local src = parts:FindFirstChild("op_rune")
	if not src then return end
	local function ring(scale, speed, color, tr)
		local hub = k:Hub(CFrame.new(src.Position), speed)
		local p = k:Mesh(src, color, NEON, hub)
		p.Size = src.Size * V3(scale, 1, scale)
		p.Transparency = tr
		p.CastShadow = false
		p.Name = "Rune"
		pcall(function() p.DoubleSided = true end)
	end
	ring(1, 0.5, tier.Glow, 0.2)
	if r >= 10 then ring(1.32, -0.3, duck.Accent, 0.35) end
end

function Builder._Sig(ctx, duck, r, tier, opts, has)
	local k, parts = ctx.k, ctx.parts
	local glow = tier.Glow
	local psrc = parts:FindFirstChild("op_plume")
	if psrc then
		local n = if r >= 8 then 3 else 1
		local cols = {ctx.ac, glow, Kit.Lighten(ctx.body, 0.5)}
		local rel = psrc.Position - TAIL_PIVOT
		for i = 1, n do
			local yaw = if n == 1 then 0 else (i - 2) * RAD(30)
			local sc = if (i == 2 or n == 1) then 1.5 else 1.2
			local pivot = CFrame.new(TAIL_PIVOT) * CFrame.Angles(0, yaw, 0)
			local j = k:Joint("J_Plume" .. i, pivot)
			local p = k:Mesh(psrc, cols[(i - 1) % 3 + 1], if r >= 9 then NEON else SP, j, pivot * CFrame.new(rel * sc) * psrc.CFrame.Rotation)
			p.Size = psrc.Size * sc
			p.CastShadow = false
			p.Name = "Plume"
		end
	end
	if r < 8 then return end
	local hasWings, hasOrbit, headTaken = false, false, false
	for a in has do
		if WINGS_ACC[a] then hasWings = true end
		if ORBIT_ACC[a] then hasOrbit = true end
		if HEAD_TAKEN[a] then headTaken = true end
	end
	-- blades of light fanned out as wings
	local fsrc = parts:FindFirstChild("op_efeather")
	if fsrc and not hasWings then
		local relX = (fsrc.Position - WING_ROOT).X
		local nf = if r >= 10 then 5 else 4
		for _, s in {1, -1} do
			local root = CFrame.new(WING_ROOT.X * s, WING_ROOT.Y, WING_ROOT.Z) * (if s < 0 then CFrame.Angles(0, math.pi, 0) else CFrame.new())
			local j = k:Joint("J_EWing" .. (if s > 0 then "R" else "L"), root)
			for i = 1, nf do
				local len = 1.25 - (i - 1) * 0.13
				local cf = root * CFrame.Angles(0, RAD(-14) * s, 0) * CFrame.Angles(0, 0, RAD(8 + (i - 1) * 24)) * CFrame.new(relX * len, 0, 0)
				local p = k:Mesh(fsrc, if i % 2 == 1 then glow else ctx.ac, NEON, j, cf)
				p.Size = fsrc.Size * V3(len, 1, 1)
				p.Transparency = 0.12
				p.CastShadow = false
				p.Name = "EFeather"
			end
		end
	end
	-- spinning spiked corona over the head
	local csrc = parts:FindFirstChild("op_corona")
	if csrc and not (has.halo or has.sunHalo) then
		local at = CFrame.new(csrc.Position + V3(0, if headTaken then 0.9 else 0, 0))
		local hub = k:Hub(at, 0.9)
		local p = k:Mesh(csrc, if r >= 10 then rgb(255, 235, 140) else glow, NEON, hub, at * csrc.CFrame.Rotation)
		p.CastShadow = false
		p.Name = "Corona"
		pcall(function() p.DoubleSided = true end)
	end
	if not has.armor then dpart(ctx, "body_gem", glow, NEON) end
	-- comet orbs for Secret+ ducks that don't already have something orbiting them
	local orbs = {}
	if r >= 9 and not hasOrbit then
		local hub = k:Hub(CFrame.new(0, 1.6, 0.2) * CFrame.Angles(RAD(12), 0, RAD(8)), 2.2)
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local o = k:Part("sphere", V3(0.42, 0.42, 0.42), CFrame.new(math.cos(a) * 2.5, 0, math.sin(a) * 2.5), if i == 2 then ctx.ac else glow, NEON, hub)
			o.Name = "Orb"
			table.insert(orbs, o)
		end
	end
	if opts.Lite or opts.NoEffects then return end
	local core = k.Root
	local function trail(part, p0, p1, life, color)
		local a0 = Instance.new("Attachment"); a0.Position = p0; a0.Parent = part
		local a1 = Instance.new("Attachment"); a1.Position = p1; a1.Parent = part
		local tr = Instance.new("Trail")
		tr.Attachment0 = a0; tr.Attachment1 = a1
		tr.Lifetime = life
		tr.LightEmission = 1
		tr.FaceCamera = true
		tr.Color = color
		tr.Transparency = NS(0.25, 1)
		tr.WidthScale = NS(1, 0.15)
		tr.Parent = part
	end
	trail(core, V3(0, 2.3, 0.7), V3(0, 0.4, 0.7), 0.5 + (r - 8) * 0.3, if r >= 10 then Rarity.Gradient(10) else CS(glow, ctx.ac))
	for _, o in orbs do trail(o, V3(0, 0.2, 0), V3(0, -0.2, 0), 0.35, CS(o.Color)) end
	local fx = ELEMENT_FX[duck.Element] or ELEMENT_FX.Normal
	k:Particles(core, fx(glow)).Name = "ElementFx"
	local burst = k:Particles(core, {Rate = 0, Color = if r >= 10 then Rarity.Gradient(10) else CS(glow, Color3.new(1, 1, 1)), Size = NS(0.9, 0), Speed = NR(8, 16), Lifetime = NR(0.5, 1), LightEmission = 1})
	burst.Name = "SigBurst"
end

-- opts: {Lite = bool (no particles/lights, for pools), NoEffects = bool, Scale = number}
function Builder.Build(duck, opts)
	opts = opts or {}
	local ok, M = pcall(Kit.Meshes)
	local lib = ok and M and M:FindFirstChild("Duck")
	if not lib then return Builder.BuildLegacy(duck, opts) end
	local accLib = M:FindFirstChild("Acc")

	local k = Kit.new(duck.Name)
	local body, accent = duck.Body, duck.Accent
	local code = duck.Material or "P"
	local mat = Kit.MaterialCodes[code] or SP
	if code == "M" then mat = SP end -- foil texture crinkles on big smooth meshes; use polished reflectance instead
	local r = duck.Rarity
	local tier = Rarity.List[r]
	local partsLib = M:FindFirstChild("DuckParts")
	if r >= 7 and partsLib then
		-- the rune stays on the water; everything else hangs off an animated core joint
		if r >= 8 then Builder._Rune(k, partsLib, duck, r, tier) end
		local core = k:Joint("J_Core", CFrame.new())
		k.Root = core
	end

	-- rig: Root (anchored) -> [Core] -> Neck joint -> head pieces; Core -> WingL / WingR joints
	local bodyPart = k:Mesh(lib.Body, body, mat)
	bodyPart.Name = "Body"
	bodyPart.Reflectance = if code == "P" then 0.08 elseif code == "M" then 0.3 else 0
	if code == "F" then
		local core = k:Mesh(lib.Body, Kit.Darken(body, 0.6), SP)
		core.Size *= 0.9; core.Transparency = 0.3; core.Name = "Core"
	end
	local neck = k:Joint("J_Neck", NECK_PIVOT)
	local head = k:Mesh(lib.Head, body, mat, neck)
	head.Name = "Head"
	head.Reflectance = bodyPart.Reflectance
	local beak = k:Mesh(lib.Beak, accent, if code == "N" then NEON else SP, neck)
	beak.Name = "Beak"
	k:Mesh(lib.EyeWhites, WHITE, SP, neck).Name = "Eyes"
	local pupils = k:Mesh(lib.Pupils, if r >= 9 then accent else BLACK, if r >= 9 then NEON else SP, neck)
	pupils.Name = "Pupil"
	k:Mesh(lib.Shine, WHITE, NEON, neck).Name = "Shine"
	for _, side in {"L", "R"} do
		local j = k:Joint("J_Wing" .. side, WING_PIVOT[side])
		local w = k:Mesh(lib["Wing" .. side], Kit.Darken(body, 0.93), mat, j)
		w.Name = "Wing" .. side
		w.Reflectance = bodyPart.Reflectance
	end
	if code == "N" then
		k:Ring(CFrame.new(0, 0.55, 0.25), 1.25, 16, 0.18, accent, NEON)
	end

	local ctx = {k = k, ac = accent, body = body, mat = mat, neck = neck, lib = accLib, lite = opts.Lite, parts = partsLib,
		beak = beak, pupils = pupils, wings = {k.Model:FindFirstChild("WingL"), k.Model:FindFirstChild("WingR")}}
	local traits, has = Builder.Traits(duck)
	if partsLib then Builder._ApplyTraits(ctx, traits) end
	for _, key in duck.Accessories do
		if opts.Lite and LITE_SKIP[key] then continue end
		local mfn = accLib and MA[key]
		if mfn then
			mfn(ctx)
		elseif A[key] then
			local before = {}
			for _, c in k.Model:GetChildren() do before[c] = true end
			A[key](k, duck, accent, body)
			if HEAD_KEYS[key] then
				for _, c in k.Model:GetChildren() do
					if not before[c] and c:IsA("BasePart") then
						local w = c:FindFirstChildOfClass("WeldConstraint")
						if w and w.Part0 == k.Root then w.Part0 = neck end
					end
				end
			end
		else
			warn("[DuckModelBuilder] Unknown accessory:", key)
		end
	end
	if r >= 7 and partsLib then Builder._Sig(ctx, duck, r, tier, opts, has) end

	if not opts.Lite and not opts.NoEffects then
		if r >= 5 then
			k:Particles(k.Root, {Color = ColorSequence.new(tier.Glow, tier.Color), Rate = 6 + r * 2, Size = NumberSequence.new(0.3 + r * 0.03, 0), Speed = NumberRange.new(0.5, 2)})
			k:Light(head, tier.Glow, 0.6 + r * 0.1, 6 + r)
		end
		if r >= 6 then
			local disc = k:Part("cyl", Vector3.new(0.1, 4.6, 4.6), CFrame.new(0, 0.05, 0.2) * CFrame.Angles(0, 0, RAD(90)), tier.Color, NEON)
			disc.Transparency = 0.55
			disc.Name = "AuraDisc"
		end
		if r >= 7 then
			local beam = k:Part("cyl", Vector3.new(9, 1.2, 1.2), CFrame.new(0, 4.5, 0.2) * CFrame.Angles(0, 0, RAD(90)), tier.Glow, NEON)
			beam.Transparency = 0.85
			beam.Name = "LightPillar"
		end
		if r >= 9 then
			k:Particles(k.Root, {Texture = Kit.Textures.Smoke, Color = ColorSequence.new(Color3.fromRGB(40, 0, 50), tier.Glow), Transparency = NumberSequence.new(0.4, 1), Rate = 8, Size = NumberSequence.new(1.5, 3), LightEmission = 0.5})
		end
		if r >= 10 then
			k:Particles(k.Root, {Color = Rarity.Gradient(10), Rate = 30, Size = NumberSequence.new(0.5, 0), Speed = NumberRange.new(2, 4), Lifetime = NumberRange.new(1, 2)})
		end
	end

	k.Model:SetAttribute("DuckId", duck.Id)
	k.Model:SetAttribute("Rarity", r)
	k.Model:SetAttribute("Rig", "Duck")
	if r >= 7 and partsLib then
		k.Model:SetAttribute("Sig", r)
		k.Model:SetAttribute("SigStyle", SIG_STYLE[duck.Element] or "loop")
		if r >= 8 then
			local disc = k.Model:FindFirstChild("AuraDisc")
			if disc then disc:Destroy() end -- the rune circle replaces the plain disc
		end
	end
	k.Model:SetAttribute("Seed", ((duck.Id or 0) * 7919) % 1000 / 1000)
	local scale = (duck.Scale or 1) * (opts.Scale or 1)
	if scale ~= 1 then k.Model:ScaleTo(scale) end
	return k.Model
end

-- Mom duck: a big brown mallard hen in a bonnet, apron and pearls, rolling pin at the ready.
-- Lives in the pond and chases anyone who runs off with one of her ducklings.
local MOM = {
	Body = Color3.fromRGB(150, 105, 65), Wing = Color3.fromRGB(118, 80, 48), Speck = Color3.fromRGB(95, 62, 36),
	Beak = Color3.fromRGB(255, 160, 40), Bonnet = Color3.fromRGB(255, 170, 200), Trim = Color3.fromRGB(255, 255, 255),
	Ribbon = Color3.fromRGB(235, 70, 120), Pearl = Color3.fromRGB(250, 245, 235), Apron = Color3.fromRGB(255, 250, 240),
	Wood = Color3.fromRGB(196, 140, 88),
}
function Builder.BuildMom(opts)
	opts = opts or {}
	local M = Kit.Meshes()
	local lib, momLib, partsLib = M.Duck, M:FindFirstChild("Mom"), M:FindFirstChild("DuckParts")
	local k = Kit.new("MomDuck")
	local body = k:Mesh(lib.Body, MOM.Body, SP); body.Name = "Body"
	local neck = k:Joint("J_Neck", NECK_PIVOT)
	local head = k:Mesh(lib.Head, MOM.Body, SP, neck); head.Name = "Head"
	k:Mesh(lib.Beak, MOM.Beak, SP, neck).Name = "Beak"
	k:Mesh(lib.EyeWhites, WHITE, SP, neck).Name = "Eyes"
	k:Mesh(lib.Pupils, BLACK, SP, neck).Name = "Pupil"
	k:Mesh(lib.Shine, WHITE, NEON, neck).Name = "Shine"
	for _, side in {"L", "R"} do
		local j = k:Joint("J_Wing" .. side, WING_PIVOT[side])
		k:Mesh(lib["Wing" .. side], MOM.Wing, SP, j).Name = "Wing" .. side
	end
	if partsLib then
		local spots = partsLib:FindFirstChild("mark_spots")
		if spots then k:Mesh(spots, MOM.Speck, SP).Name = "Specks" end
		local lashes = partsLib:FindFirstChild("face_lashes")
		if lashes then k:Mesh(lashes, BLACK, SP, neck).Name = "Lashes" end
		local soft = partsLib:FindFirstChild("face_brows_soft")
		if soft then k:Mesh(soft, MOM.Speck, SP, neck).Name = "BrowsCalm" end
		local angry = partsLib:FindFirstChild("face_brows_angry")
		if angry then local a = k:Mesh(angry, BLACK, SP, neck); a.Name = "BrowsAngry"; a.Transparency = 1 end
	end
	if momLib then
		local function add(name, color, mat, to)
			local src = momLib:FindFirstChild(name)
			if src then local p = k:Mesh(src, color, mat or SP, to); p.Name = "Mom_" .. name; return p end
		end
		add("bonnet", MOM.Bonnet, Enum.Material.Fabric, neck)
		add("brim", MOM.Trim, Enum.Material.Fabric, neck)
		add("ribbon", MOM.Ribbon, SP, neck)
		add("pearls", MOM.Pearl, SP).Reflectance = 0.25
		add("apron", MOM.Apron, Enum.Material.Fabric)
		local pinSrc = momLib:FindFirstChild("pin")
		if pinSrc then
			local pj = k:Joint("J_Pin", CFrame.new(1.05, 1.55, 0.2))
			k:Mesh(pinSrc, MOM.Wood, Enum.Material.Wood, pj).Name = "RollingPin"
		end
	end
	k.Model:SetAttribute("Rig", "Duck")
	k.Model:SetAttribute("AnimStyle", "swim")
	k.Model:SetAttribute("Seed", 0.37)
	k.Model:SetAttribute("Mom", true)
	local scale = opts.Scale or 1
	if scale ~= 1 then k.Model:ScaleTo(scale) end
	return k.Model
end

return Builder
