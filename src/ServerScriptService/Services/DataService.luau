-- Player data: load/validate/save with session locking, autosave, retries and BindToClose.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("Shared")
local DuckData = require(Shared.DuckData)
local Config = require(Shared.Config)
local WorldData = require(Shared.WorldData)
local Net = require(script.Parent.Net)

local DataService = {}
DataService.Profiles = {} :: {[Player]: any}
DataService.Loaded = Instance.new("BindableEvent")

local STORE_NAME = "DuckRNG_Players_v1"
local LOCK_TIMEOUT = 300
local AUTOSAVE = 90
local JOB = if RunService:IsStudio() then "studio" else game.JobId

local store
local storeErr
local storeOk = pcall(function() store = DataStoreService:GetDataStore(STORE_NAME) end)
if not storeOk then
	storeErr = select(2, pcall(function() DataStoreService:GetDataStore(STORE_NAME) end))
end
local memoryOnly = not storeOk
if memoryOnly then
	warn("[DataService] DataStores unavailable (" .. tostring(storeErr) .. ") - using temporary data. Publish the place and enable Studio API access to save.")
end

local function default()
	return {
		v = 1, coins = 0, gems = 0, level = 1, xp = 0, skillPoints = 0, skills = {},
		rebirths = 0, essence = 0,
		ducks = {}, nextUid = 1, team = {}, discovered = {},
		rods = {["1"] = true}, rod = 1, worlds = {["1"] = true}, world = 1,
		quests = {}, achievements = {},
		stats = {caught = 0, bosses = 0, king = 0, pvpWins = 0, pvpLosses = 0, best = 0, coinsEarned = 0, rebirths = 0, species = 0},
		bossesBeaten = {},
		daily = {last = 0, streak = 0},
		pvp = {rating = Config.PVP_START_RATING, peak = Config.PVP_START_RATING, streak = 0, bestStreak = 0, season = Config.SeasonId(), titles = {}},
		title = "",
		settings = {music = true, sfx = true, lowFx = false, tutorialDone = false},
		feathers = 0,
		coop = {slots = 3, ducks = {}, bank = 0, cbank = 0, last = 0},
		cosmetics = {owned = {}, equipped = {}},
	}
end
DataService.Default = default

local function num(v, d, lo, hi)
	if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return d end
	return math.clamp(v, lo or -1e15, hi or 1e15)
end

-- Repairs/validates loaded data. Never trusts stored shape blindly.
function DataService.Validate(d)
	local def = default()
	if typeof(d) ~= "table" then return def end
	for k, v in def do
		if typeof(d[k]) ~= typeof(v) then d[k] = v end
	end
	for k, v in def.stats do d.stats[k] = num(d.stats[k], v, 0) end
	for k, v in def.pvp do if typeof(d.pvp[k]) ~= typeof(v) then d.pvp[k] = v end end
	for k, v in def.settings do if typeof(d.settings[k]) ~= typeof(v) then d.settings[k] = v end end
	d.coins = math.floor(num(d.coins, 0, 0)); d.gems = math.floor(num(d.gems, 0, 0))
	d.level = math.floor(num(d.level, 1, 1, Config.MAX_LEVEL)); d.xp = num(d.xp, 0, 0)
	d.skillPoints = math.floor(num(d.skillPoints, 0, 0, 10000)); d.rebirths = math.floor(num(d.rebirths, 0, 0, 10000))
	d.essence = math.floor(num(d.essence, 0, 0)); d.nextUid = math.floor(num(d.nextUid, 1, 1))
	-- ducks
	local count = 0
	for uid, duck in d.ducks do
		if typeof(uid) ~= "string" or typeof(duck) ~= "table" or not DuckData.List[duck.id] then
			d.ducks[uid] = nil
		else
			duck.l = math.floor(num(duck.l, 1, 1, DuckData.MAX_LEVEL))
			duck.s = math.floor(num(duck.s, 0, 0, Config.MAX_STARS))
			duck.lock = duck.lock == true
			count += 1
		end
	end
	-- team must reference owned ducks, no duplicates
	local seen, team = {}, {}
	for _, uid in d.team do
		if typeof(uid) == "string" and d.ducks[uid] and not seen[uid] and #team < Config.TEAM_SIZE then
			seen[uid] = true; table.insert(team, uid)
		end
	end
	d.team = team
	-- skills
	for key, lvl in d.skills do
		local s = Config.SkillByKey[key]
		if not s then d.skills[key] = nil else d.skills[key] = math.floor(num(lvl, 0, 0, s.Max)) end
	end
	-- rods / worlds use string keys (DataStore-safe)
	for k in d.rods do if not Config.Rods[tonumber(k) or 0] then d.rods[k] = nil end end
	d.rods["1"] = true
	if not d.rods[tostring(d.rod)] then d.rod = 1 end
	for k in d.worlds do if not WorldData.List[tonumber(k) or 0] then d.worlds[k] = nil end end
	d.worlds["1"] = true
	if not d.worlds[tostring(d.world)] then d.world = 1 end
	-- species discovered
	local species = 0
	for k, v in d.discovered do
		if not DuckData.List[tonumber(k) or 0] then d.discovered[k] = nil else d.discovered[k] = math.floor(num(v, 1, 1)); species += 1 end
	end
	d.stats.species = species
	if typeof(d.title) ~= "string" then d.title = "" end
	-- coop: slots, ducks must be owned (no duplicates), bank/feathers sane
	d.feathers = math.floor(num(d.feathers, 0, 0))
	for k, v in def.coop do if typeof(d.coop[k]) ~= typeof(v) then d.coop[k] = v end end
	d.coop.slots = math.floor(num(d.coop.slots, 3, 3, 12))
	d.coop.bank = num(d.coop.bank, 0, 0)
	d.coop.cbank = num(d.coop.cbank, 0, 0)
	d.coop.last = num(d.coop.last, 0, 0)
	local cseen, clist = {}, {}
	for _, uid in d.coop.ducks do
		if typeof(uid) == "string" and d.ducks[uid] and not cseen[uid] and #clist < d.coop.slots then cseen[uid] = true; table.insert(clist, uid) end
	end
	d.coop.ducks = clist
	-- cosmetics: only real items, equipped must be owned
	if typeof(d.cosmetics.owned) ~= "table" then d.cosmetics.owned = {} end
	if typeof(d.cosmetics.equipped) ~= "table" then d.cosmetics.equipped = {} end
	local okCos, Cos = pcall(require, Shared:FindFirstChild("Cosmetics"))
	if okCos and Cos then
		for id in d.cosmetics.owned do if not Cos.ById[id] then d.cosmetics.owned[id] = nil end end
		for slot, id in d.cosmetics.equipped do
			local c = Cos.ById[id]
			if not c or c.Slot ~= slot or not d.cosmetics.owned[id] then d.cosmetics.equipped[slot] = nil end
		end
	end
	return d
end

local function key(player) return "p_" .. player.UserId end

local function loadAsync(player)
	if memoryOnly or not storeOk then return default(), false end
	local result, locked
	for attempt = 1, 5 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				local now = os.time()
				if old and old.lock and old.lock.job ~= JOB and now - (old.lock.t or 0) < LOCK_TIMEOUT and attempt < 5 then
					locked = true
					return nil -- abort write, try again
				end
				locked = false
				old = old or {data = default()}
				old.lock = {job = JOB, t = now}
				result = old.data
				return old
			end)
		end)
		if ok and not locked then return result, true end
		if not ok then
			warn("[DataService] Load failed (" .. attempt .. "): " .. tostring(err))
			if string.find(tostring(err), "StudioAccessToApisNotAllowed") or string.find(tostring(err), "403") or string.find(tostring(err), "publish") then
				memoryOnly = true
				warn("[DataService] DataStores unavailable in Studio - using temporary memory data. Enable 'Studio Access to API Services' to test saving.")
				return default(), false
			end
		end
		task.wait(if locked then 3 else 2 ^ attempt)
	end
	return nil, false
end

local function saveAsync(player, profile, release)
	if memoryOnly or not storeOk or not profile.CanSave then return true end
	local data = profile.Data
	for attempt = 1, 4 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				if old and old.lock and old.lock.job ~= JOB and os.time() - (old.lock.t or 0) < LOCK_TIMEOUT then
					return nil -- another server owns the session; do not overwrite
				end
				return {data = data, lock = if release then nil else {job = JOB, t = os.time()}, saved = os.time()}
			end)
		end)
		if ok then return true end
		warn("[DataService] Save failed (" .. attempt .. "): " .. tostring(err))
		task.wait(2 ^ attempt)
	end
	return false
end

function DataService.Get(player: Player)
	local p = DataService.Profiles[player]
	return p and p.Data
end

-- Push changed keys to the client (sanitized snapshot of those keys)
local function syncTeamAttr(player, d)
	local ids = {}
	for _, uid in d.team do
		local rec = d.ducks[uid]
		if rec then table.insert(ids, tostring(rec.id)) end
	end
	player:SetAttribute("TeamDucks", table.concat(ids, ","))
end
DataService.SyncTeam = syncTeamAttr

function DataService.Push(player: Player, ...)
	local d = DataService.Get(player)
	if not d then return end
	local payload = {}
	for _, k in {...} do
		payload[k] = d[k]
		if k == "team" or k == "ducks" then syncTeamAttr(player, d) end
	end
	Net.Fire(player, "Data", payload)
end

function DataService.PushAll(player: Player)
	local d = DataService.Get(player)
	if d then Net.Fire(player, "Data", d); syncTeamAttr(player, d) end
end

local function onJoin(player)
	local data, canSave = loadAsync(player)
	if not player.Parent then return end
	if not data then
		player:Kick("Your duck data couldn't be loaded. Please rejoin in a moment.")
		return
	end
	data = DataService.Validate(data)
	DataService.Profiles[player] = {Data = data, CanSave = canSave, Joined = os.time()}
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"
	local c = Instance.new("IntValue"); c.Name = "Caught"; c.Value = data.stats.caught; c.Parent = ls
	local r = Instance.new("IntValue"); r.Name = "Rebirths"; r.Value = data.rebirths; r.Parent = ls
	ls.Parent = player
	syncTeamAttr(player, data)
	player:SetAttribute("DataLoaded", true)
	DataService.Loaded:Fire(player, data)
end

function DataService.UpdateLeaderstats(player)
	local d = DataService.Get(player)
	local ls = player:FindFirstChild("leaderstats")
	if d and ls then
		ls.Caught.Value = d.stats.caught
		ls.Rebirths.Value = d.rebirths
	end
end

local function onLeave(player)
	local profile = DataService.Profiles[player]
	if not profile then return end
	saveAsync(player, profile, true)
	DataService.Profiles[player] = nil
end

function DataService.Init()
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in Players:GetPlayers() do task.spawn(onJoin, p) end
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for player, profile in DataService.Profiles do
				task.spawn(saveAsync, player, profile, false)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player, profile in DataService.Profiles do
			pending += 1
			task.spawn(function()
				saveAsync(player, profile, true)
				pending -= 1
			end)
		end
		local t = os.clock()
		while pending > 0 and os.clock() - t < 25 do task.wait(0.2) end
	end)
end

function DataService.IsMemoryOnly() return memoryOnly end

return DataService
