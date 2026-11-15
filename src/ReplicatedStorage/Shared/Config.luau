-- Game configuration: rods, bosses, skills, rebirth, quests, achievements, daily rewards, PvP.
local Config = {}

----------------------------------------------------------------- RODS
-- Catching nets (kept as Config.Rods / d.rod for save compatibility). See Stats.Net for derived values.
-- Luck: rare-duck spawn luck | Bar: bigger net hoop | Hook: duck swim speed mult (lower = calmer ducks)
-- Bite: swing recovery (lower = faster swings) | Special: net perk | Gain/Drain: unused (legacy)
Config.Rods = {
	{Id=1,  Name="Wooden Net",       Cost=0,          Rebirth=0,  Luck=1.0, Bar=0.00, Gain=1.00, Drain=1.00, Hook=1.00, Bite=3.4, Special=nil,          Color=Color3.fromRGB(150,100,55),  Tip=Color3.fromRGB(255,80,80),   Mat="Wood"},
	{Id=2,  Name="Plastic Net",      Cost=750,        Rebirth=0,  Luck=1.2, Bar=0.02, Gain=1.05, Drain=0.95, Hook=0.97, Bite=3.1, Special=nil,          Color=Color3.fromRGB(80,190,255),  Tip=Color3.fromRGB(255,220,60),  Mat="SmoothPlastic"},
	{Id=3,  Name="Iron Net",         Cost=6000,       Rebirth=0,  Luck=1.5, Bar=0.03, Gain=1.10, Drain=0.90, Hook=0.94, Bite=2.9, Special="sturdy",     Color=Color3.fromRGB(150,155,165), Tip=Color3.fromRGB(220,220,230), Mat="Metal"},
	{Id=4,  Name="Golden Net",       Cost=40000,      Rebirth=0,  Luck=2.0, Bar=0.04, Gain=1.15, Drain=0.85, Hook=0.90, Bite=2.6, Special="midas",      Color=Color3.fromRGB(255,200,50),  Tip=Color3.fromRGB(255,240,150), Mat="Foil"},
	{Id=5,  Name="Diamond Net",      Cost=250000,     Rebirth=0,  Luck=2.8, Bar=0.05, Gain=1.20, Drain=0.80, Hook=0.86, Bite=2.3, Special="secondwind", Color=Color3.fromRGB(170,240,255), Tip=Color3.fromRGB(255,255,255), Mat="Glass"},
	{Id=6,  Name="Crystal Net",      Cost=1500000,    Rebirth=1,  Luck=3.8, Bar=0.06, Gain=1.25, Drain=0.75, Hook=0.82, Bite=2.1, Special="steady",     Color=Color3.fromRGB(255,130,230), Tip=Color3.fromRGB(200,255,255), Mat="Glass"},
	{Id=7,  Name="Mythic Net",       Cost=8000000,    Rebirth=2,  Luck=5.0, Bar=0.07, Gain=1.30, Drain=0.70, Hook=0.78, Bite=1.9, Special="magnet",     Color=Color3.fromRGB(255,60,90),   Tip=Color3.fromRGB(255,200,90),  Mat="Neon"},
	{Id=8,  Name="Divine Net",       Cost=50000000,   Rebirth=4,  Luck=7.0, Bar=0.08, Gain=1.35, Drain=0.65, Hook=0.74, Bite=1.7, Special="autoreel",   Color=Color3.fromRGB(255,250,200), Tip=Color3.fromRGB(255,220,90),  Mat="Neon"},
	{Id=9,  Name="Cosmic Net",       Cost=400000000,  Rebirth=6,  Luck=10,  Bar=0.09, Gain=1.40, Drain=0.60, Hook=0.70, Bite=1.5, Special="timewarp",   Color=Color3.fromRGB(90,40,200),   Tip=Color3.fromRGB(120,240,255), Mat="Neon"},
	{Id=10, Name="Transcendent Net", Cost=3000000000, Rebirth=10, Luck=15,  Bar=0.10, Gain=1.50, Drain=0.55, Hook=0.65, Bite=1.2, Special="transcend",  Color=Color3.fromRGB(255,255,255), Tip=Color3.fromRGB(255,120,255), Mat="Neon"},
}
Config.RodSpecials = {
	sturdy     = "Wide Rim: the net hoop is 15% bigger.",
	midas      = "Midas Touch: +25% coins from every catch.",
	secondwind = "Quick Recovery: missed swings recover twice as fast.",
	steady     = "Long Handle: +2 studs of reach.",
	magnet     = "Magnet Net: grabs ducks 30% outside the hoop.",
	autoreel   = "Duck Lure: 2 extra ducks swim in your pond.",
	timewarp   = "Time Warp: every duck swims 15% slower.",
	transcend  = "Transcendence: Long Handle + Quick Recovery + Magnet Net + Duck Lure.",
}

----------------------------------------------------------------- BOSSES
-- Attack types: single, aoe, burn, stun, heal, enrage, shield, drain
Config.Bosses = {
	{Id=1, Name="Giant Slime",            World=1, HP=1200,    Atk=27,   Def=3,   Spd=8,  Element="Nature", Color=Color3.fromRGB(110,255,100),
	 Attacks={{Name="Goo Slam",Type="single",Power=1.0},{Name="Slime Rain",Type="aoe",Power=0.55},{Name="Absorb",Type="heal",Power=0.08}},
	 Coins=400, Gems=5, XP=150, Essence=1, DropChance=0.08, RodReward=nil},
	{Id=2, Name="Pirate Captain",         World=2, HP=5100,   Atk=79,   Def=6,   Spd=12, Element="Water", Color=Color3.fromRGB(150,90,50),
	 Attacks={{Name="Cutlass Slash",Type="single",Power=1.0},{Name="Cannon Barrage",Type="aoe",Power=0.6},{Name="Rum Break",Type="heal",Power=0.07}},
	 Coins=1500, Gems=8, XP=450, Essence=2, DropChance=0.07, RodReward=3},
	{Id=3, Name="Ice Titan",              World=3, HP=12100,   Atk=135,   Def=14,  Spd=9,  Element="Ice", Color=Color3.fromRGB(150,220,255),
	 Attacks={{Name="Glacier Fist",Type="single",Power=1.1},{Name="Blizzard",Type="aoe",Power=0.55},{Name="Deep Freeze",Type="stun",Power=0.7},{Name="Ice Armor",Type="shield",Power=0}},
	 Coins=6000, Gems=12, XP=1200, Essence=3, DropChance=0.06, RodReward=nil},
	{Id=4, Name="Fire Dragon",            World=4, HP=20600,  Atk=213,  Def=24,  Spd=14, Element="Fire", Color=Color3.fromRGB(220,50,30),
	 Attacks={{Name="Claw Swipe",Type="single",Power=1.0},{Name="Dragon Fire",Type="burn",Power=0.7},{Name="Inferno Wave",Type="aoe",Power=0.6},{Name="Rage",Type="enrage",Power=0}},
	 Coins=25000, Gems=18, XP=3200, Essence=4, DropChance=0.05, RodReward=4},
	{Id=5, Name="Shadow Monster",         World=5, HP=62500,  Atk=521,  Def=40,  Spd=16, Element="Shadow", Color=Color3.fromRGB(40,20,60),
	 Attacks={{Name="Shadow Claw",Type="single",Power=1.1},{Name="Nightmare",Type="stun",Power=0.6},{Name="Soul Drain",Type="drain",Power=0.9},{Name="Dark Wave",Type="aoe",Power=0.55}},
	 Coins=90000, Gems=25, XP=8000, Essence=5, DropChance=0.05, RodReward=nil},
	{Id=6, Name="Golden Guardian",        World=6, HP=87100,  Atk=694,  Def=70,  Spd=12, Element="Light", Color=Color3.fromRGB(255,200,60),
	 Attacks={{Name="Judgement Spear",Type="single",Power=1.15},{Name="Radiant Burst",Type="aoe",Power=0.6},{Name="Golden Aegis",Type="shield",Power=0},{Name="Restore",Type="heal",Power=0.06}},
	 Coins=300000, Gems=35, XP=18000, Essence=6, DropChance=0.045, RodReward=5},
	{Id=7, Name="Demon King",             World=6, HP=133600,  Atk=985,  Def=90,  Spd=17, Element="Fire", Color=Color3.fromRGB(160,0,20),
	 Attacks={{Name="Hellblade",Type="single",Power=1.2},{Name="Hellfire",Type="burn",Power=0.75},{Name="Demonic Fury",Type="enrage",Power=0},{Name="Soul Feast",Type="drain",Power=1.0}},
	 Coins=700000, Gems=50, XP=35000, Essence=8, DropChance=0.04, RodReward=nil},
	{Id=8, Name="Cosmic Beast",           World=7, HP=270700, Atk=1600,  Def=140, Spd=18, Element="Cosmic", Color=Color3.fromRGB(110,60,230),
	 Attacks={{Name="Star Bite",Type="single",Power=1.1},{Name="Meteor Storm",Type="aoe",Power=0.65},{Name="Gravity Lock",Type="stun",Power=0.7},{Name="Nebula Mend",Type="heal",Power=0.05}},
	 Coins=2500000, Gems=75, XP=80000, Essence=10, DropChance=0.035, RodReward=nil},
	{Id=9, Name="Void Destroyer",         World=8, HP=733600, Atk=3483, Def=230, Spd=20, Element="Void", Color=Color3.fromRGB(30,0,50),
	 Attacks={{Name="Null Beam",Type="single",Power=1.2},{Name="Collapse",Type="aoe",Power=0.7},{Name="Erase",Type="drain",Power=1.0},{Name="Void Rage",Type="enrage",Power=0}},
	 Coins=9000000, Gems=110, XP=200000, Essence=14, DropChance=0.03, RodReward=nil},
	{Id=10, Name="Transcendent Duck King", World=8, HP=870100, Atk=3677, Def=360, Spd=24, Element="Cosmic", Color=Color3.fromRGB(255,240,120),
	 Attacks={{Name="Royal Quack",Type="single",Power=1.25},{Name="Transcendent Wave",Type="aoe",Power=0.75},{Name="Crown of Ages",Type="shield",Power=0},{Name="Divine Mend",Type="heal",Power=0.05},{Name="Ascend",Type="enrage",Power=0}},
	 Coins=30000000, Gems=200, XP=500000, Essence=20, DropChance=0.02, RodReward=nil},
}
Config.BOSS_COOLDOWN = 20 -- seconds between boss attempts

----------------------------------------------------------------- SKILLS
-- Each skill: max level, effect per level. Cost per level = 1 + floor(level/3) skill points.
Config.SkillTrees = {
	{Key="Fishing", Color=Color3.fromRGB(60,170,255), Skills={
		{Key="fastCatch", Name="Quick Swing",    Max=10, Per=0.04,  Desc="Swing your net %d%% faster."},
		{Key="fishLuck",  Name="Lucky Lure",     Max=10, Per=0.05,  Desc="+%d%% duck spawn luck."},
		{Key="window",    Name="Wide Net",       Max=10, Per=0.03,  Desc="Net hoop %d%% bigger."},
		{Key="noEscape",  Name="Calm Waters",    Max=10, Per=0.025, Desc="Ducks swim %d%% slower."},
		{Key="rareFind",  Name="Rare Finder",    Max=10, Per=0.04,  Desc="+%d%% Epic+ duck chance."},
	}},
	{Key="Combat", Color=Color3.fromRGB(255,90,90), Skills={
		{Key="atk",     Name="Sharp Beaks",    Max=10, Per=0.04, Desc="+%d%% duck attack."},
		{Key="hp",      Name="Thick Rubber",   Max=10, Per=0.04, Desc="+%d%% duck health."},
		{Key="crit",    Name="Critical Quack", Max=10, Per=0.01, Desc="+%d%% critical hit chance."},
		{Key="def",     Name="Duck Armor",     Max=10, Per=0.04, Desc="+%d%% duck defense."},
		{Key="special", Name="Super Splash",   Max=10, Per=0.06, Desc="+%d%% special ability damage."},
	}},
	{Key="Luck", Color=Color3.fromRGB(110,230,110), Skills={
		{Key="luck",      Name="Four-Leaf Feather", Max=10, Per=0.06, Desc="+%d%% overall luck."},
		{Key="bossDrop",  Name="Treasure Sense",    Max=10, Per=0.08, Desc="+%d%% boss duck drop chance."},
		{Key="secret",    Name="Secret Hunter",     Max=10, Per=0.10, Desc="+%d%% Celestial/Secret/Transcendent chance."},
		{Key="rewards",   Name="Golden Touch",      Max=10, Per=0.05, Desc="+%d%% coins and XP."},
	}},
}
Config.SkillByKey = {}
for _, tree in Config.SkillTrees do
	for _, s in tree.Skills do s.Tree = tree.Key; Config.SkillByKey[s.Key] = s end
end
function Config.SkillCost(level: number): number return 1 + math.floor(level / 3) end

----------------------------------------------------------------- LEVELING
function Config.XPForLevel(level: number): number return math.floor(60 * level ^ 1.55) end
Config.MAX_LEVEL = 250

----------------------------------------------------------------- REBIRTH
function Config.RebirthRequirement(rebirths: number)
	return {Coins = math.floor(60000 * 4.5 ^ rebirths), Level = 12 + rebirths * 6}
end
function Config.RebirthBonuses(rebirths: number)
	return {Luck = 1 + rebirths * 0.25, Damage = 1 + rebirths * 0.10, FishSpeed = 1 + rebirths * 0.05, Coins = 1 + rebirths * 0.15}
end
function Config.RebirthReward(nextRebirth: number)
	return {Gems = 25 * nextRebirth, SkillPoints = 2}
end

----------------------------------------------------------------- QUESTS
-- Goal types: catch, catchRarity (Min), boss, pvpWin, levelUp, coins
Config.QuestTemplates = {
	{Type="catch",       Base=10, Text="Catch %d ducks",                        Coins=200,  Gems=2},
	{Type="catch",       Base=25, Text="Catch %d ducks",                        Coins=500,  Gems=4},
	{Type="catchRarity", Base=5,  Min=3, Text="Catch %d Rare or better ducks",   Coins=600,  Gems=5},
	{Type="catchRarity", Base=2,  Min=4, Text="Catch %d Epic or better ducks",   Coins=1000, Gems=8},
	{Type="catchRarity", Base=1,  Min=5, Text="Catch a Legendary or better duck", Coins=2500, Gems=15},
	{Type="boss",        Base=1,  Text="Defeat %d boss",                         Coins=800,  Gems=6},
	{Type="boss",        Base=3,  Text="Defeat %d bosses",                       Coins=2000, Gems=12},
	{Type="pvpWin",      Base=1,  Text="Win %d PvP battle",                      Coins=700,  Gems=8},
	{Type="levelUp",     Base=5,  Text="Train your ducks %d times",              Coins=400,  Gems=4},
	{Type="coins",       Base=2000, Text="Earn %d coins",                        Coins=500,  Gems=3},
}
Config.ACTIVE_QUESTS = 3

Config.Achievements = {
	{Key="catch1",    Name="First Splash",      Desc="Catch your first duck",      Stat="caught", Goal=1,    Gems=5},
	{Key="catch100",  Name="Duck Wrangler",     Desc="Catch 100 ducks",            Stat="caught", Goal=100,  Gems=25},
	{Key="catch1000", Name="Pond Master",       Desc="Catch 1,000 ducks",          Stat="caught", Goal=1000, Gems=100},
	{Key="dex25",     Name="Collector",         Desc="Discover 25 duck species",   Stat="species", Goal=25,  Gems=20},
	{Key="dex100",    Name="Curator",           Desc="Discover 100 duck species",  Stat="species", Goal=100, Gems=75},
	{Key="dex200",    Name="Duckopedia",        Desc="Discover 200 duck species",  Stat="species", Goal=200, Gems=300},
	{Key="leg",       Name="Legend Hunter",     Desc="Catch a Legendary duck",     Stat="best",   Goal=5,    Gems=20},
	{Key="myth",      Name="Myth Buster",       Desc="Catch a Mythic duck",        Stat="best",   Goal=6,    Gems=50},
	{Key="secret",    Name="Keeper of Secrets", Desc="Catch a Secret duck",        Stat="best",   Goal=9,    Gems=250},
	{Key="trans",     Name="Beyond Rarity",     Desc="Catch a Transcendent duck",  Stat="best",   Goal=10,   Gems=1000},
	{Key="boss1",     Name="Slime Slayer",      Desc="Defeat any boss",            Stat="bosses", Goal=1,    Gems=10},
	{Key="boss50",    Name="Boss Breaker",      Desc="Defeat 50 bosses",           Stat="bosses", Goal=50,   Gems=80},
	{Key="king",      Name="Kingslayer",        Desc="Defeat the Transcendent Duck King", Stat="king", Goal=1, Gems=500},
	{Key="reb1",      Name="Born Again",        Desc="Rebirth once",               Stat="rebirths", Goal=1,  Gems=30},
	{Key="reb10",     Name="Eternal Cycle",     Desc="Rebirth 10 times",           Stat="rebirths", Goal=10, Gems=300},
	{Key="pvp10",     Name="Duelist",           Desc="Win 10 PvP battles",         Stat="pvpWins", Goal=10,  Gems=40},
	{Key="pvp100",    Name="Arena Legend",      Desc="Win 100 PvP battles",        Stat="pvpWins", Goal=100, Gems=250},
}

----------------------------------------------------------------- DAILY REWARDS (7-day streak)
Config.Daily = {
	{Coins=250},{Coins=600},{Gems=10},{Coins=2000},{Gems=20},{Coins=6000},{Gems=50, Coins=10000},
}
Config.DAILY_COOLDOWN = 20 * 3600
Config.DAILY_RESET = 48 * 3600

----------------------------------------------------------------- PVP
Config.PvPTitles = {
	{Min=0,    Name="Bronze Quacker",  Color=Color3.fromRGB(205,127,50)},
	{Min=1100, Name="Silver Splasher", Color=Color3.fromRGB(200,210,220)},
	{Min=1250, Name="Gold Paddler",    Color=Color3.fromRGB(255,205,60)},
	{Min=1450, Name="Platinum Drake",  Color=Color3.fromRGB(120,230,220)},
	{Min=1700, Name="Diamond Mallard", Color=Color3.fromRGB(150,200,255)},
	{Min=2000, Name="Duck Champion",   Color=Color3.fromRGB(255,90,220)},
}
function Config.PvPTitle(rating: number)
	local best = Config.PvPTitles[1]
	for _, t in Config.PvPTitles do if rating >= t.Min then best = t end end
	return best
end
function Config.SeasonId(): string return os.date("!%Y-%m") end
function Config.SeasonReward(peak: number): number
	return math.floor(math.max(0, peak - 900) / 10) * 2
end
Config.PVP_START_RATING = 1000

----------------------------------------------------------------- MISC
Config.TEAM_SIZE = 3
Config.MAX_DUCKS = 600
Config.CAST_RANGE = 26     -- studs from pool edge
Config.EVOLVE_COPIES = 2   -- extra copies consumed per star
Config.EVOLVE_ESSENCE = {3, 8, 20}
Config.MAX_STARS = 3

return Config
