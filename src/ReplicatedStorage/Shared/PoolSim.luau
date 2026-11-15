-- Pond simulation shared by server (authority) and client (rendering).
-- * Every world's pond has its own outline: r(theta) = R * (1 + sum amp*cos(k*theta + phase)).
--   The same numbers are used to model the ponds in Blender, so the art matches the maths.
-- * Duck paths are a pure function of their spawn record + server time and always stay inside the outline.
-- * The mom duck patrols the pond on a deterministic loop when she isn't chasing anyone.
-- Record: {u = uid, id = duckId, t0 = spawn server time, life = seconds, seed = int, sp = speed mult}
local WorldData = require(script.Parent.WorldData)
local DuckData = require(script.Parent.DuckData)

local Sim = {}

-- swim speed (studs/s) by rarity: worse ducks paddle, rare ducks race around
Sim.SPEED = {3.4, 4.8, 6.4, 8.4, 10.4, 12.6, 14.8, 17.2, 19.8, 22.8}
-- how long a duck stays before swimming off (rare ducks don't wait around)
Sim.LIFE = {95, 85, 75, 60, 45, 40, 34, 30, 26, 22}
-- speed wobble (darting) by rarity
Sim.JITTER = {0.14, 0.2, 0.28, 0.38, 0.46, 0.54, 0.6, 0.66, 0.72, 0.8}
-- chance a duck dodges a net that would have caught it
Sim.DODGE = {0, 0, 0.08, 0.14, 0.2, 0.26, 0.32, 0.38, 0.44, 0.5}
Sim.DUCK_SCALE = 0.72
-- Hunt & pounce: ducks hear you moving fast within FEAR studs (sneaking is silent except to skittish rare ducks
-- that still notice you within SNEAK studs). Panicked ducks swim off faster for a few seconds.
Sim.FEAR = {4.5, 5.5, 6.5, 8, 9.5, 11, 12.5, 14, 15, 16}
Sim.SNEAK = {0, 0, 0, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5}
Sim.PANIC_SPEED = {1.5, 1.55, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2, 2.3}
Sim.PANIC_TIME = 3
Sim.LOUD_SPEED = 7.5 -- horizontal speed above which you count as noisy
Sim.SNEAK_SPEED = 6 -- walk speed while sneaking in the water
Sim.LUNGE = 5 -- studs a pounce carries you
-- net fight (timing ring) for Rare+ ducks
Sim.FIGHT_ROUNDS = {0, 0, 1, 1, 2, 2, 2, 3, 3, 4}
Sim.FIGHT_ZONE = {90, 90, 80, 70, 60, 52, 46, 40, 34, 30} -- degrees of green on the dial
function Sim.FightPeriod(r: number): number return 1.25 - r * 0.045 end -- seconds per needle turn
Sim.WATER_Y = 1.4 -- water surface height above the island ground (players wade knee/waist deep)

-- mom duck
Sim.MOM_SCALE = 2.7
Sim.MOM_CATCH = 4.2 -- studs between mom and player that counts as caught
Sim.MOM_REACT = 0.55 -- seconds before she starts chasing
function Sim.MomSpeed(rarity: number): number
	return 13 + (rarity - 1) * 0.35 -- a bit faster than a wading player (12)
end
Sim.WADE_SPEED = 12 -- player walk speed while in the water (normal is 16)
Sim.ESCAPE_MARGIN = 1.6 -- how far past the edge you must be to count as out of the water

-- outline terms per world: {k, amplitude, phase}
Sim.SHAPES = {
	[1] = {R = 56, terms = {{1, 0.10, 0.4}, {2, 0.20, 1.2}, {3, 0.06, 0.2}}},               -- carnival: bean / kidney
	[2] = {R = 48, terms = {{3, 0.15, 0.9}, {5, 0.06, 2.0}, {1, 0.06, 4.0}}},               -- tropical: lagoon with bays
	[3] = {R = 48, terms = {{6, 0.07, 0.0}, {11, 0.045, 1.1}, {17, 0.03, 2.3}}},            -- frozen: jagged ice edge
	[4] = {R = 48, terms = {{4, 0.20, 0.3}, {8, 0.05, 1.0}, {1, 0.05, 2.0}}},               -- lava: four-armed crack
	[5] = {R = 48, terms = {{2, 0.24, 0.6}, {3, 0.11, 2.4}, {5, 0.05, 0.4}}},               -- swamp: long lumpy bog
	[6] = {R = 48, terms = {{5, 0.22, 1.57}, {10, 0.04, 0.0}}},                              -- crystal: five-point star
	[7] = {R = 48, terms = {{9, 0.07, 0.0}, {1, 0.08, 1.0}, {2, 0.06, 3.0}}},                -- celestial: cloud scallops
	[8] = {R = 48, terms = {{3, 0.17, 0.0}, {7, 0.07, 1.4}, {2, 0.05, 2.2}}},                -- void: warped tri-rift
}

function Sim.Center(world: number): Vector3
	local w = WorldData.List[world]
	local c = w.Origin + WorldData.POOL_OFFSET
	return Vector3.new(c.X, w.Origin.Y + Sim.WATER_Y, c.Z)
end

-- distance from the pond centre to the shoreline in direction theta (theta in the XZ plane, x = cos, z = sin)
function Sim.EdgeR(world: number, theta: number): number
	local s = Sim.SHAPES[world] or Sim.SHAPES[2]
	local f = 1
	for _, t in s.terms do f += t[2] * math.cos(t[1] * theta + t[3]) end
	return s.R * f
end

-- outer bounding radius (for culling / "near the pond" checks)
function Sim.Radius(world: number): number
	local s = Sim.SHAPES[world] or Sim.SHAPES[2]
	local f = 1
	for _, t in s.terms do f += math.abs(t[2]) end
	return s.R * f
end

-- how far inside (+) or outside (-) the shoreline a position is, in studs
function Sim.EdgeDistance(world: number, pos: Vector3): number
	local c = Sim.Center(world)
	local dx, dz = pos.X - c.X, pos.Z - c.Z
	local d = math.sqrt(dx * dx + dz * dz)
	return Sim.EdgeR(world, math.atan2(dz, dx)) - d
end

function Sim.InPool(world: number, pos: Vector3, margin: number?): boolean
	return Sim.EdgeDistance(world, pos) >= -(margin or 0)
end

-- clamp a point to stay at least `inset` studs inside the shore
function Sim.Clamp(world: number, pos: Vector3, inset: number): Vector3
	local c = Sim.Center(world)
	local dx, dz = pos.X - c.X, pos.Z - c.Z
	local d = math.sqrt(dx * dx + dz * dz)
	if d < 1e-3 then return Vector3.new(c.X, c.Y, c.Z) end
	local th = math.atan2(dz, dx)
	local maxD = math.max(0, Sim.EdgeR(world, th) - inset)
	if d <= maxD then return Vector3.new(pos.X, c.Y, pos.Z) end
	return Vector3.new(c.X + dx / d * maxD, c.Y, c.Z + dz / d * maxD)
end

local cache = setmetatable({}, {__mode = "k"})

local function params(rec, world)
	local p = cache[rec]
	if p then return p end
	local duck = DuckData.List[rec.id]
	local r = duck and duck.Rarity or 1
	local s = Sim.SHAPES[world] or Sim.SHAPES[2]
	local rng = Random.new(rec.seed)
	-- normalised radius (fraction of the shoreline distance)
	local inner, outer = 0.14, 0.86
	local rc = rng:NextNumber(0.34, 0.68)
	local ra = math.min(rc - inner, outer - rc) * rng:NextNumber(0.6, 0.95)
	local v = Sim.SPEED[r] * (rec.sp or 1)
	local J = Sim.JITTER[r]
	local avgR = rc * s.R
	p = {
		C = Sim.Center(world), rc = rc, ra = ra,
		w = v / avgR, dir = rec.dir or (if rng:NextNumber() < 0.5 then -1 else 1),
		J = J, k = rng:NextNumber(0.7, 1.3) * (0.7 + r * 0.14),
		f2 = 0.42 * v / math.max(ra * s.R, 0.8), p2 = rng:NextNumber(0, 6.283),
		f3 = rng:NextNumber(0.2, 0.5), p3 = rng:NextNumber(0, 6.283),
		th0 = rec.th0 or rng:NextNumber(0, 6.283),
		blink = if r == 10 then 4.2 elseif r == 9 then 6 else nil,
		Rarity = r, Speed = v,
	}
	-- when a duck re-paths (panic/calm) it starts exactly where it was: blend from its old radius
	p.base0 = rc + ra * (0.75 * math.sin(p.p2) + 0.25 * math.sin(p.p3))
	p.rn0 = rec.rn0
	cache[rec] = p
	return p
end
Sim.Params = params
-- call after changing a record's path (dodges)
function Sim.Forget(rec)
	cache[rec] = nil
end

-- position (on the water surface) at server time t, plus the blink cycle index
function Sim.Pos(rec, world: number, t: number): (Vector3, number)
	local p = params(rec, world)
	local tau = math.max(0, t - rec.t0)
	local th = p.th0 + p.dir * (p.w * tau + p.w * p.J / p.k * (1 - math.cos(p.k * tau)))
	local blinkN = 0
	if p.blink then
		blinkN = math.floor(tau / p.blink)
		th += blinkN * 2.4
	end
	local rn = p.rc + p.ra * (0.75 * math.sin(p.f2 * tau + p.p2) + 0.25 * math.sin(p.f3 * p.f2 * tau + p.p3))
	if p.rn0 then rn += (p.rn0 - p.base0) * math.exp(-tau / 1.2) end
	rn = math.clamp(rn, 0.12, 0.88)
	local rad = rn * Sim.EdgeR(world, th)
	return Vector3.new(p.C.X + math.cos(th) * rad, p.C.Y, p.C.Z + math.sin(th) * rad), blinkN
end

-- current angle + normalised radius (for continuous re-paths)
function Sim.Polar(rec, world: number, t: number): (number, number)
	local pos = Sim.Pos(rec, world, t)
	local c = Sim.Center(world)
	local dx, dz = pos.X - c.X, pos.Z - c.Z
	local th = math.atan2(dz, dx)
	return th, math.sqrt(dx * dx + dz * dz) / math.max(Sim.EdgeR(world, th), 1)
end

-- heading as a CFrame facing the swim direction (ducks face -Z)
function Sim.CFrame(rec, world: number, t: number): (CFrame, number)
	local a, blinkN = Sim.Pos(rec, world, t)
	local b = Sim.Pos(rec, world, t + 0.05)
	local d = (b - a) * Vector3.new(1, 0, 1)
	if d.Magnitude < 1e-4 then return CFrame.new(a), blinkN end
	return CFrame.lookAt(a, a + d), blinkN
end

function Sim.Alive(rec, t: number): boolean
	return t >= rec.t0 and t < rec.t0 + rec.life
end

-- mom's calm patrol loop (same for server and client)
function Sim.MomPatrol(world: number, t: number): Vector3
	local c = Sim.Center(world)
	local th = t * 0.11 + world * 1.7
	local rn = 0.48 + 0.16 * math.sin(t * 0.23 + world)
	local rad = rn * Sim.EdgeR(world, th)
	return Vector3.new(c.X + math.cos(th) * rad, c.Y, c.Z + math.sin(th) * rad)
end

-- mom position while easing back from a chase to her patrol loop
Sim.MOM_RETURN_TIME = 3
function Sim.MomReturning(world: number, fromPos: Vector3, t0: number, t: number): (Vector3, boolean)
	local a = math.clamp((t - t0) / Sim.MOM_RETURN_TIME, 0, 1)
	a = a * a * (3 - 2 * a)
	return fromPos:Lerp(Sim.MomPatrol(world, t), a), a >= 1
end

return Sim
