-- Worlds: each has its own map region, pool, duck species, boss and odds boost.
local WorldData = {}

WorldData.List = {
	{Id=1, Name="Carnival Island",   Cost=0,          Rebirth=0, Boost=1.0, StatMult=1,    Origin=Vector3.new(0,0,0),
	 Water=Color3.fromRGB(40,140,235),  Ground=Color3.fromRGB(240,215,160), Accent=Color3.fromRGB(255,70,90),  Sky="day",    Boss=1},
	{Id=2, Name="Tropical Paradise", Cost=2500,       Rebirth=0, Boost=1.3, StatMult=1.8,  Origin=Vector3.new(700,0,0),
	 Water=Color3.fromRGB(30,220,210),  Ground=Color3.fromRGB(250,230,170), Accent=Color3.fromRGB(80,200,90),  Sky="day",    Boss=2},
	{Id=3, Name="Frozen Lake",       Cost=25000,      Rebirth=0, Boost=1.7, StatMult=3.2,  Origin=Vector3.new(1400,0,0),
	 Water=Color3.fromRGB(150,215,255), Ground=Color3.fromRGB(235,245,255), Accent=Color3.fromRGB(120,190,255), Sky="snow",   Boss=3},
	{Id=4, Name="Lava Pools",        Cost=200000,     Rebirth=1, Boost=2.2, StatMult=5.5,  Origin=Vector3.new(2100,0,0),
	 Water=Color3.fromRGB(255,110,20),  Ground=Color3.fromRGB(60,40,40),    Accent=Color3.fromRGB(255,60,20),  Sky="lava",   Boss=4},
	{Id=5, Name="Haunted Swamp",     Cost=1500000,    Rebirth=2, Boost=2.8, StatMult=9,    Origin=Vector3.new(0,0,700),
	 Water=Color3.fromRGB(70,110,60),   Ground=Color3.fromRGB(55,60,45),    Accent=Color3.fromRGB(170,90,255), Sky="night",  Boss=5},
	{Id=6, Name="Crystal Ocean",     Cost=10000000,   Rebirth=3, Boost=3.6, StatMult=15,   Origin=Vector3.new(700,0,700),
	 Water=Color3.fromRGB(60,120,255),  Ground=Color3.fromRGB(200,220,255), Accent=Color3.fromRGB(255,120,230), Sky="dusk",   Boss=6},
	{Id=7, Name="Celestial Lake",    Cost=80000000,   Rebirth=5, Boost=4.6, StatMult=26,   Origin=Vector3.new(1400,0,700),
	 Water=Color3.fromRGB(200,230,255), Ground=Color3.fromRGB(255,250,235), Accent=Color3.fromRGB(255,215,90), Sky="heaven", Boss=7},
	{Id=8, Name="Void Dimension",    Cost=750000000,  Rebirth=8, Boost=6.0, StatMult=45,   Origin=Vector3.new(2100,0,700),
	 Water=Color3.fromRGB(110,30,200),  Ground=Color3.fromRGB(20,10,35),    Accent=Color3.fromRGB(200,80,255), Sky="void",   Boss=8},
}

-- Boss ids available from each world's boss portal
WorldData.BossesByWorld = {
	[1]={1}, [2]={2}, [3]={3}, [4]={4}, [5]={5}, [6]={6,7}, [7]={8}, [8]={9,10},
}

function WorldData.Get(id: number)
	return WorldData.List[id]
end

-- Pond centre for a world (offset from the world origin) and island size
WorldData.POOL_OFFSET = Vector3.new(0, 0, -62)
WorldData.POOL_SIZE = Vector3.new(110, 0, 90) -- bounding box kept clear of decor
function WorldData.IslandRadius(id: number): number
	return if id == 1 then 220 else 170
end

return WorldData
