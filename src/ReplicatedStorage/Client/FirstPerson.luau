-- First-person experience: locked camera, held-net viewmodel (sway, bob, scoop animation),
-- crosshair that reacts to the water, and a cursor manager for menus/minigame/battles.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local RodModelBuilder = require(Shared.RodModelBuilder)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local new = UI.new

local FP = {}
local player = Players.LocalPlayer
local reasons = {}
local modal, crossRoot, crossRing, crossDot, crossHint, cursorHint
local vm, vmHandle, vmTip, vmRodId
local swayX, swayY = 0, 0
local lastLook
local castT = -10
local reeling, reelHold = false, false
local hidden = false
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MAX_ZOOM = 22

-- true when the camera is zoomed all the way in (first person). Scroll out for third person.
function FP.IsFirstPerson(): boolean
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then return false end
	return (cam.Focus.Position - cam.CFrame.Position).Magnitude < 1.5
end

-- spawn zoomed in (first person) but keep the scroll wheel free to zoom out
local function startInFirstPerson()
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
	task.delay(0.35, function() player.CameraMaxZoomDistance = MAX_ZOOM end)
end

function FP.SetCursor(reason: string, on: boolean)
	reasons[reason] = on or nil
end
local watchers = {}
function FP.AddWatcher(fn) table.insert(watchers, fn) end
function FP.CursorFree()
	if next(reasons) ~= nil then return true end
	for _, fn in watchers do if fn() then return true end end
	return false
end

---------------------------------------------------------------- viewmodel
local function equippedRod()
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("RodId") then return tool end
	return nil
end
FP.EquippedRod = equippedRod

local function buildViewmodel(rodId)
	if vm then vm:Destroy() end
	local rod = Config.Rods[rodId] or Config.Rods[1]
	vm = RodModelBuilder.Build(rod, false)
	vm.Name = "RodViewmodel"
	vmHandle = vm.PrimaryPart
	local skin = Color3.fromRGB(255, 205, 160)
	local char = player.Character
	local bc = char and char:FindFirstChildOfClass("BodyColors")
	if bc then skin = bc.RightArmColor3 end
	local function add(shape, size, cf, color, mat)
		local p = Instance.new("Part")
		if shape == "ball" then p.Shape = Enum.PartType.Ball elseif shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
		p.Size = size; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
		p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Anchored = false; p.Massless = true
		p.CFrame = vmHandle.CFrame * cf
		local w = Instance.new("WeldConstraint"); w.Part0 = vmHandle; w.Part1 = p; w.Parent = p
		p.Parent = vm
		return p
	end
	-- gloved hand wrapped around the grip + sleeve
	add("ball", Vector3.new(0.52, 0.52, 0.52), CFrame.new(0.05, -0.05, 0.2), skin)
	add("ball", Vector3.new(0.34, 0.34, 0.34), CFrame.new(-0.15, 0.12, -0.05), skin)
	add("cyl", Vector3.new(1.8, 0.6, 0.6), CFrame.new(0.2, -0.3, 1.2) * CFrame.Angles(0, math.rad(90), math.rad(-18)), Color3.fromRGB(60, 120, 230), Enum.Material.Fabric)
	for _, p in vm:GetDescendants() do
		if p:IsA("BasePart") then p.CastShadow = false; p.CanQuery = false; p.CanTouch = false; p.CanCollide = false end
	end
	vmTip = vm:FindFirstChild("Tip")
	vmRodId = rodId
	vm.Parent = workspace.CurrentCamera
end

function FP.TipAttachment()
	if vm and vm.Parent and not hidden and vmTip then return vmTip:FindFirstChild("LineAttachment") end
	return nil
end

function FP.PlayCast() castT = os.clock() end
function FP.SetReeling(on: boolean, holding: boolean?)
	reeling = on
	reelHold = holding == true
end

---------------------------------------------------------------- aiming
local aimCacheT, aimCacheHit, aimCacheWater = -1, nil, nil
local aimWaterRaw
function FP.AimWater()
	-- several systems ask every frame; raycast once per frame and share the answer
	local t = os.clock()
	if t - aimCacheT < 0.005 then return aimCacheHit, aimCacheWater end
	aimCacheT = t
	aimCacheHit, aimCacheWater = aimWaterRaw()
	return aimCacheHit, aimCacheWater
end

local PoolSim = require(game:GetService("ReplicatedStorage").Shared.PoolSim)
-- the pond is a flat surface with a known outline, so aiming is a ray/plane intersection (no physics needed)
aimWaterRaw = function()
	local cam = workspace.CurrentCamera
	local world = player:GetAttribute("World") or 1
	local map = workspace:FindFirstChild("Map")
	local wf = map and map:FindFirstChild("World_" .. world)
	local water = wf and wf:FindFirstChild("Pond") and wf.Pond:FindFirstChild("Water")
	if not cam then return nil end
	local origin = cam.CFrame.Position
	local dir = cam.CFrame.LookVector
	if (FP.CursorFree() or not FP.IsFirstPerson()) and not isTouch then
		local m = UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(m.X, m.Y)
		origin, dir = ray.Origin, ray.Direction
	end
	local y = PoolSim.Center(world).Y
	dir = dir.Unit
	if dir.Y > -0.02 or origin.Y <= y then return nil, water end
	local k = (y - origin.Y) / dir.Y
	if k > 90 then return nil, water end
	local hit = origin + dir * k
	if not PoolSim.InPool(world, hit, -0.2) then return nil, water end
	return hit, water
end

---------------------------------------------------------------- UI
function FP.Init(screen)
	player.CameraMode = Enum.CameraMode.Classic
	startInFirstPerson()
	player.CharacterAdded:Connect(startInFirstPerson)
	modal = new("TextButton", {Parent = screen, Name = "CursorModal", Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Visible = false})
	crossRoot = new("Frame", {Parent = screen, Name = "Crosshair", Size = UDim2.fromOffset(60, 60), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 2})
	crossRing = new("Frame", {Parent = crossRoot, Size = UDim2.fromOffset(26, 26), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 2})
	UI.Corner(crossRing, 13)
	local ringStroke = UI.Stroke(crossRing, Color3.new(1, 1, 1), 2.5, 0.25)
	crossDot = new("Frame", {Parent = crossRoot, Size = UDim2.fromOffset(6, 6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3})
	UI.Corner(crossDot, 3)
	UI.Stroke(crossDot, UI.C.Outline, 1.5)
	local ringScale = new("UIScale", {Parent = crossRing})
	crossHint = UI.Label(screen, "", UDim2.fromOffset(300, 22), UDim2.new(0.5, -150, 0.5, 26), {Font = UI.Body, ZIndex = 2})
	cursorHint = UI.Label(screen, if isTouch then "" else "[Alt] / [C] Cursor", UDim2.fromOffset(200, 18), UDim2.new(0, 16, 1, -26), {Font = UI.Body, TextColor3 = UI.C.Sub, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

	UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.C then
			if gp and input.KeyCode == Enum.KeyCode.C then return end
			FP.SetCursor("toggle", not reasons.toggle)
		end
	end)

	local aimOn = false
	local t = 0
	RunService:BindToRenderStep("DuckViewmodel", Enum.RenderPriority.Camera.Value + 1, function(dt)
		t += dt
		local cam = workspace.CurrentCamera
		local free = FP.CursorFree()
		modal.Visible = free and not isTouch
		local inBattle = player:GetAttribute("InBattleView") == true
		local firstPerson = FP.IsFirstPerson()
		-- phones aim from the screen centre in both views, so they always get the crosshair
		crossRoot.Visible = not free and not inBattle and (firstPerson or isTouch)
		cursorHint.Visible = not inBattle and firstPerson
		-- no mouse cursor while looking around in first person (menus/battles/Alt still free it)
		UserInputService.MouseIconEnabled = free or inBattle or not firstPerson or isTouch
		-- crosshair reacts to the water when a rod is equipped
		local tool = equippedRod()
		local hit = tool and not inBattle and FP.AimWater()
		local want = hit ~= nil
		if want ~= aimOn then
			aimOn = want
			UI.Tween(ringScale, 0.18, {Scale = if want then 1.35 else 1}, Enum.EasingStyle.Back)
			UI.Tween(ringStroke, 0.18, {Color = if want then UI.C.Gem else Color3.new(1, 1, 1), Transparency = if want then 0 else 0.25})
		end
		crossRing.Rotation = if aimOn then (t * 90) % 360 else 0
		crossHint.Text = ""

		-- viewmodel
		hidden = inBattle or not tool or not firstPerson
		if hidden then
			if vm then vm.Parent = nil end
			-- third person: show the real net in the character's hand
			if tool and not firstPerson then
				for _, p in tool:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end end
			end
			return
		end
		local rodId = tool:GetAttribute("RodId")
		if not vm or vmRodId ~= rodId then buildViewmodel(rodId) end
		if vm.Parent ~= cam then vm.Parent = cam end
		-- hide the third-person tool so only the viewmodel shows
		for _, p in tool:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end end
		-- sway from camera rotation
		local look = cam.CFrame.LookVector
		if lastLook then
			local rel = cam.CFrame:VectorToObjectSpace(lastLook)
			swayX = swayX + (rel.X * 2.2 - swayX) * math.min(1, dt * 12)
			swayY = swayY + (rel.Y * 2.2 - swayY) * math.min(1, dt * 12)
		end
		lastLook = look
		swayX = math.clamp(swayX * (1 - math.min(1, dt * 6)), -0.35, 0.35)
		swayY = math.clamp(swayY * (1 - math.min(1, dt * 6)), -0.35, 0.35)
		-- walk bob
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local moving = hum and hum.MoveDirection.Magnitude > 0.1
		local bobAmt = if moving then 1 else 0.25
		local bob = CFrame.new(math.sin(t * 7) * 0.05 * bobAmt, math.abs(math.cos(t * 7)) * 0.06 * bobAmt, 0)
		-- net scoop: quick lift, chop down into the water, then pull back up
		local ct = os.clock() - castT
		local castRot = 0
		local reach = 0
		if ct < 0.06 then castRot = math.rad(18) * (ct / 0.06)
		elseif ct < 0.16 then local a = (ct - 0.06) / 0.1; castRot = math.rad(18) - math.rad(68) * a; reach = a
		elseif ct < 0.3 then castRot = math.rad(-50); reach = 1
		elseif ct < 0.62 then local a = (ct - 0.3) / 0.32; a = a * a * (3 - 2 * a); castRot = math.rad(-50) * (1 - a) + math.rad(12) * math.sin(a * math.pi); reach = 1 - a end
		-- reeling: rod bends up and jitters while holding
		local reel = CFrame.new()
		if reeling then
			local k = if reelHold then 1 else 0.35
			reel = CFrame.Angles(math.rad(14 * k) + math.sin(t * 40) * 0.015 * k, math.sin(t * 23) * 0.02 * k, 0) * CFrame.new(0, 0.1 * k, 0.15 * k)
		end
		local base = CFrame.new(1.15, -1.3, -2.1) * CFrame.Angles(math.rad(26), math.rad(-10), math.rad(-8))
		vmHandle.CFrame = cam.CFrame * CFrame.new(-swayX * 0.6 - reach * 0.5, swayY * 0.4, -reach * 1.4) * bob * base
			* CFrame.Angles(castRot + swayY * 0.3, swayX * 0.4 + reach * 0.25, swayX * 0.3) * reel
	end)
	player.CharacterAdded:Connect(function()
		if vm then vm:Destroy(); vm = nil end
	end)
end

return FP
