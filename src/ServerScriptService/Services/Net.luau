-- Single validated entry point for client requests.
-- Every action is registered with a handler and a rate limit; unknown actions and spam are rejected.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Net = {}
local handlers = {}
local limits = {}
local buckets = {} -- [player][action] = {tokens, last}

local remotes = RS:WaitForChild("Remotes")
local invoke = remotes:FindFirstChild("Invoke") or Instance.new("RemoteFunction")
invoke.Name = "Invoke"; invoke.Parent = remotes
local event = remotes:FindFirstChild("Event") or Instance.new("RemoteEvent")
event.Name = "Event"; event.Parent = remotes

-- perSecond: sustained rate, burst: max tokens
function Net.On(action: string, perSecond: number, burst: number, fn)
	handlers[action] = fn
	limits[action] = {rate = perSecond, burst = burst}
end

local function allow(player, action)
	local lim = limits[action]
	buckets[player] = buckets[player] or {}
	local b = buckets[player][action]
	local now = os.clock()
	if not b then
		b = {tokens = lim.burst, last = now}
		buckets[player][action] = b
	end
	b.tokens = math.min(lim.burst, b.tokens + (now - b.last) * lim.rate)
	b.last = now
	if b.tokens < 1 then return false end
	b.tokens -= 1
	return true
end

invoke.OnServerInvoke = function(player, action, ...)
	if typeof(action) ~= "string" or not handlers[action] then
		return {ok = false, err = "Unknown action"}
	end
	if not allow(player, action) then
		return {ok = false, err = "Slow down!"}
	end
	local ok, result = pcall(handlers[action], player, ...)
	if not ok then
		warn("[Net] " .. action .. " failed for " .. player.Name .. ": " .. tostring(result))
		return {ok = false, err = "Server error"}
	end
	if result == nil then return {ok = true} end
	return result
end

function Net.Fire(player: Player, name: string, payload: any)
	if player.Parent then event:FireClient(player, name, payload) end
end
function Net.FireAll(name: string, payload: any)
	event:FireAllClients(name, payload)
end

-- Type helpers for handlers
function Net.Int(v, lo, hi): number?
	if typeof(v) ~= "number" or v ~= v or v % 1 ~= 0 then return nil end
	if v < lo or v > hi then return nil end
	return v
end
function Net.Str(v, maxLen): string?
	if typeof(v) ~= "string" or #v > maxLen then return nil end
	return v
end

Players.PlayerRemoving:Connect(function(p) buckets[p] = nil end)

return Net
