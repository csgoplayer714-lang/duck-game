-- Every player's equipped team ducks waddle behind them (rendered locally on each client from the
-- replicated "TeamDucks" attribute, so it costs the server nothing).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local DuckData = require(RS.Shared.DuckData)
local DuckModelBuilder = require(RS.Shared.DuckModelBuilder)

local Followers = {}
local folder
local entries = {} -- [player] = {key, ducks = {{model, root, pos, yaw, phase}}}
local templates = {}
local OFFSETS = {Vector3.new(-3.2, 0, 4.5), Vector3.new(3.2, 0, 4.5), Vector3.new(0, 0, 7.5)}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function template(id)
	if not templates[id] then
		local duck = DuckData.List[id]
		templates[id] = DuckModelBuilder.Build(duck, {Lite = true, Scale = 0.55})
		for _, p in templates[id]:GetDescendants() do if p:IsA("BasePart") then p.CastShadow = true; p.CanQuery = false end end
	end
	return templates[id]:Clone()
end

local function rebuild(player)
	local e = entries[player]
	if e then for _, d in e.ducks do d.model:Destroy() end end
	local key = player:GetAttribute("TeamDucks") or ""
	e = {key = key, ducks = {}}
	entries[player] = e
	local i = 0
	for idStr in string.gmatch(key, "[^,]+") do
		local id = tonumber(idStr)
		if id and DuckData.List[id] and i < 3 then
			i += 1
			local m = template(id)
			m.Parent = folder
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local start = if hrp then hrp.Position else Vector3.zero
			table.insert(e.ducks, {model = m, root = m.PrimaryPart, pos = start, yaw = 0, phase = math.random() * 6, slot = i})
		end
	end
end

local function watch(player)
	player:GetAttributeChangedSignal("TeamDucks"):Connect(function() rebuild(player) end)
	rebuild(player)
end

function Followers.Init()
	folder = Instance.new("Folder")
	folder.Name = "FollowerDucks"
	folder.Parent = workspace
	rayParams.FilterDescendantsInstances = {folder}
	for _, p in Players:GetPlayers() do watch(p) end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(p)
		local e = entries[p]
		if e then for _, d in e.ducks do d.model:Destroy() end end
		entries[p] = nil
	end)
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		local parts, cfs = {}, {}
		local exclude = {folder}
		for p in entries do if p.Character then table.insert(exclude, p.Character) end end
		rayParams.FilterDescendantsInstances = exclude
		for player, e in entries do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local inBattle = player:GetAttribute("InBattle") == true
			for _, d in e.ducks do
				if not hrp or (hrp.Position - camPos).Magnitude > 220 then
					if hrp then d.pos = hrp.Position end
					continue
				end
				local flat = CFrame.new(hrp.Position) * CFrame.Angles(0, select(2, hrp.CFrame:ToOrientation()), 0)
				local target = flat:PointToWorldSpace(OFFSETS[d.slot])
				if (d.pos - target).Magnitude > 60 then d.pos = target end -- teleported
				local before = d.pos
				d.pos = d.pos:Lerp(target, 1 - math.exp(-dt * 5))
				local vel = (d.pos - before) / math.max(dt, 1e-3)
				local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
				-- ground (or water surface) height
				local hit = workspace:Raycast(Vector3.new(d.pos.X, hrp.Position.Y + 4, d.pos.Z), Vector3.new(0, -30, 0), rayParams)
				local groundY = if hit then hit.Position.Y else hrp.Position.Y - 3
				if speed > 0.5 then
					local want = math.atan2(-vel.X, -vel.Z)
					local diff = (want - d.yaw + math.pi) % (math.pi * 2) - math.pi
					d.yaw += diff * math.min(1, dt * 8)
				else
					local want = select(2, hrp.CFrame:ToOrientation())
					local diff = (want - d.yaw + math.pi) % (math.pi * 2) - math.pi
					d.yaw += diff * math.min(1, dt * 3)
				end
				local moving = math.clamp(speed / 10, 0, 1)
				local hop = math.abs(math.sin(t * 11 + d.phase)) * 0.55 * moving + math.sin(t * 2 + d.phase) * 0.06
				local roll = math.sin(t * 11 + d.phase) * 0.14 * moving
				local celebrate = if inBattle then math.abs(math.sin(t * 6 + d.phase)) * 0.8 else 0
				table.insert(parts, d.root)
				table.insert(cfs, CFrame.new(d.pos.X, groundY + hop + celebrate, d.pos.Z) * CFrame.Angles(0, d.yaw, roll))
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)
end

return Followers
