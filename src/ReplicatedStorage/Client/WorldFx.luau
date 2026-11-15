-- Client-only world animation: swimming pool ducks, spinning accessory hubs, floating decor, per-world lighting.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local WorldFx = {}
local player = Players.LocalPlayer
WorldFx.LowFx = false

---------------------------------------------------------------- pool ducks
local pools = {} -- {water, ducks = {{model, pos, vel, phase, yaw}}}

local function setupPool(pool)
	local water = pool:FindFirstChild("Water")
	local folder = pool:FindFirstChild("Ducks")
	if not water or not folder then return end
	local entry = {water = water, ducks = {}, center = water.Position}
	local rng = Random.new()
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m.PrimaryPart then
			local cf = m:GetPivot()
			local rel = water.CFrame:PointToObjectSpace(cf.Position)
			local ang = rng:NextNumber(0, math.pi * 2)
			table.insert(entry.ducks, {model = m, root = m.PrimaryPart, x = rel.X, z = rel.Z, y = cf.Position.Y,
				vx = math.cos(ang) * rng:NextNumber(0.6, 1.6), vz = math.sin(ang) * rng:NextNumber(0.6, 1.6),
				phase = rng:NextNumber(0, 10), yaw = ang, turn = rng:NextNumber(-0.4, 0.4)})
		end
	end
	table.insert(pools, entry)
end

local hubs = {} -- {part, weld, base, speed, axis}
local floats = {} -- {part, base, phase}

local function registerHub(part)
	local weld = part:FindFirstChild("SpinWeld")
	if weld and weld:IsA("Weld") then
		table.insert(hubs, {part = part, weld = weld, base = weld.C0, speed = part:GetAttribute("Spin") or 1, axis = part:GetAttribute("Axis") or "Y", phase = math.random() * 6})
	end
end
WorldFx.RegisterHubs = function(model)
	for _, d in model:GetDescendants() do
		if d.Name == "SpinHub" then registerHub(d) end
	end
end

local function step(dt)
	debug.profilebegin("DuckWorldFx")
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	local t = os.clock()
	-- pool ducks: drift, bounce off walls, bob and tilt
	local parts, cfs = {}, {}
	for _, p in pools do
		if (p.center - camPos).Magnitude < 260 then
			local water = p.water
			local hx, hz = water.Size.X / 2 - 2, water.Size.Z / 2 - 2
			for _, d in p.ducks do
				if not d.model.Parent then continue end
				if d.model:GetAttribute("Hooked") then
					local rel = water.CFrame:PointToObjectSpace(d.root.Position)
					d.x, d.z = rel.X, rel.Z
					continue
				end
				d.yaw += d.turn * dt
				local speed = math.sqrt(d.vx * d.vx + d.vz * d.vz)
				d.vx = math.cos(d.yaw) * speed
				d.vz = math.sin(d.yaw) * speed
				d.x += d.vx * dt
				d.z += d.vz * dt
				if d.x > hx or d.x < -hx then d.x = math.clamp(d.x, -hx, hx); d.yaw = math.pi - d.yaw end
				if d.z > hz or d.z < -hz then d.z = math.clamp(d.z, -hz, hz); d.yaw = -d.yaw end
				-- divider in the middle
				if math.abs(d.z) < 2.8 and math.abs(d.x) < water.Size.X * 0.28 then
					d.z = if d.z >= 0 then 2.8 else -2.8
					d.yaw = -d.yaw
				end
				if math.random() < dt * 0.15 then d.turn = math.random() * 0.8 - 0.4 end
				local pos = water.CFrame:PointToWorldSpace(Vector3.new(d.x, 0, d.z))
				local bob = math.sin(t * 2 + d.phase) * 0.08
				local tilt = math.sin(t * 1.6 + d.phase) * 0.06
				-- duck model faces -Z; heading = movement direction
				local heading = math.atan2(-d.vx, -d.vz)
				table.insert(parts, d.root)
				table.insert(cfs, CFrame.new(pos.X, d.y + bob, pos.Z) * CFrame.Angles(0, heading, 0) * CFrame.Angles(tilt, 0, tilt * 0.7))
			end
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	-- spinning hubs
	for i = #hubs, 1, -1 do
		local h = hubs[i]
		if not h.part.Parent then
			table.remove(hubs, i)
		elseif not WorldFx.LowFx and (h.part.Position - camPos).Magnitude < 150 then
			local a = t * h.speed + h.phase
			h.weld.C0 = h.base * (if h.axis == "X" then CFrame.Angles(a, 0, 0) elseif h.axis == "Z" then CFrame.Angles(0, 0, a) else CFrame.Angles(0, a, 0))
		end
	end
	-- floating decor
	for i = #floats, 1, -1 do
		local f = floats[i]
		if not f.part.Parent then table.remove(floats, i)
		elseif (f.base.Position - camPos).Magnitude < 220 then
			f.part.CFrame = f.base * CFrame.new(0, math.sin(t * 1.2 + f.phase) * 0.8, 0) * CFrame.Angles(0, t * 0.3 + f.phase, 0)
		end
	end
	debug.profileend()
end

---------------------------------------------------------------- lighting per world
local MOODS = {
	[1] = {Clock = 14.2, Bright = 2.6, Ambient = Color3.fromRGB(110, 110, 130), Out = Color3.fromRGB(150, 150, 165), Atmo = Color3.fromRGB(200, 225, 255), Decay = Color3.fromRGB(110, 140, 190), Density = 0.28, Tint = Color3.new(1, 1, 1), Sat = 0.18},
	[2] = {Clock = 15, Bright = 3, Ambient = Color3.fromRGB(130, 120, 100), Out = Color3.fromRGB(170, 160, 130), Atmo = Color3.fromRGB(255, 235, 200), Decay = Color3.fromRGB(120, 200, 220), Density = 0.25, Tint = Color3.fromRGB(255, 248, 235), Sat = 0.25},
	[3] = {Clock = 11, Bright = 2.4, Ambient = Color3.fromRGB(140, 160, 190), Out = Color3.fromRGB(170, 190, 220), Atmo = Color3.fromRGB(220, 235, 255), Decay = Color3.fromRGB(180, 210, 240), Density = 0.4, Tint = Color3.fromRGB(235, 245, 255), Sat = 0},
	[4] = {Clock = 18.6, Bright = 1.6, Ambient = Color3.fromRGB(120, 60, 40), Out = Color3.fromRGB(140, 70, 50), Atmo = Color3.fromRGB(255, 120, 60), Decay = Color3.fromRGB(120, 30, 10), Density = 0.42, Tint = Color3.fromRGB(255, 225, 205), Sat = 0.2},
	[5] = {Clock = 0.5, Bright = 1.2, Ambient = Color3.fromRGB(70, 60, 100), Out = Color3.fromRGB(80, 70, 120), Atmo = Color3.fromRGB(80, 110, 80), Decay = Color3.fromRGB(40, 30, 70), Density = 0.5, Tint = Color3.fromRGB(215, 225, 255), Sat = -0.1},
	[6] = {Clock = 17.6, Bright = 2.2, Ambient = Color3.fromRGB(120, 100, 160), Out = Color3.fromRGB(150, 130, 200), Atmo = Color3.fromRGB(230, 180, 255), Decay = Color3.fromRGB(100, 120, 255), Density = 0.32, Tint = Color3.fromRGB(250, 240, 255), Sat = 0.3},
	[7] = {Clock = 12, Bright = 3.2, Ambient = Color3.fromRGB(170, 160, 140), Out = Color3.fromRGB(200, 190, 170), Atmo = Color3.fromRGB(255, 250, 230), Decay = Color3.fromRGB(255, 220, 150), Density = 0.35, Tint = Color3.fromRGB(255, 252, 240), Sat = 0.1},
	[8] = {Clock = 22, Bright = 1.1, Ambient = Color3.fromRGB(90, 50, 140), Out = Color3.fromRGB(70, 40, 120), Atmo = Color3.fromRGB(120, 40, 200), Decay = Color3.fromRGB(30, 0, 60), Density = 0.45, Tint = Color3.fromRGB(235, 215, 255), Sat = 0.25},
}
function WorldFx.ApplyMood(id)
	local m = MOODS[id] or MOODS[1]
	local info = TweenInfo.new(1.2)
	TweenService:Create(Lighting, info, {ClockTime = m.Clock, Brightness = m.Bright, Ambient = m.Ambient, OutdoorAmbient = m.Out}):Play()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if a then TweenService:Create(a, info, {Color = m.Atmo, Decay = m.Decay, Density = m.Density}):Play() end
	local cc = Lighting:FindFirstChild("WorldColor")
	if cc then TweenService:Create(cc, info, {TintColor = m.Tint, Saturation = m.Sat}):Play() end
end

-- detect world by position (works even if the attribute lags)
local WorldData = require(game:GetService("ReplicatedStorage").Shared.WorldData)
local function worldAt(pos)
	local best, bestD = 1, math.huge
	for _, w in WorldData.List do
		local d = (Vector3.new(pos.X, 0, pos.Z) - w.Origin).Magnitude
		if d < bestD then best, bestD = w.Id, d end
	end
	return best
end

function WorldFx.Init()
	local map = workspace:WaitForChild("Map", 30)
	if map then
		for _, wf in map:GetChildren() do
			local pool = wf:FindFirstChild("Pool")
			if pool then setupPool(pool) end
			for _, d in wf:GetDescendants() do
				if d.Name == "SpinHub" then registerHub(d)
				elseif d:IsA("BasePart") and d:GetAttribute("Float") then
					table.insert(floats, {part = d, base = d.CFrame, phase = math.random() * 6})
				end
			end
		end
	end
	RunService.Heartbeat:Connect(step)
	local current = 0
	task.spawn(function()
		while true do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and not player:GetAttribute("InBattleView") then
				local w = worldAt(hrp.Position)
				if w ~= current then current = w; WorldFx.ApplyMood(w) end
			end
			task.wait(0.5)
		end
	end)
	WorldFx.ForceMood = function() current = 0 end
end

return WorldFx
