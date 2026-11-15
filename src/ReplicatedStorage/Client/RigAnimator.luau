-- Procedural animation for mesh rigs built by DuckModelBuilder / BossModelBuilder.
-- Rigs are Models with attribute Rig = "Duck" | "Boss" and Motor6D joints named J_<Part>.
-- Every rig in workspace or in the player's GUI viewports is picked up automatically.
-- Optional model attribute AnimStyle: "battle" (livelier). One-shots: Anim.Play(model, name).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Anim = {}

local rigs = {} -- [Model] = rec
local list = {} -- array of recs for iteration
local camera = workspace.CurrentCamera

local DUCK_RANGE = 95
local BOSS_RANGE = 320
local sin, cos, abs, clamp, pi = math.sin, math.cos, math.abs, math.clamp, math.pi
local CF, ANG = CFrame.new, CFrame.Angles
local IDENT = CFrame.identity

local function env(t, dur)
	-- smooth 0 -> 1 -> 0 bump
	if t <= 0 or t >= dur then return 0 end
	return sin(pi * t / dur)
end

local function add(model: Model)
	if rigs[model] then return end
	local kind = model:GetAttribute("Rig")
	if kind ~= "Duck" and kind ~= "Boss" then return end
	local motors = {}
	local hubs, bursts = {}, {}
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Name:sub(1, 2) == "J_" then
			motors[d.Name:sub(3)] = d
			n += 1
		elseif d:IsA("Weld") and d.Name == "SpinWeld" and kind == "Duck" then
			local hub = d.Parent
			table.insert(hubs, {d, d.C0, hub:GetAttribute("Spin") or 1, hub:GetAttribute("Axis") or "Y", #hubs * 2.1})
		elseif d:IsA("ParticleEmitter") and d.Name == "SigBurst" then
			table.insert(bursts, d)
		end
	end
	if n == 0 then return end
	local seed = model:GetAttribute("Seed") or (math.random() )
	local rec = {
		Model = model, Kind = kind, Motors = motors, Root = model.PrimaryPart,
		Seed = seed * 37.1, Active = true, Shots = {}, InGui = not model:IsDescendantOf(workspace),
		NextFlap = os.clock() + 2 + seed * 8, FlapT = -10,
		BossId = model:GetAttribute("BossId"),
		Hubs = hubs, Bursts = bursts,
		Sig = if kind == "Duck" and motors.Core then model:GetAttribute("Sig") else nil,
		Style = model:GetAttribute("SigStyle"),
		NextFl = os.clock() + 3 + seed * 6, FlT = -10,
	}
	-- tendrils & legs get stable phase offsets
	rec.Order = {}
	for name, m in motors do table.insert(rec.Order, {name, m, (#rec.Order + 1) * 1.37}) end
	rigs[model] = rec
	table.insert(list, rec)
end

local function remove(model)
	local rec = rigs[model]
	if not rec then return end
	rigs[model] = nil
	local i = table.find(list, rec)
	if i then table.remove(list, i) end
end

function Anim.Register(model: Model)
	add(model)
end

-- name: "attack" | "hit" | "cast" | "celebrate" | "faint" | "roar"
function Anim.Play(model: Model, name: string, duration: number?)
	local rec = rigs[model]
	if not rec then add(model); rec = rigs[model] end
	if not rec then return end
	local dur = duration or ({attack = 0.55, hit = 0.4, cast = 0.7, celebrate = 1.4, faint = 0.6, roar = 1.2})[name] or 0.5
	rec.Shots[name] = {T0 = os.clock(), Dur = dur, Hold = (name == "faint")}
end

local function shot(rec, name, now)
	local s = rec.Shots[name]
	if not s then return 0 end
	local t = now - s.T0
	if s.Hold then return clamp(t / s.Dur, 0, 1) end
	if t >= s.Dur then rec.Shots[name] = nil return 0 end
	return env(t, s.Dur)
end

---------------------------------------------------------------- ducks
local function animDuck(rec, now, battle)
	local m, sd = rec.Motors, rec.Seed
	local t = now + sd
	local atk = shot(rec, "attack", now)
	local hit = shot(rec, "hit", now)
	local cast = shot(rec, "cast", now)
	local cel = shot(rec, "celebrate", now)
	local faint = shot(rec, "faint", now)

	-- periodic flap burst
	if now > rec.NextFlap then
		rec.FlapT = now
		rec.NextFlap = now + (if battle then 2.5 else 5) + (sd % 1) * 6
	end
	local ft = now - rec.FlapT
	local burst = if ft < 0.9 then env(ft, 0.9) * abs(sin(ft * 22)) else 0

	local speed = if battle then 1.8 else 1
	local flap = 0.06 + sin(t * 2.2 * speed) * 0.05 + burst * 0.75 + cel * abs(sin(now * 26)) * 0.9 + cast * 0.8 + atk * 0.5
	if m.WingL then m.WingL.Transform = ANG(0, 0, -flap) end
	if m.WingR then m.WingR.Transform = ANG(0, 0, flap) end
	local big = 0.08 + sin(t * 1.6 * speed) * 0.1 + burst * 0.5 + cel * abs(sin(now * 18)) * 0.6 + cast * 0.6

	-- top rarities: hover over the water, slow majestic wing beats, flowing plumes and a signature flourish
	local sig = rec.Sig
	if sig then
		if now > rec.NextFl then
			rec.FlT = now
			rec.NextFl = now + (if battle then 6 else 8) + (sd % 1) * 6
			if sig >= 8 then for _, e in rec.Bursts do e:Emit(16 + sig * 4) end end
		end
		local fd = if sig >= 10 then 1.7 else 1.25
		local ft2 = now - rec.FlT
		local u = if ft2 < fd and sig >= 8 then ft2 / fd else nil
		local e = if u then sin(pi * u) else 0
		local s = if u then u * u * (3 - 2 * u) else 0
		local hover = (sig - 7) * 0.3 + 0.12 + sin(t * 1.3) * (0.06 + sig * 0.012)
		local tr
		local style = rec.Style
		if not u then
			tr = CF(0, hover, 0) * ANG(sin(t * 0.9) * 0.05, 0, sin(t * 0.7) * 0.06)
		elseif style == "ascend" then
			tr = CF(0, hover + e * 1.5, 0) * ANG(0, s * 2 * pi, 0)
		elseif style == "roll" then
			tr = CF(0, hover + e * 1.0, 0) * ANG(0, 0, s * 2 * pi)
		elseif style == "loop" then
			tr = CF(0, hover + e * 1.7, 0) * ANG(-s * 2 * pi, 0, 0)
		else -- glitch: violent jitter and snap turns
			local q = math.floor(now * 24)
			tr = CF(math.noise(q * 0.71, sd) * 1.6 * e, hover + math.noise(q * 0.53, sd + 9) * 1.2 * e, math.noise(q * 0.37, sd + 4) * 1.6 * e)
				* ANG(0, (if q % 3 == 0 then 1.2 else -0.6) * e, math.noise(q * 0.9, sd) * e)
		end
		m.Core.Transform = tr * CF(0, -faint * hover, 0) * ANG(-atk * 0.25 + hit * 0.2, 0, 0)
		for i = 1, 3 do
			local p = m["Plume" .. i]
			if p then p.Transform = ANG(sin(t * 1.8 + i * 1.3) * 0.16 - e * 0.35, sin(t * 1.25 + i * 2.1) * 0.26, 0) end
		end
		local beat = sin(t * (if sig >= 10 then 1.15 else 1.5))
		local amp = 0.2 + (sig - 8) * 0.07
		local w = 0.08 + beat * amp + e * 0.7 + cast * 0.5 + atk * 0.4
		if m.EWingR then m.EWingR.Transform = ANG(0, beat * 0.1, w) end
		if m.EWingL then m.EWingL.Transform = ANG(0, -beat * 0.1, w) end
		if sig >= 8 then big += beat * amp + e * 0.5 end
	end
	if m.BigWingL then m.BigWingL.Transform = ANG(0, big * 0.6, -big) end
	if m.BigWingR then m.BigWingR.Transform = ANG(0, -big * 0.6, big) end

	if m.Neck then
		local yaw = sin(t * 0.55) * 0.32 + sin(t * 1.7) * 0.06
		local pitch = sin(t * 1.25) * 0.06 + (if battle then sin(t * 4) * 0.04 else 0)
		local roll = sin(t * 0.8) * 0.06
		-- quick curious head tilt every few seconds
		local tilt = env((t * 0.23) % 1, 0.18) * 0.28
		pitch += -atk * 0.55 + hit * 0.45 - cast * 0.25 + faint * 0.5
		yaw *= (1 - atk) * (1 - faint)
		roll += tilt + cel * sin(now * 14) * 0.25 + hit * 0.2
		local lunge = CF(0, -faint * 0.3, -atk * 0.45 + hit * 0.25)
		m.Neck.Transform = lunge * ANG(pitch, yaw, roll)
	end
end

---------------------------------------------------------------- bosses
local function animBoss(rec, now, battle)
	local m, sd = rec.Motors, rec.Seed
	local t = now + sd
	local atk = shot(rec, "attack", now)
	local hit = shot(rec, "hit", now)
	local roar = shot(rec, "roar", now)
	local cast = shot(rec, "cast", now)
	local faint = shot(rec, "faint", now)
	local sp = if battle then 1.25 else 1
	local breathe = sin(t * 1.4 * sp)
	for _, e in rec.Order do
		local name, mot, ph = e[1], e[2], e[3]
		local tr = IDENT
		if name == "Torso" or name == "Body" then
			local lean = atk * 0.22 - hit * 0.18 + roar * -0.1 + faint * 0.5
			tr = CF(0, breathe * 0.12 - faint * 1.5, 0) * ANG(-lean + breathe * 0.015, sin(t * 0.4) * 0.05, faint * 0.4)
		elseif name == "Core" then
			tr = CF(0, sin(t * 1.1) * 0.6 - faint * 3, 0) * ANG(sin(t * 0.5) * 0.08, sin(t * 0.3) * 0.2, 0)
		elseif name == "Head" or name == "Face" then
			local yaw = sin(t * 0.45) * 0.18 * (1 - atk)
			local pitch = sin(t * 0.9) * 0.05 - atk * 0.25 + hit * 0.3 + roar * 0.45 + faint * 0.4
			tr = ANG(pitch, yaw, sin(t * 0.7) * 0.04)
			if name == "Face" then tr = CF(0, breathe * 0.25, 0) * tr end
		elseif name == "Jaw" then
			local open = 0.08 + (0.5 + 0.5 * sin(t * 1.7)) * 0.12 + atk * 0.55 + roar * 0.6 + cast * 0.4
			tr = ANG(open, 0, 0)
		elseif name == "ArmL" or name == "ArmR" then
			local s = if name == "ArmL" then -1 else 1
			local swing = sin(t * 1.1 * sp + (s > 0 and pi or 0)) * 0.1
			local raise = atk * 1.5 + cast * 1.0 + roar * 0.6
			tr = ANG(swing + raise * 0.75, 0, s * (0.03 + breathe * 0.03 + raise * 0.35 + faint * 0.4))
		elseif name == "WingL" or name == "WingR" then
			local s = if name == "WingL" then -1 else 1
			local f = 0.15 + sin(t * 2.6 * sp) * 0.3 + atk * 0.4 + roar * 0.6 * abs(sin(now * 12))
			tr = ANG(0, -s * 0.15 * sin(t * 2.6 * sp), s * f)
		elseif name == "Tail" then
			tr = ANG(sin(t * 1.3) * 0.08, sin(t * 1.6 * sp) * 0.35, 0)
		elseif name:sub(1, 7) == "Tendril" then
			local a = t * 1.6 * sp + ph
			tr = ANG(sin(a) * 0.22 + atk * 0.3, 0, cos(a * 0.8) * 0.22)
		elseif name:sub(1, 3) == "Leg" or name == "Legs" then
			local step = sin(t * 1.8 * sp + ph * 2.1) * (if battle then 0.12 else 0.05)
			tr = ANG(step, 0, 0)
		elseif name == "Ring1" then
			tr = ANG(0.35, now * 1.3, 0.1)
		elseif name == "Ring2" then
			tr = ANG(-0.5, -now * 0.9, 0.6)
		end
		mot.Transform = tr
	end
end

---------------------------------------------------------------- loop
local acc = 0
local function cull()
	local camPos = camera and camera.CFrame.Position or Vector3.zero
	for i = #list, 1, -1 do
		local rec = list[i]
		local model = rec.Model
		if not model.Parent or not rec.Root or not rec.Root.Parent then
			remove(model)
		elseif rec.InGui then
			rec.Active = true
		else
			local range = if rec.Kind == "Boss" then BOSS_RANGE else DUCK_RANGE
			if model:GetAttribute("AnimStyle") == "battle" then range = 1e9 end
			local near = (rec.Root.Position - camPos).Magnitude < range
			if not near and rec.Active then
				-- settle to rest pose once when leaving range
				for _, mot in rec.Motors do mot.Transform = IDENT end
			end
			rec.Active = near
		end
	end
end

local function step(dt)
	debug.profilebegin("DuckRig")
	camera = workspace.CurrentCamera
	acc += dt
	if acc > 0.4 then acc = 0; cull() end
	local now = os.clock()
	for _, rec in list do
		if rec.Active then
			local style = rec.Model:GetAttribute("AnimStyle")
			local battle = style == "battle" or style == "swim"
			if rec.Kind == "Duck" then
				animDuck(rec, now, battle)
				-- spinning halos, rings, orbs and runes
				for _, h in rec.Hubs do
					local a = now * h[3] + h[5]
					h[1].C0 = h[2] * (if h[4] == "X" then ANG(a, 0, 0) elseif h[4] == "Z" then ANG(0, 0, a) else ANG(0, a, 0))
				end
			else
				animBoss(rec, now, battle)
			end
		end
	end
	debug.profileend()
end

local started = false
function Anim.Init()
	if started then return end
	started = true
	local function watch(container: Instance)
		for _, d in container:GetDescendants() do
			if d:IsA("Model") and d:GetAttribute("Rig") then add(d) end
		end
		container.DescendantAdded:Connect(function(d)
			if d:IsA("Model") and d:GetAttribute("Rig") then
				-- wait a frame so all joints have replicated/parented
				task.defer(function()
					if d.Parent then
						remove(d)
						add(d)
						local rec = rigs[d]
						if rec then rec.InGui = not d:IsDescendantOf(workspace) end
					end
				end)
			end
		end)
	end
	-- only the 3D world: GUI previews are static pictures (animating them re-renders every frame)
	watch(workspace)
	RunService.RenderStepped:Connect(step)
	cull()
end

return Anim
