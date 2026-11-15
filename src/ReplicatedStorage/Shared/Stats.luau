-- Derived player stats (luck, bite time, combat multipliers). Pure functions of profile data,
-- shared so the client can display exactly what the server uses.
local Config = require(script.Parent.Config)
local Rarity = require(script.Parent.Rarity)
local WorldData = require(script.Parent.WorldData)
local DuckData = require(script.Parent.DuckData)

local Stats = {}

function Stats.Skill(d, key: string): number
	local s = Config.SkillByKey[key]
	local lvl = d.skills[key] or 0
	return lvl * s.Per
end

function Stats.Rod(d)
	return Config.Rods[d.rod] or Config.Rods[1]
end

-- Server-wide luck event multiplier (replicated through workspace attributes)
function Stats.EventMult(): number
	local m = workspace:GetAttribute("LuckEventMult") or 1
	local e = workspace:GetAttribute("LuckEventEnd") or 0
	if m > 1 and e > workspace:GetServerTimeNow() then return m end
	return 1
end

-- Worlds whose 25 fishable species are all discovered (each gives +10% luck)
function Stats.CompletedWorlds(d): number
	local n = 0
	for w = 1, #WorldData.List do
		local all = true
		for r = 1, #Rarity.List do
			for _, id in DuckData.Pools[w][r] do
				if not d.discovered[tostring(id)] then all = false break end
			end
			if not all then break end
		end
		if all then n += 1 end
	end
	return n
end

function Stats.Luck(d): number
	local rod = Stats.Rod(d)
	local rb = Config.RebirthBonuses(d.rebirths)
	local luck = rod.Luck * (1 + Stats.Skill(d, "fishLuck")) * (1 + Stats.Skill(d, "luck")) * rb.Luck
		* (1 + 0.1 * Stats.CompletedWorlds(d)) * Stats.EventMult()
	return math.clamp(luck, 1, Rarity.MAX_LUCK)
end

function Stats.WorldBoost(d, world: number): number
	return WorldData.List[world].Boost * (1 + Stats.Skill(d, "rareFind"))
end

function Stats.HighBoost(d): number
	return 1 + Stats.Skill(d, "secret")
end

function Stats.BiteTime(d): number
	local rod = Stats.Rod(d)
	local rb = Config.RebirthBonuses(d.rebirths)
	return math.max(0.8, rod.Bite / ((1 + Stats.Skill(d, "fastCatch")) * rb.FishSpeed))
end

-- Catching net: reach (studs from you), hoop radius, swing recovery, duck calm (speed mult), duck count
function Stats.Net(d)
	local rod = Stats.Rod(d)
	local sp = rod.Special
	local all = sp == "transcend"
	local rb = Config.RebirthBonuses(d.rebirths)
	local radius = (1.7 + rod.Bar * 10) * (1 + Stats.Skill(d, "window")) * (if sp == "sturdy" then 1.15 else 1)
	local grab = radius * (if sp == "magnet" or all then 1.3 else 1)
	local cooldown = math.max(0.32, 1.15 * (rod.Bite / 3.4) / ((1 + Stats.Skill(d, "fastCatch")) * rb.FishSpeed))
	return {
		Reach = 7 + (rod.Id - 1) * 0.4 + (if sp == "steady" or all then 2 else 0), -- plus a 5-stud pounce
		Radius = radius, -- visual hoop size
		Grab = grab, -- catch distance
		Cooldown = cooldown,
		MissCooldown = cooldown * (if sp == "secondwind" or all then 0.5 else 1),
		Calm = rod.Hook * (if sp == "timewarp" then 0.85 else 1) * (1 - math.min(0.4, Stats.Skill(d, "noEscape"))),
		Extra = if sp == "autoreel" or all then 2 else 0,
	}
end

function Stats.CatchMods(d)
	return {
		WindowBonus = Stats.Skill(d, "window"),
		EscapeReduction = math.min(0.5, Stats.Skill(d, "noEscape")),
	}
end

function Stats.RewardMult(d): number
	return (1 + Stats.Skill(d, "rewards")) * Config.RebirthBonuses(d.rebirths).Coins
end

-- Odds (1 in N) for display, after luck & world boost.
function Stats.Odds(d, world: number)
	local luck = Stats.Luck(d)
	local wb = Stats.WorldBoost(d, world)
	local hb = Stats.HighBoost(d)
	local out = {}
	for i, t in Rarity.List do
		if i == 1 then out[i] = 1 else
			local mult = luck * (if i >= 4 then wb else 1) * (if i >= 8 then hb else 1)
			out[i] = math.max(1, t.OneIn / mult)
		end
	end
	return out
end

-- Battle stats for an owned duck record {id, l, s}
function Stats.DuckBattle(d, rec)
	local duck = DuckData.List[rec.id]
	local base = DuckData.StatsAt(duck, rec.l)
	local star = 1 + 0.25 * (rec.s or 0)
	local rb = Config.RebirthBonuses(d.rebirths)
	return {
		Attack = math.floor(base.Attack * star * (1 + Stats.Skill(d, "atk")) * rb.Damage),
		Health = math.floor(base.Health * star * (1 + Stats.Skill(d, "hp"))),
		Defense = math.floor(base.Defense * star * (1 + Stats.Skill(d, "def"))),
		Speed = base.Speed,
		Crit = math.min(0.75, base.Crit + Stats.Skill(d, "crit")),
		SpecialMult = 1 + Stats.Skill(d, "special"),
	}
end

function Stats.DuckPower(d, rec): number
	local s = Stats.DuckBattle(d, rec)
	return math.floor(s.Attack * 2 + s.Health * 0.5 + s.Defense * 1.5 + s.Speed)
end

function Stats.TeamPower(d): number
	local total = 0
	for _, uid in d.team do
		local rec = d.ducks[uid]
		if rec then total += Stats.DuckPower(d, rec) end
	end
	return total
end

return Stats
