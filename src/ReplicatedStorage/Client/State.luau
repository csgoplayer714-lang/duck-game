-- Client-side mirror of the player's profile (read-only; the server is the authority).
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("Remotes")
local invoke = remotes:WaitForChild("Invoke")
local event = remotes:WaitForChild("Event")

local State = {}
State.Data = nil
State.KeyVersion = {} -- bumps every time a data key changes (lets panels skip needless rebuilds)
local listeners = {} -- [key] = {fn}
local eventHandlers = {} -- [name] = {fn}

function State.Request(action: string, ...)
	local ok, res = pcall(invoke.InvokeServer, invoke, action, ...)
	if not ok then return {ok = false, err = "Connection problem"} end
	return res or {ok = false}
end

-- Subscribe to changes of a data key ("*" = any)
function State.On(key: string, fn)
	listeners[key] = listeners[key] or {}
	table.insert(listeners[key], fn)
end

function State.OnEvent(name: string, fn)
	eventHandlers[name] = eventHandlers[name] or {}
	table.insert(eventHandlers[name], fn)
end

local function fire(key)
	for _, fn in listeners[key] or {} do task.spawn(fn, State.Data[key]) end
end

local function apply(payload)
	if not State.Data then return end
	for k, v in payload do
		State.Data[k] = v
		State.KeyVersion[k] = (State.KeyVersion[k] or 0) + 1
		fire(k)
	end
	for _, fn in listeners["*"] or {} do task.spawn(fn, payload) end
end

event.OnClientEvent:Connect(function(name, payload)
	if name == "Data" then
		apply(payload)
	else
		for _, fn in eventHandlers[name] or {} do task.spawn(fn, payload) end
	end
end)

function State.Load()
	local player = game:GetService("Players").LocalPlayer
	while true do
		if player:GetAttribute("DataLoaded") then
			local r = State.Request("GetData")
			if r.ok then
				State.Data = r.data
				State.MemoryOnly = r.memoryOnly
				return r.data
			end
		end
		task.wait(0.5)
	end
end

function State.DuckCount(): number
	local n = 0
	for _ in State.Data.ducks do n += 1 end
	return n
end

return State
