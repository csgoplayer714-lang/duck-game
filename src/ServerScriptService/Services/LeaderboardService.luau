-- Global leaderboards (OrderedDataStore) for rebirths, ducks caught and PvP rating, shown on in-world boards
-- and in the UI. Falls back to in-server rankings when DataStores are unavailable (e.g. Studio without API access).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)

local LB = {}
local BOARDS = {
	{Key = "Rebirths", Store = "DuckRNG_LB_Rebirths", Get = function(d) return d.rebirths end},
	{Key = "Caught",   Store = "DuckRNG_LB_Caught",   Get = function(d) return d.stats.caught end},
	{Key = "PvP",      Store = "DuckRNG_LB_PvP",      Get = function(d) return d.pvp.rating end},
}
local stores = {}
local cache = {} -- [key] = {{name, value}}
local names = {}

local function nameOf(userId)
	if names[userId] then return names[userId] end
	local p = Players:GetPlayerByUserId(userId)
	if p then names[userId] = p.DisplayName return names[userId] end
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then n else ("Player " .. userId)
	return names[userId]
end

local function abbreviate(n)
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(n)
end

local function drawOne(list, rows)
	for _, c in list:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
	for i = 1, 10 do
		local row = rows[i]
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 0.092)
		t.BackgroundTransparency = if i % 2 == 0 then 0.85 else 0.92
		t.BackgroundColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.LayoutOrder = i
		t.TextColor3 = if i == 1 then Color3.fromRGB(255, 215, 60) elseif i == 2 then Color3.fromRGB(220, 225, 235) elseif i == 3 then Color3.fromRGB(230, 150, 80) else Color3.new(1, 1, 1)
		t.Text = if row then string.format("  #%d  %s  -  %s", i, row.name, abbreviate(row.value)) else string.format("  #%d  ---", i)
		t.Parent = list
	end
end
-- every world has its own copy of each board
local function draw(key, rows)
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	for _, wf in map:GetChildren() do
		local board = wf:FindFirstChild("Leaderboard_" .. key)
		local list = board and board:FindFirstChild("Board") and board.Board:FindFirstChild("BoardGui")
		list = list and list:FindFirstChildOfClass("Frame") and list:FindFirstChildOfClass("Frame"):FindFirstChild("List")
		if list then drawOne(list, rows) end
	end
end

local function refresh()
	for _, b in BOARDS do
		local store = stores[b.Key]
		-- write current players' values
		for _, p in Players:GetPlayers() do
			local d = DataService.Get(p)
			if d and store and not DataService.IsMemoryOnly() then
				pcall(store.SetAsync, store, tostring(p.UserId), math.floor(b.Get(d)))
			end
		end
		local rows = {}
		local ok = false
		if store and not DataService.IsMemoryOnly() then
			ok = pcall(function()
				local page = store:GetSortedAsync(false, 10):GetCurrentPage()
				for _, entry in page do
					table.insert(rows, {name = nameOf(tonumber(entry.key)), value = entry.value})
				end
			end)
		end
		if not ok then
			rows = {}
			for _, p in Players:GetPlayers() do
				local d = DataService.Get(p)
				if d then table.insert(rows, {name = p.DisplayName, value = b.Get(d)}) end
			end
			table.sort(rows, function(x, y) return x.value > y.value end)
		end
		cache[b.Key] = rows
		draw(b.Key, rows)
	end
end

function LB.Init()
	for _, b in BOARDS do
		local ok, s = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, b.Store)
		if ok then stores[b.Key] = s end
	end
	Net.On("GetLeaderboards", 0.5, 2, function() return {ok = true, boards = cache} end)
	task.spawn(function()
		task.wait(8)
		while true do
			local ok, err = pcall(refresh)
			if not ok then warn("[Leaderboard] " .. tostring(err)) end
			task.wait(75)
		end
	end)
end

LB.Refresh = refresh
return LB
