--!strict
-- Rarity tiers: odds, colors and catching-minigame difficulty.
-- The rarer the duck, the harder the minigame (faster, smaller window, more resistance, stages).
local Rarity = {}

export type Tier = {
	Name: string, Index: number, OneIn: number, Color: Color3, Glow: Color3,
	-- minigame
	BarSize: number, DuckSpeed: number, Retarget: number, Jitter: number,
	Gain: number, Drain: number, Stages: number, TimeLimit: number,
	BurstChance: number, Pattern: string,
	-- rewards / meta
	XP: number, Coins: number, Announce: string?, StatMult: number,
}

local T: {Tier} = {
	{Name="Common",      Index=1,  OneIn=1,       Color=Color3.fromRGB(200,200,200), Glow=Color3.fromRGB(255,255,255), BarSize=0.42, DuckSpeed=0.10, Retarget=2.4,  Jitter=0.00, Gain=0.60, Drain=0.10, Stages=1, TimeLimit=20, BurstChance=0,    Pattern="drift",   XP=5,     Coins=10,      StatMult=1.0},
	{Name="Uncommon",    Index=2,  OneIn=3,       Color=Color3.fromRGB(85,220,110),  Glow=Color3.fromRGB(140,255,160), BarSize=0.36, DuckSpeed=0.18, Retarget=1.9,  Jitter=0.05, Gain=0.50, Drain=0.14, Stages=1, TimeLimit=22, BurstChance=0,    Pattern="drift",   XP=12,    Coins=25,     StatMult=1.35},
	{Name="Rare",        Index=3,  OneIn=10,      Color=Color3.fromRGB(60,150,255),  Glow=Color3.fromRGB(120,190,255), BarSize=0.30, DuckSpeed=0.30, Retarget=1.4,  Jitter=0.10, Gain=0.42, Drain=0.20, Stages=1, TimeLimit=24, BurstChance=0,    Pattern="dart",    XP=30,    Coins=60,     StatMult=1.8},
	{Name="Epic",        Index=4,  OneIn=35,      Color=Color3.fromRGB(175,80,255),  Glow=Color3.fromRGB(210,150,255), BarSize=0.26, DuckSpeed=0.4, Retarget=1.0,  Jitter=0.30, Gain=0.38, Drain=0.22, Stages=1, TimeLimit=26, BurstChance=0,    Pattern="zigzag",  XP=80,    Coins=160,    StatMult=2.5},
	{Name="Legendary",   Index=5,  OneIn=150,     Color=Color3.fromRGB(255,190,30),  Glow=Color3.fromRGB(255,230,120), BarSize=0.22, DuckSpeed=0.46, Retarget=0.8,  Jitter=0.35, Gain=0.36, Drain=0.25, Stages=1, TimeLimit=28, BurstChance=0.15, Pattern="zigzag",  XP=220,   Coins=450,    StatMult=3.6, Announce="server"},
	{Name="Mythic",      Index=6,  OneIn=750,    Color=Color3.fromRGB(255,60,90),   Glow=Color3.fromRGB(255,140,160), BarSize=0.18, DuckSpeed=0.57, Retarget=0.6,  Jitter=0.45, Gain=0.34, Drain=0.28, Stages=1, TimeLimit=30, BurstChance=0.2, Pattern="dart",    XP=600,   Coins=1000,   StatMult=5.2, Announce="server"},
	{Name="Divine",      Index=7,  OneIn=3500,    Color=Color3.fromRGB(255,250,190), Glow=Color3.fromRGB(255,255,230), BarSize=0.16, DuckSpeed=0.68, Retarget=0.5,  Jitter=0.50, Gain=0.33, Drain=0.3, Stages=1, TimeLimit=32, BurstChance=0.22, Pattern="wave",    XP=1500,  Coins=3000,   StatMult=7.5, Announce="server"},
	{Name="Celestial",   Index=8,  OneIn=15000,   Color=Color3.fromRGB(110,230,255), Glow=Color3.fromRGB(190,245,255), BarSize=0.15, DuckSpeed=0.76, Retarget=0.45, Jitter=0.55, Gain=0.33, Drain=0.31, Stages=2, TimeLimit=40, BurstChance=0.25, Pattern="wave",    XP=4000,  Coins=9000,   StatMult=10.5, Announce="global"},
	{Name="Secret",      Index=9,  OneIn=60000,  Color=Color3.fromRGB(30,30,30),    Glow=Color3.fromRGB(255,60,200),  BarSize=0.13, DuckSpeed=0.92, Retarget=0.40, Jitter=0.65, Gain=0.32, Drain=0.36, Stages=2, TimeLimit=45, BurstChance=0.28, Pattern="teleport",XP=12000, Coins=30000,  StatMult=15, Announce="global"},
	{Name="Transcendent",Index=10, OneIn=300000,  Color=Color3.fromRGB(255,255,255), Glow=Color3.fromRGB(255,120,255), BarSize=0.11, DuckSpeed=1.06, Retarget=0.32, Jitter=0.80, Gain=0.31, Drain=0.4, Stages=3, TimeLimit=60, BurstChance=0.3, Pattern="chaos",   XP=40000, Coins=120000, StatMult=22, Announce="global"},
}

Rarity.List = T
Rarity.ByName = {} :: {[string]: Tier}
for _, t in T do Rarity.ByName[t.Name] = t end
Rarity.MAX_LUCK = 2500 -- hard server clamp on total luck multiplier

-- Rolls a tier index. luck multiplies the chance of every tier above Common.
-- worldBoost multiplies chances of Epic+ (later worlds have better odds).
-- highBoost multiplies chances of Celestial+ (Secret Hunter skill).
function Rarity.Roll(rng: Random, luck: number, worldBoost: number, highBoost: number?): number
	luck = math.clamp(luck, 1, Rarity.MAX_LUCK)
	local hb = math.clamp(highBoost or 1, 1, 10)
	for i = #T, 2, -1 do
		local t = T[i]
		local mult = luck * (if i >= 4 then worldBoost else 1) * (if i >= 8 then hb else 1)
		local chance = math.min(mult / t.OneIn, 0.5)
		-- the cap keeps cheap tiers from swallowing all rolls at very high luck
		if i <= 3 then chance = math.min(chance, 0.35) end
		if rng:NextNumber() < chance then return i end
	end
	return 1
end

-- Gradient used for UI text/frames per tier.
function Rarity.Gradient(index: number): ColorSequence
	local t = T[index]
	if index == 10 then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,90,90)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,220,90)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90,255,140)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90,200,255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(180,100,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,110,220)),
		})
	elseif index == 9 then
		return ColorSequence.new(Color3.fromRGB(60,0,60), Color3.fromRGB(255,60,200))
	end
	return ColorSequence.new(t.Glow, t.Color)
end

return Rarity
