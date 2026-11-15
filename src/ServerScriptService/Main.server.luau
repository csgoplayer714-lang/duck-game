-- DUCK RNG server bootstrap
local Services = script.Parent:WaitForChild("Services")
local Net = require(Services.Net)
local DataService = require(Services.DataService)
local Progress = require(Services.ProgressService)
local Inventory = require(Services.InventoryService)
local Shop = require(Services.ShopService)
local Fishing = require(Services.FishingService)
local Boss = require(Services.BossService)
local PvP = require(Services.PvPService)
local Leaderboard = require(Services.LeaderboardService)
local Announce = require(Services.AnnounceService)
local LuckEvents = require(Services.LuckEventService)
local Coop = require(Services.CoopService)
local CosmeticSvc = require(Services.CosmeticService)

Progress.Init()
Inventory.Init()
Shop.Init()
Fishing.Init()
Boss.Init()
PvP.Init()
Leaderboard.Init()
Announce.Init()
LuckEvents.Init()
Coop.IsCarrying = Fishing.IsCarrying
Coop.Teleport = Shop.Teleport
Coop.Init()
CosmeticSvc.Init()
if game:GetService("RunService"):IsStudio() then
	-- Studio-only: lets tests trigger a luck event
	local b = Instance.new("BindableFunction"); b.Name = "DevLuckEvent"
	b.OnInvoke = function(mult, dur) LuckEvents.Start(mult or 2, dur or 60) return true end
	b.Parent = game.ServerScriptService
	-- Studio-only: grant ducks to a player for testing battles/visuals (server-side bindable, unreachable by clients)
	local g = Instance.new("BindableFunction"); g.Name = "DevGrant"
	g.OnInvoke = function(player, ids)
		for _, id in ids do Inventory.Grant(player, id) end
		DataService.PushAll(player)
		return true
	end
	g.Parent = game.ServerScriptService
	-- Studio-only: give feathers/coins for testing the coop + cosmetics
	local fe = Instance.new("BindableFunction"); fe.Name = "DevCurrency"
	fe.OnInvoke = function(player, feathers, coins)
		local d = DataService.Get(player)
		if not d then return false end
		d.feathers += feathers or 0
		d.coins += coins or 0
		DataService.Push(player, "feathers", "coins")
		return true
	end
	fe.Parent = game.ServerScriptService
end
Progress.OnRebirth = function(player) Shop.GiveRod(player) end

Net.On("GetData", 1, 5, function(player)
	local d = DataService.Get(player)
	if not d then return {ok = false, err = "Loading"} end
	return {ok = true, data = d, memoryOnly = DataService.IsMemoryOnly()}
end)

-- Data must init last so every Loaded listener is connected first
DataService.Init()
print("[DuckRNG] Server ready")
