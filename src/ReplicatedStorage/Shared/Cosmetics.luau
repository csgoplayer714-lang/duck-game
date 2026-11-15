-- Wearable cosmetics bought with Feathers (made in the Coop).
-- Models live in ReplicatedStorage.Assets.Meshes.Cosmetics.<Id> (Blender). Parts named a_* / wl_* / wr_* are animated.
-- Slot: where it attaches; only one item per slot can be worn.
-- Anim: how the client animates it (see Client.CosmeticFx).
local Cosmetics = {}

Cosmetics.Slots = {"Hat", "Face", "Back", "Waist", "Trail"}
Cosmetics.Attach = {Hat = "HatAttachment", Face = "FaceFrontAttachment", Back = "BodyBackAttachment", Waist = "WaistCenterAttachment"}

-- Rarity reuses the duck rarity colours (Shared.Rarity) for the UI
Cosmetics.List = {
	{Id = "Shades",      Name = "Cool Shades",       Slot = "Face",  Price = 600,    Rarity = 1, Anim = "none",   Desc = "Too cool for the pond."},
	{Id = "PropCap",     Name = "Propeller Cap",     Slot = "Hat",   Price = 900,    Rarity = 2, Anim = "spin",   Desc = "The propeller spins as you move."},
	{Id = "DuckHat",     Name = "Rubber Duck Hat",   Slot = "Hat",   Price = 1800,   Rarity = 2, Anim = "bob",    Desc = "A tiny duck that bobs and squeaks on your head."},
	{Id = "PirateHat",   Name = "Pirate Hat",        Slot = "Hat",   Price = 3000,   Rarity = 3, Anim = "sway",   Desc = "Arr! The feather sways in the wind."},
	{Id = "Floatie",     Name = "Duck Floatie",      Slot = "Waist", Price = 4500,   Rarity = 3, Anim = "float",  Desc = "A squeaky ring that bobs around your waist."},
	{Id = "Jetpack",     Name = "Rocket Jetpack",    Slot = "Back",  Price = 9000,   Rarity = 4, Anim = "jet",    Desc = "Twin thrusters with real flames."},
	{Id = "RainbowTrail",Name = "Rainbow Trail",     Slot = "Trail", Price = 14000,  Rarity = 4, Anim = "trail",  Desc = "Leave a rainbow wherever you run."},
	{Id = "Crown",       Name = "Royal Crown",       Slot = "Hat",   Price = 18000,  Rarity = 5, Anim = "orbit",  Desc = "Gems orbit your royal head."},
	{Id = "Halo",        Name = "Golden Halo",       Slot = "Hat",   Price = 28000,  Rarity = 5, Anim = "halo",   Desc = "Floats, spins and sparkles."},
	{Id = "AngelWings",  Name = "Angel Wings",       Slot = "Back",  Price = 45000,  Rarity = 6, Anim = "flap",   Desc = "Soft wings that gently flap."},
	{Id = "DragonWings", Name = "Dragon Wings",      Slot = "Back",  Price = 75000,  Rarity = 7, Anim = "dragon", Desc = "Huge wings that beat and shed embers."},
	{Id = "CosmicAura",  Name = "Cosmic Aura",       Slot = "Waist", Price = 120000, Rarity = 8, Anim = "cosmic", Desc = "A tiny solar system orbits you."},
}
Cosmetics.ById = {}
for i, c in Cosmetics.List do c.Order = i; Cosmetics.ById[c.Id] = c end

-- colours/materials per mesh slot (from the Blender part names)
Cosmetics.Style = {
	CapA = {Color3.fromRGB(230, 50, 50), "SmoothPlastic"}, CapB = {Color3.fromRGB(255, 215, 40), "SmoothPlastic"},
	Metal = {Color3.fromRGB(205, 205, 215), "Metal"}, Prop = {Color3.fromRGB(60, 160, 255), "SmoothPlastic"},
	Lens = {Color3.fromRGB(25, 25, 35), "Glass"}, Frame = {Color3.fromRGB(250, 200, 40), "Metal"},
	Yellow = {Color3.fromRGB(255, 215, 40), "SmoothPlastic"}, Orange = {Color3.fromRGB(255, 140, 30), "SmoothPlastic"},
	Black = {Color3.fromRGB(20, 20, 20), "SmoothPlastic"}, Hat = {Color3.fromRGB(35, 30, 38), "Fabric"},
	Gold = {Color3.fromRGB(255, 200, 50), "Metal"}, Bone = {Color3.fromRGB(240, 235, 220), "SmoothPlastic"},
	Feather = {Color3.fromRGB(220, 40, 60), "SmoothPlastic"}, Floatie = {Color3.fromRGB(255, 220, 50), "SmoothPlastic"},
	White = {Color3.fromRGB(250, 250, 250), "SmoothPlastic"}, Body = {Color3.fromRGB(220, 50, 50), "SmoothPlastic"},
	Dark = {Color3.fromRGB(50, 50, 60), "Metal"}, Gem = {Color3.fromRGB(80, 200, 255), "Neon"}, Gem2 = {Color3.fromRGB(255, 60, 120), "Neon"},
	Halo = {Color3.fromRGB(255, 225, 110), "Neon"}, WingA = {Color3.fromRGB(250, 250, 255), "SmoothPlastic"},
	WingB = {Color3.fromRGB(255, 215, 110), "SmoothPlastic"}, Membrane = {Color3.fromRGB(200, 40, 30), "SmoothPlastic"},
	PlanetA = {Color3.fromRGB(255, 150, 60), "SmoothPlastic"}, PlanetB = {Color3.fromRGB(120, 200, 255), "Neon"},
	PlanetC = {Color3.fromRGB(200, 120, 255), "Neon"}, Ring = {Color3.fromRGB(255, 230, 180), "SmoothPlastic"}, Moon = {Color3.fromRGB(220, 220, 230), "SmoothPlastic"},
}

-- pivots (in cosmetic space) for animated groups
Cosmetics.Pivots = {
	AngelWings = {wl = Vector3.new(-0.25, 0.3, 0.45), wr = Vector3.new(0.25, 0.3, 0.45)},
	DragonWings = {wl = Vector3.new(-0.25, 0.35, 0.45), wr = Vector3.new(0.25, 0.35, 0.45)},
	PirateHat = {a = Vector3.new(0.35, 0.55, 0.15)},
	PropCap = {a = Vector3.new(0, 0.7, 0)},
	DuckHat = {a = Vector3.new(0, 0.1, 0)},
	Crown = {a = Vector3.new(0, 0.35, 0)},
	Halo = {a = Vector3.new(0, 0.75, 0)},
	Floatie = {a = Vector3.new(0, 0, 0)},
	CosmicAura = {a = Vector3.new(0, 0.5, 0)},
}

return Cosmetics
