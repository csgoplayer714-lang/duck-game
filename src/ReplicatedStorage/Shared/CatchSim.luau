--!strict
-- Deterministic catching minigame.
-- The client runs it live for display; the server replays the player's input toggles with the
-- same seed to decide whether the catch really succeeded (server-authoritative catching).
-- Duck movement only depends on the seed, never on input, so the RNG sequence always matches.
local CatchSim = {}
CatchSim.__index = CatchSim

CatchSim.DT = 1 / 60
CatchSim.MAX_TOGGLES = 4000

export type Params = {
	Seed: number, BarSize: number, DuckSpeed: number, Retarget: number, Jitter: number,
	Gain: number, Drain: number, Stages: number, TimeLimit: number, BurstChance: number,
	BurstPower: number, Pattern: string, Magnet: number, AutoReel: number,
	Steady: boolean, SecondWind: boolean,
}

local PATTERNS = {"dart", "zigzag", "teleport", "wave"}

function CatchSim.new(p: Params)
	local self = setmetatable({}, CatchSim)
	self.P = p
	self.Rng = Random.new(p.Seed)
	self.Tick = 0
	self.T = 0
	self.BarSize = p.BarSize
	self.BarPos = 0
	self.BarVel = 0
	self.Duck = 0.5
	self.Target = 0.5
	self.Timer = 0.6 -- grace before the duck starts moving
	self.SpeedMult = 1
	self.Progress = 0.3
	self.Stage = 1
	self.Burst = 0
	self.ZigUp = true
	self.WaveDir = 1
	self.SecondWindUsed = false
	self.Inside = false
	self.Status = "playing"
	self.Pattern = p.Pattern
	self.Teleported = false
	return self
end

function CatchSim:_retarget()
	local rng = self.Rng
	local pattern = self.Pattern
	if self.P.Pattern == "chaos" then
		pattern = PATTERNS[rng:NextInteger(1, #PATTERNS)]
		self.Pattern = pattern
	end
	if pattern == "drift" then
		self.Target = math.clamp(self.Duck + rng:NextNumber(-0.35, 0.35), 0.05, 0.95)
	elseif pattern == "zigzag" then
		self.ZigUp = not self.ZigUp
		self.Target = if self.ZigUp then rng:NextNumber(0.6, 0.95) else rng:NextNumber(0.05, 0.4)
	elseif pattern == "teleport" then
		if rng:NextNumber() < 0.35 then
			self.Duck = rng:NextNumber(0.08, 0.92)
			self.Teleported = true
		end
		self.Target = rng:NextNumber(0.05, 0.95)
	else -- dart / wave
		self.Target = rng:NextNumber(0.05, 0.95)
	end
	local base = self.P.Retarget
	self.Timer = base * rng:NextNumber(0.6, 1.4)
end

-- Advances one fixed tick. Returns status: playing | stage | success | escaped
function CatchSim:Step(holding: boolean): string
	if self.Status ~= "playing" and self.Status ~= "stage" then return self.Status end
	local p = self.P
	local dt = CatchSim.DT
	local rng = self.Rng
	self.Tick += 1
	self.T += dt
	self.Teleported = false

	-- player's catch bar (simple buoyancy physics)
	if holding then self.BarVel += 3.0 * dt else self.BarVel -= 2.6 * dt end
	self.BarVel = math.clamp(self.BarVel, -1.5, 1.5)
	self.BarPos += self.BarVel * dt
	local top = 1 - self.BarSize
	if self.BarPos < 0 then
		self.BarPos = 0
		self.BarVel = -self.BarVel * 0.3
	elseif self.BarPos > top then
		self.BarPos = top
		self.BarVel = 0
	end

	-- duck movement (input independent)
	self.Timer -= dt
	if self.Timer <= 0 then self:_retarget() end
	if p.Jitter > 0 and rng:NextNumber() < p.Jitter * dt * 1.5 then
		-- sudden direction change
		self.Target = if self.Target > self.Duck then rng:NextNumber(0.05, math.max(0.06, self.Duck)) else rng:NextNumber(math.min(0.94, self.Duck), 0.95)
	end
	if self.Tick % 60 == 0 and p.BurstChance > 0 and rng:NextNumber() < p.BurstChance then
		self.Burst = 0.7
		self.Target = if self.Duck > 0.5 then 0.04 else 0.96
	end
	local speed = p.DuckSpeed * self.SpeedMult
	if self.Burst > 0 then
		self.Burst -= dt
		speed *= 1.0 + p.BurstPower
	end
	if p.Steady and self.T < 2.5 then speed *= 0.5 end
	if self.Timer > 0 and self.T < 0.6 then speed = 0 end
	if self.Pattern == "wave" then
		-- sweeping sine-like motion using a triangle wave (no trig for determinism)
		self.Duck += self.WaveDir * speed * dt
		if self.Duck >= 0.95 then self.Duck = 0.95; self.WaveDir = -1
		elseif self.Duck <= 0.05 then self.Duck = 0.05; self.WaveDir = 1 end
		if math.abs(self.Duck - self.Target) < 0.04 then self.WaveDir = -self.WaveDir; self.Target = rng:NextNumber(0.05, 0.95) end
	else
		local diff = self.Target - self.Duck
		local stepMax = speed * dt
		if math.abs(diff) <= stepMax then self.Duck = self.Target else self.Duck += math.sign(diff) * stepMax end
	end
	self.Duck = math.clamp(self.Duck, 0, 1)

	-- overlap + progress
	local center = self.BarPos + self.BarSize / 2
	self.Inside = math.abs(self.Duck - center) <= self.BarSize / 2 + p.Magnet
	if self.Inside then
		self.Progress += p.Gain * dt
	else
		local drain = p.Drain * (if self.Burst > 0 then 1.5 else 1)
		self.Progress -= (drain - p.AutoReel) * dt
	end

	if self.Progress >= 1 then
		if self.Stage < p.Stages then
			self.Stage += 1
			self.Progress = 0.35
			self.SpeedMult *= 1.2
			self.BarSize = math.max(0.06, self.BarSize * 0.92)
			self.Status = "stage"
			return "stage"
		end
		self.Progress = 1
		self.Status = "success"
		return "success"
	end
	if self.Progress <= 0 then
		if p.SecondWind and not self.SecondWindUsed then
			self.SecondWindUsed = true
			self.Progress = 0.25
		else
			self.Progress = 0
			self.Status = "escaped"
			return "escaped"
		end
	end
	if self.T >= p.TimeLimit then
		self.Status = "escaped"
		return "escaped"
	end
	self.Status = "playing"
	return "playing"
end

-- Replays a list of tick numbers at which the hold state toggled. Returns final status and tick count.
function CatchSim.Replay(p: Params, toggles: {number}): (string, number)
	local sim = CatchSim.new(p)
	local holding = false
	local ti = 1
	local maxTicks = math.ceil(p.TimeLimit / CatchSim.DT) + 2
	for _ = 1, maxTicks do
		local nextTick = sim.Tick + 1
		while toggles[ti] and toggles[ti] <= nextTick do
			if toggles[ti] == nextTick then holding = not holding end
			ti += 1
		end
		local s = sim:Step(holding)
		if s == "success" or s == "escaped" then return s, sim.Tick end
	end
	return "escaped", sim.Tick
end

-- Builds minigame parameters from rarity tier, duck, rod and player modifiers.
-- mods: {WindowBonus, EscapeReduction (0..1), TimeLimitMult}
function CatchSim.BuildParams(seed: number, tier, duck, rod, mods): Params
	local special = rod.Special
	local tr = special == "transcend"
	local speed = tier.DuckSpeed * duck.CatchSpeedMult * rod.Hook
	local retarget = tier.Retarget
	if special == "timewarp" or tr then speed *= 0.85; retarget *= 1.15 end
	local p: Params = {
		Seed = seed,
		BarSize = math.clamp(tier.BarSize + rod.Bar + mods.WindowBonus, 0.08, 0.6),
		DuckSpeed = speed,
		Retarget = retarget,
		Jitter = tier.Jitter,
		Gain = tier.Gain * rod.Gain,
		Drain = tier.Drain * rod.Drain * (1 - mods.EscapeReduction),
		Stages = tier.Stages,
		TimeLimit = tier.TimeLimit,
		BurstChance = tier.BurstChance,
		BurstPower = if special == "sturdy" then 0.7 else 1.2,
		Pattern = tier.Pattern,
		Magnet = if special == "magnet" or tr then 0.03 else 0,
		AutoReel = if special == "autoreel" or tr then 0.05 else 0,
		Steady = special == "steady" or tr,
		SecondWind = special == "secondwind" or tr,
	}
	return p
end

return CatchSim
