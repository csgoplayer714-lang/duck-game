-- Cosmetics bought with Feathers and worn on the character (everyone sees them).
-- Each item becomes an Accessory: invisible Handle + Blender mesh parts. Animated groups (a_/wl_/wr_)
-- hang off Motor6D joints named CosAnim_<group>, which Client.CosmeticFx animates on every client.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Cosmetics = require(Shared.Cosmetics)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)

local Svc = {}
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local function emitter(parent, props)
	local pe = Instance.new("ParticleEmitter")
	for k, v in props do (pe :: any)[k] = v end
	pe.Parent = parent
	return pe
end

local function setupPart(p)
	p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	p.CastShadow = false
end

local function groupOf(name)
	if name:sub(1, 2) == "a_" then return "a" end
	if name:sub(1, 3) == "wl_" then return "wl" end
	if name:sub(1, 3) == "wr_" then return "wr" end
	return nil
end

function Svc.BuildAccessory(item)
	local lib = RS.Assets.Meshes:FindFirstChild("Cosmetics")
	lib = lib and lib:FindFirstChild(item.Id)
	if not lib then return nil end
	local acc = Instance.new("Accessory")
	acc.Name = "Cosmetic_" .. item.Slot
	acc:SetAttribute("CosmeticId", item.Id)
	acc:SetAttribute("Anim", item.Anim)
	local handle = Instance.new("Part")
	handle.Name = "Handle"; handle.Size = Vector3.new(0.2, 0.2, 0.2); handle.Transparency = 1
	setupPart(handle)
	handle.CFrame = CFrame.new()
	handle.Parent = acc
	local att = Instance.new("Attachment"); att.Name = Cosmetics.Attach[item.Slot]; att.Parent = handle
	local joints = {}
	local pivots = Cosmetics.Pivots[item.Id] or {}
	local function joint(g)
		if joints[g] then return joints[g] end
		local j = Instance.new("Part")
		j.Name = "Joint_" .. g; j.Size = Vector3.new(0.1, 0.1, 0.1); j.Transparency = 1
		setupPart(j)
		local pv = pivots[g] or Vector3.zero
		j.CFrame = CFrame.new(pv)
		local m = Instance.new("Motor6D")
		m.Name = "CosAnim_" .. g; m.Part0 = handle; m.Part1 = j; m.C0 = CFrame.new(pv); m.C1 = CFrame.new()
		m.Parent = j
		j.Parent = acc
		joints[g] = j
		return j
	end
	for _, src in lib:GetChildren() do
		local p = src:Clone()
		setupPart(p)
		local st = Cosmetics.Style[src:GetAttribute("Slot")]
		if st then p.Color = st[1]; p.Material = Enum.Material[st[2]] end
		if p.Material == Enum.Material.Glass then p.Transparency = 0.15; p.Reflectance = 0.3 end
		p.CFrame = src.CFrame
		local g = groupOf(src.Name)
		-- classic Weld with an explicit offset (WeldConstraints built outside the workspace didn't hold inside accessories)
		local p0 = if g then joint(g) else handle
		local w = Instance.new("Weld")
		w.Part0 = p0
		w.Part1 = p
		w.C0 = p0.CFrame:ToObjectSpace(p.CFrame)
		w.C1 = CFrame.new()
		w.Parent = p
		p.Parent = acc
	end
	-- effects
	if item.Id == "Jetpack" then
		for _, sx in {-1, 1} do
			local a = Instance.new("Attachment"); a.Name = "Nozzle"; a.Position = Vector3.new(sx * 0.45, -1.0, 0.62); a.Parent = handle
			emitter(a, {Texture = FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 80, 20)), LightEmission = 1,
				Size = NumberSequence.new(0.5, 0.05), Lifetime = NumberRange.new(0.25, 0.45), Speed = NumberRange.new(6, 9), Rate = 45,
				EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(8, 8), Transparency = NumberSequence.new(0.1, 1)})
		end
	elseif item.Id == "Halo" then
		emitter(joint("a"), {Texture = SPARK, Color = ColorSequence.new(Color3.fromRGB(255, 240, 160)), LightEmission = 1, Rate = 8,
			Size = NumberSequence.new(0.25, 0), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(0.3, 0.8)})
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 230, 140); l.Range = 6; l.Brightness = 1; l.Parent = joint("a")
	elseif item.Id == "DragonWings" then
		for _, g in {"wl", "wr"} do
			emitter(joint(g), {Texture = FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 160, 60), Color3.fromRGB(200, 30, 10)), LightEmission = 0.8,
				Rate = 10, Size = NumberSequence.new(0.18, 0), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.5, 1.5),
				Acceleration = Vector3.new(0, 2, 0), SpreadAngle = Vector2.new(60, 60)})
		end
	elseif item.Id == "CosmicAura" then
		emitter(handle, {Texture = SPARK, Color = ColorSequence.new(Color3.fromRGB(150, 120, 255), Color3.fromRGB(120, 230, 255)), LightEmission = 1,
			Rate = 14, Size = NumberSequence.new(0.3, 0), Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(0.5, 1.2), SpreadAngle = Vector2.new(180, 180)})
	elseif item.Id == "AngelWings" then
		emitter(handle, {Texture = SPARK, Color = ColorSequence.new(Color3.new(1, 1, 1)), LightEmission = 0.6, Rate = 4,
			Size = NumberSequence.new(0.2, 0), Lifetime = NumberRange.new(1, 1.5), Speed = NumberRange.new(0.2, 0.5)})
	end
	return acc
end

local function trail(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local a0 = Instance.new("Attachment"); a0.Name = "CosTrail0"; a0.Position = Vector3.new(0, 0.9, 0.3); a0.Parent = hrp
	local a1 = Instance.new("Attachment"); a1.Name = "CosTrail1"; a1.Position = Vector3.new(0, -0.9, 0.3); a1.Parent = hrp
	local t = Instance.new("Trail")
	t.Name = "Cosmetic_Trail"
	t.Attachment0 = a0; t.Attachment1 = a1
	t.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 90)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 180, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(160, 90, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200))})
	t.Lifetime = 0.7; t.LightEmission = 0.6; t.Transparency = NumberSequence.new(0.15, 1); t.WidthScale = NumberSequence.new(1, 0.3)
	t.FaceCamera = true
	t.Parent = hrp
end

function Svc.Apply(player)
	local char = player.Character
	local d = DataService.Get(player)
	if not char or not d then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	for _, c in char:GetChildren() do
		if c:IsA("Accessory") and c.Name:sub(1, 9) == "Cosmetic_" then c:Destroy() end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, c in hrp:GetChildren() do
			if c.Name == "Cosmetic_Trail" or c.Name == "CosTrail0" or c.Name == "CosTrail1" then c:Destroy() end
		end
	end
	for slot, id in d.cosmetics.equipped do
		local item = Cosmetics.ById[id]
		if item then
			if item.Slot == "Trail" then
				trail(char)
			else
				local acc = Svc.BuildAccessory(item)
				if acc then
					-- hats replace the player's own hat so they don't clip
					if item.Slot == "Hat" then
						for _, c in char:GetChildren() do
							if c:IsA("Accessory") and c.Name:sub(1, 9) ~= "Cosmetic_" and c.AccessoryType == Enum.AccessoryType.Hat then
								local h = c:FindFirstChild("Handle")
								if h then h.Transparency = 1 end
							end
						end
					end
					pcall(function() hum:AddAccessory(acc) end)
				end
			end
		end
	end
end

local function buy(player, id)
	local d = DataService.Get(player)
	local item = typeof(id) == "string" and Cosmetics.ById[id]
	if not d or not item then return {ok = false} end
	if d.cosmetics.owned[id] then return {ok = false, err = "You already own this"} end
	if d.feathers < item.Price then return {ok = false, err = "Not enough Feathers"} end
	d.feathers -= item.Price
	d.cosmetics.owned[id] = true
	d.cosmetics.equipped[item.Slot] = id
	DataService.Push(player, "feathers", "cosmetics")
	Svc.Apply(player)
	return {ok = true}
end

local function equip(player, id)
	local d = DataService.Get(player)
	local item = typeof(id) == "string" and Cosmetics.ById[id]
	if not d or not item or not d.cosmetics.owned[id] then return {ok = false} end
	if d.cosmetics.equipped[item.Slot] == id then
		d.cosmetics.equipped[item.Slot] = nil
	else
		d.cosmetics.equipped[item.Slot] = id
	end
	DataService.Push(player, "cosmetics")
	Svc.Apply(player)
	return {ok = true, equipped = d.cosmetics.equipped[item.Slot] == id}
end

function Svc.Init()
	Net.On("CosBuy", 2, 4, buy)
	Net.On("CosEquip", 4, 8, equip)
	local function hook(p)
		p.CharacterAppearanceLoaded:Connect(function() task.wait(0.2); Svc.Apply(p) end)
		if p.Character then task.spawn(Svc.Apply, p) end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do hook(p) end
	DataService.Loaded.Event:Connect(function(p) task.wait(0.5); Svc.Apply(p) end)
end

return Svc
