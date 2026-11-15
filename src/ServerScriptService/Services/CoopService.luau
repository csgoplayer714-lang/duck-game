-- Coop Field: every player owns a plot with a coop. Ducks put in the coop make Feathers over time
-- (online at full speed, offline at half speed for up to 8 hours). Feathers buy cosmetics.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local CoopData = require(Shared.CoopData)
local DuckModelBuilder = require(Shared.DuckModelBuilder)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)

local Coop = {}
local plotOf = {} -- [player] = index
local owner = {} -- [index] = player
Coop.IsCarrying = function() return false end -- set by Main (FishingService)
Coop.Teleport = nil -- set by Main (ShopService.Teleport)

local function plotModel(i)
	local map = workspace:FindFirstChild("Map")
	local f = map and map:FindFirstChild("CoopField")
	return f and f:FindFirstChild("Plots") and f.Plots:FindFirstChild("Plot_" .. i)
end

function Coop.Rate(d)
	local r = 0
	for _, uid in d.coop.ducks do
		local rec = d.ducks[uid]
		local duck = rec and DuckData.List[rec.id]
		if duck then r += CoopData.DuckRate(duck.Rarity, rec.l) end
	end
	return r -- feathers per minute
end

function Coop.CoinRate(d)
	local r = 0
	for _, uid in d.coop.ducks do
		local rec = d.ducks[uid]
		local duck = rec and DuckData.List[rec.id]
		if duck then r += CoopData.CoinRate(duck, rec.l) end
	end
	return r -- coins per minute
end

-- rebuild the ducks walking around a plot (everyone sees them)
local function refreshPlot(player)
	local i = plotOf[player]
	local m = i and plotModel(i)
	if not m then return end
	local d = DataService.Get(player)
	local holder = m:FindFirstChild("Ducks")
	if holder then holder:ClearAllChildren() end
	local sign = m:FindFirstChild("OwnerSign")
	local txt = sign and sign:FindFirstChild("OwnerText", true)
	if txt then txt.Text = if player.Parent then (player.DisplayName .. "'s Coop") else "Free plot" end
	m:SetAttribute("OwnerId", if player.Parent then player.UserId else 0)
	if not d or not holder or not player.Parent then return end
	for k, uid in d.coop.ducks do
		local rec = d.ducks[uid]
		local duck = rec and DuckData.List[rec.id]
		if duck then
			local ok, dm = pcall(DuckModelBuilder.Build, duck, {Lite = true, Scale = 0.85})
			if ok and dm then
				dm:SetAttribute("CoopSlot", k)
				dm:SetAttribute("AnimStyle", "swim")
				for _, p in dm:GetDescendants() do if p:IsA("BasePart") then p.CanQuery = false; p.CanCollide = false end end
				dm:PivotTo(m:GetPivot())
				dm.Parent = holder
			end
		end
	end
end
Coop.RefreshPlot = refreshPlot

local function push(player)
	local d = DataService.Get(player)
	if not d then return end
	player:SetAttribute("FeatherRate", Coop.Rate(d))
	player:SetAttribute("CoinRate", Coop.CoinRate(d))
	player:SetAttribute("CoinBank", math.floor(d.coop.cbank or 0))
	DataService.Push(player, "coop", "feathers")
end

local function assign(player)
	if plotOf[player] then return plotOf[player] end
	for i = 1, CoopData.PLOTS do
		if not owner[i] then
			owner[i] = player; plotOf[player] = i
			player:SetAttribute("CoopPlot", i)
			return i
		end
	end
	return nil
end

local function onLoaded(player)
	local d = DataService.Get(player)
	if not d then return end
	-- offline earnings
	local now = os.time()
	if d.coop.last > 0 and #d.coop.ducks > 0 then
		local away = math.clamp(now - d.coop.last, 0, CoopData.OFFLINE_MAX)
		local earned = Coop.Rate(d) * away / 60 * CoopData.OFFLINE_RATE
		local coins = Coop.CoinRate(d) * away / 60 * CoopData.OFFLINE_RATE
		if earned >= 1 then
			d.coop.bank += earned
			d.coop.cbank = (d.coop.cbank or 0) + coins
			task.delay(6, function()
				if player.Parent then Net.Fire(player, "Notify", {Text = string.format("\u{1FAB6} Your coop made %d Feathers and %d Coins while you were away! Collect them at your coop.", math.floor(earned), math.floor(coins)), Kind = "good"}) end
			end)
		end
	end
	d.coop.last = now
	assign(player)
	refreshPlot(player)
	push(player)
end

----------------------------------------------------------------- requests
local function inCoop(d, uid)
	for k, u in d.coop.ducks do if u == uid then return k end end
end

local function add(player, uid)
	local d = DataService.Get(player)
	if not d or typeof(uid) ~= "string" or not d.ducks[uid] then return {ok = false} end
	if inCoop(d, uid) then return {ok = false, err = "Already in your coop"} end
	if #d.coop.ducks >= d.coop.slots then return {ok = false, err = "Your coop is full - buy another slot!"} end
	table.insert(d.coop.ducks, uid)
	refreshPlot(player); push(player)
	return {ok = true}
end

local function remove(player, uid)
	local d = DataService.Get(player)
	if not d or typeof(uid) ~= "string" then return {ok = false} end
	local k = inCoop(d, uid)
	if not k then return {ok = false} end
	table.remove(d.coop.ducks, k)
	refreshPlot(player); push(player)
	return {ok = true}
end

-- fill the coop with the ducks that make the most feathers
local function auto(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local list = {}
	for uid, rec in d.ducks do
		local duck = DuckData.List[rec.id]
		if duck then table.insert(list, {uid = uid, r = CoopData.DuckRate(duck.Rarity, rec.l)}) end
	end
	table.sort(list, function(a, b) return a.r > b.r end)
	local pick = {}
	for k = 1, math.min(d.coop.slots, #list) do pick[k] = list[k].uid end
	d.coop.ducks = pick
	refreshPlot(player); push(player)
	return {ok = true, n = #pick}
end

local function collect(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local n = math.floor(d.coop.bank)
	local c = math.floor(d.coop.cbank or 0)
	if n < 1 and c < 1 then return {ok = false, err = "Nothing to collect yet - put ducks in your coop!"} end
	d.coop.bank -= n
	d.coop.cbank = (d.coop.cbank or 0) - c
	d.feathers += n
	if c > 0 then require(script.Parent.ProgressService).AddCoins(player, c) end
	push(player)
	DataService.Push(player, "coins", "stats", "quests")
	local m = plotOf[player] and plotModel(plotOf[player])
	local basket = m and m:FindFirstChild("FeatherBasket", true)
	local pe = basket and basket:FindFirstChild("FeatherGlow")
	if pe then pe:Emit(30) end
	return {ok = true, amount = n, coins = c, feathers = d.feathers}
end

local function upgrade(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local nxt = d.coop.slots + 1
	local cost = CoopData.SlotCost[nxt]
	if not cost then return {ok = false, err = "Your coop is already maxed!"} end
	if d.coins < cost then return {ok = false, err = "Not enough coins"} end
	d.coins -= cost
	d.coop.slots = nxt
	DataService.Push(player, "coins")
	push(player)
	return {ok = true, slots = nxt}
end

local last = {}
local function goCoop(player)
	if player:GetAttribute("InBattle") then return {ok = false, err = "Finish your battle first"} end
	if Coop.IsCarrying(player) then return {ok = false, err = "Get your duck out of the water first!"} end
	if last[player] and os.clock() - last[player] < 2 then return {ok = false, err = "Wait a moment"} end
	last[player] = os.clock()
	local i = assign(player)
	local char = player.Character
	if not i or not char then return {ok = false, err = "No free plot"} end
	local cf = CoopData.PlotCFrame(i) * CFrame.new(math.random(-3, 3), 3, -24) * CFrame.Angles(0, math.pi, 0)
	char:PivotTo(cf)
	player:SetAttribute("AtCoop", true)
	return {ok = true}
end

local function leaveCoop(player)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	if last[player] and os.clock() - last[player] < 2 then return {ok = false, err = "Wait a moment"} end
	last[player] = os.clock()
	player:SetAttribute("AtCoop", false)
	if Coop.Teleport then Coop.Teleport(player, d.world) end
	return {ok = true}
end

function Coop.Init()
	Net.On("CoopAdd", 6, 10, add)
	Net.On("CoopRemove", 6, 10, remove)
	Net.On("CoopAuto", 1, 3, auto)
	Net.On("CoopCollect", 2, 4, collect)
	Net.On("CoopUpgrade", 2, 3, upgrade)
	Net.On("GoCoop", 1, 2, goCoop)
	Net.On("LeaveCoop", 1, 2, leaveCoop)
	DataService.Loaded.Event:Connect(onLoaded)
	for _, p in Players:GetPlayers() do if DataService.Get(p) then task.spawn(onLoaded, p) end end
	Players.PlayerRemoving:Connect(function(p)
		local i = plotOf[p]
		local d = DataService.Get(p)
		if d then d.coop.last = os.time() end
		plotOf[p] = nil
		if i then owner[i] = nil end
		if i then
			local m = plotModel(i)
			if m then
				if m:FindFirstChild("Ducks") then m.Ducks:ClearAllChildren() end
				local txt = m:FindFirstChild("OwnerText", true)
				if txt then txt.Text = "Free plot" end
				m:SetAttribute("OwnerId", 0)
				m:SetAttribute("Bank", 0)
			end
		end
		last[p] = nil
	end)
	-- feathers tick every second; ducks that left the inventory drop out of the coop
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			tick += 1
			for p, i in plotOf do
				local d = DataService.Get(p)
				if d then
					local changed = false
					for k = #d.coop.ducks, 1, -1 do
						if not d.ducks[d.coop.ducks[k]] then table.remove(d.coop.ducks, k); changed = true end
					end
					if changed then refreshPlot(p); push(p) end
					d.coop.bank += Coop.Rate(d) / 60
					d.coop.cbank = (d.coop.cbank or 0) + Coop.CoinRate(d) / 60
					p:SetAttribute("CoinBank", math.floor(d.coop.cbank))
					d.coop.last = os.time()
					p:SetAttribute("FeatherBank", math.floor(d.coop.bank))
					local m = plotModel(i)
					if m then m:SetAttribute("Bank", math.floor(d.coop.bank)) end
				end
			end
		end
	end)
end

return Coop
