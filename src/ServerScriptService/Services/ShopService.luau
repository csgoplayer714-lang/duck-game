-- Rods (buy/equip, tool giving), worlds (unlock/travel).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local WorldData = require(Shared.WorldData)
local RodModelBuilder = require(Shared.RodModelBuilder)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local Progress = require(script.Parent.ProgressService)

local Shop = {}
local toolCache = {}

local function rodTool(id)
	if not toolCache[id] then toolCache[id] = RodModelBuilder.Build(Config.Rods[id], true) end
	return toolCache[id]:Clone()
end

function Shop.GiveRod(player)
	local d = DataService.Get(player)
	if not d then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	local wasEquipped = false
	for _, container in {backpack, char} do
		if container then
			for _, t in container:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("RodId") then
					if t.Parent == char then wasEquipped = true end
					t:Destroy()
				end
			end
		end
	end
	if not backpack then return end
	local tool = rodTool(d.rod)
	tool.Parent = backpack
	if wasEquipped and char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum:EquipTool(tool) end
	end
end

local function buyRod(player, id)
	local d = DataService.Get(player)
	id = Net.Int(id, 1, #Config.Rods)
	if not d or not id then return {ok = false} end
	local rod = Config.Rods[id]
	if d.rods[tostring(id)] then return {ok = false, err = "Already owned"} end
	if d.rebirths < rod.Rebirth then return {ok = false, err = "Requires Rebirth " .. rod.Rebirth} end
	-- rods must be bought in order
	if id > 1 and not d.rods[tostring(id - 1)] then return {ok = false, err = "Buy the previous stick first"} end
	if d.coins < rod.Cost then return {ok = false, err = "Not enough coins"} end
	d.coins -= rod.Cost
	d.rods[tostring(id)] = true
	d.rod = id
	Shop.GiveRod(player)
	DataService.Push(player, "coins", "rods", "rod")
	return {ok = true}
end

local function equipRod(player, id)
	local d = DataService.Get(player)
	id = Net.Int(id, 1, #Config.Rods)
	if not d or not id or not d.rods[tostring(id)] then return {ok = false} end
	d.rod = id
	Shop.GiveRod(player)
	DataService.Push(player, "rod")
	return {ok = true}
end

function Shop.GrantRod(player, id)
	local d = DataService.Get(player)
	if not d or d.rods[tostring(id)] then return false end
	d.rods[tostring(id)] = true
	if id > d.rod then d.rod = id; Shop.GiveRod(player) end
	DataService.Push(player, "rods", "rod")
	return true
end

local function unlockWorld(player, id)
	local d = DataService.Get(player)
	id = Net.Int(id, 2, #WorldData.List)
	if not d or not id then return {ok = false} end
	local w = WorldData.List[id]
	if d.worlds[tostring(id)] then return {ok = false, err = "Already unlocked"} end
	if not d.worlds[tostring(id - 1)] then return {ok = false, err = "Unlock " .. WorldData.List[id - 1].Name .. " first"} end
	if d.rebirths < w.Rebirth then return {ok = false, err = "Requires Rebirth " .. w.Rebirth} end
	if d.coins < w.Cost then return {ok = false, err = "Not enough coins"} end
	d.coins -= w.Cost
	d.worlds[tostring(id)] = true
	DataService.Push(player, "coins", "worlds")
	return {ok = true}
end

function Shop.Teleport(player, id)
	local char = player.Character
	local map = workspace:FindFirstChild("Map")
	local wf = map and map:FindFirstChild("World_" .. id)
	if not char or not wf or not wf:FindFirstChild("Arrival") then return false end
	char:PivotTo(wf.Arrival.CFrame * CFrame.new(math.random(-4, 4), 3, math.random(-2, 2)))
	player:SetAttribute("World", id)
	player:SetAttribute("AtCoop", false)
	return true
end

local lastTravel = {}
local function travel(player, id)
	local d = DataService.Get(player)
	id = Net.Int(id, 1, #WorldData.List)
	if not d or not id then return {ok = false} end
	if not d.worlds[tostring(id)] then return {ok = false, err = "World locked"} end
	if player:GetAttribute("InBattle") then return {ok = false, err = "Finish your battle first"} end
	if lastTravel[player] and os.clock() - lastTravel[player] < 2 then return {ok = false, err = "Wait a moment"} end
	lastTravel[player] = os.clock()
	if not Shop.Teleport(player, id) then return {ok = false} end
	d.world = id
	DataService.Push(player, "world")
	return {ok = true}
end

function Shop.Init()
	Net.On("BuyRod", 2, 4, buyRod)
	Net.On("EquipRod", 3, 5, equipRod)
	Net.On("UnlockWorld", 1, 3, unlockWorld)
	Net.On("Travel", 1, 2, travel)
	local function onChar(player, char)
		task.wait(0.2)
		Shop.GiveRod(player)
		local d = DataService.Get(player)
		if d and d.world ~= 1 then
			task.wait(0.3)
			Shop.Teleport(player, d.world)
		else
			player:SetAttribute("World", 1)
		end
	end
	DataService.Loaded.Event:Connect(function(player)
		player.CharacterAdded:Connect(function(c) onChar(player, c) end)
		if player.Character then task.spawn(onChar, player, player.Character) end
	end)
	Players.PlayerRemoving:Connect(function(p) lastTravel[p] = nil end)
end

return Shop
