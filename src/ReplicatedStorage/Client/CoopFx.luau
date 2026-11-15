-- Client-side life for the new map features:
--  * coop ducks waddle around their plot (every client animates every plot nearby)
--  * your basket shows how many Feathers are ready
--  * cosmetics animate on every character (propellers spin, wings flap, halos float...)
--  * the rare duck showcase shows YOUR odds with your current luck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)
local Stats = require(Shared.Stats)
local CoopData = require(Shared.CoopData)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local new = UI.new

local Fx = {}
local player = Players.LocalPlayer

---------------------------------------------------------------- cosmetics
local ANIM = {}
ANIM.spin = function(g, t, move) if g == "a" then return CFrame.Angles(0, t * (8 + move * 14), 0) end end
ANIM.bob = function(g, t) if g == "a" then return CFrame.new(0, math.abs(math.sin(t * 4)) * 0.12, 0) * CFrame.Angles(math.sin(t * 2) * 0.12, math.sin(t * 0.9) * 0.4, math.sin(t * 3) * 0.1) end end
ANIM.sway = function(g, t) if g == "a" then return CFrame.Angles(math.sin(t * 2.4) * 0.12, 0, math.sin(t * 3) * 0.28) end end
ANIM.float = function(g, t) if g == "a" then return CFrame.new(0, math.sin(t * 2.2) * 0.14, 0) * CFrame.Angles(math.sin(t * 1.3) * 0.06, math.sin(t * 0.8) * 0.25, 0) end end
ANIM.orbit = function(g, t) if g == "a" then return CFrame.new(0, math.sin(t * 2) * 0.05, 0) * CFrame.Angles(0, t * 2.2, 0) end end
ANIM.halo = function(g, t) if g == "a" then return CFrame.new(0, 0.08 + math.sin(t * 2) * 0.1, 0) * CFrame.Angles(math.sin(t * 1.3) * 0.08, t * 1.4, 0) end end
ANIM.flap = function(g, t, move)
	local s = math.sin(t * (3 + move * 4)) * (0.32 + move * 0.2)
	if g == "wl" then return CFrame.Angles(0, -s, s * 0.4) elseif g == "wr" then return CFrame.Angles(0, s, -s * 0.4) end
end
ANIM.dragon = function(g, t, move)
	local s = math.sin(t * (2 + move * 3)) * (0.45 + move * 0.25)
	if g == "wl" then return CFrame.Angles(0, -s * 0.8, s * 0.6) elseif g == "wr" then return CFrame.Angles(0, s * 0.8, -s * 0.6) end
end
ANIM.cosmic = function(g, t) if g == "a" then return CFrame.Angles(math.sin(t * 0.5) * 0.15, t * 0.9, 0) end end

local motorCache = {} -- [Accessory] = {anim, {motor, group}}
local function motorsOf(acc)
	local c = motorCache[acc]
	if c then return c end
	c = {anim = acc:GetAttribute("Anim"), list = {}}
	for _, d in acc:GetDescendants() do
		if d:IsA("Motor6D") and d.Name:sub(1, 8) == "CosAnim_" then table.insert(c.list, {d, d.Name:sub(9)}) end
	end
	motorCache[acc] = c
	acc.AncestryChanged:Connect(function(_, parent) if not parent then motorCache[acc] = nil end end)
	return c
end

local function animateCosmetics(t)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - camPos).Magnitude > 160 then continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local move = hum and math.clamp(hum.MoveDirection.Magnitude, 0, 1) or 0
		for _, acc in char:GetChildren() do
			if acc:IsA("Accessory") and acc.Name:sub(1, 9) == "Cosmetic_" then
				local c = motorsOf(acc)
				local fn = ANIM[c.anim]
				if fn then
					local tt = t + (p.UserId % 97) * 0.37
					for _, e in c.list do
						local cf = fn(e[2], tt, move)
						if cf then e[1].Transform = cf end
					end
				end
			end
		end
	end
end

---------------------------------------------------------------- coop field
local function plots()
	local map = workspace:FindFirstChild("Map")
	local f = map and map:FindFirstChild("CoopField")
	return f and f:FindFirstChild("Plots")
end

local function animateCoopDucks(t)
	local pf = plots()
	if not pf then return end
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	if (camPos - CoopData.FIELD_ORIGIN).Magnitude > 260 then return end
	local parts, cfs = {}, {}
	for _, plot in pf:GetChildren() do
		local ducks = plot:FindFirstChild("Ducks")
		local i = plot:GetAttribute("PlotIndex")
		if not ducks or not i then continue end
		local base = CoopData.PlotCFrame(i)
		for _, m in ducks:GetChildren() do
			local root = m.PrimaryPart
			if not root then continue end
			local k = m:GetAttribute("CoopSlot") or 1
			local function at(tt)
				return base * CFrame.new(math.sin(tt * 0.33 + k * 1.7) * 15, 0.35, -4 + math.cos(tt * 0.26 + k * 2.3) * 9)
			end
			local a, b = at(t), at(t + 0.2)
			local dir = (b.Position - a.Position) * Vector3.new(1, 0, 1)
			local hop = math.abs(math.sin(t * 7 + k)) * 0.18
			local cf = if dir.Magnitude > 1e-3 then CFrame.lookAt(a.Position, a.Position + dir) else a
			table.insert(parts, root)
			table.insert(cfs, cf * CFrame.new(0, hop, 0) * CFrame.Angles(0, 0, math.sin(t * 7 + k) * 0.12))
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end

local basketGui
local function updateBasket()
	local pf = plots()
	local i = player:GetAttribute("CoopPlot")
	local plot = pf and i and pf:FindFirstChild("Plot_" .. i)
	local basket = plot and plot:FindFirstChild("FeatherBasket", true)
	if not basket then return end
	if not basketGui or basketGui.Adornee ~= basket then
		if basketGui then basketGui:Destroy() end
		basketGui = new("BillboardGui", {Parent = player:WaitForChild("PlayerGui"), Adornee = basket, Size = UDim2.fromOffset(230, 56), StudsOffset = Vector3.new(0, 3.2, 0), AlwaysOnTop = true, MaxDistance = 120, ResetOnSpawn = false})
		local f = new("Frame", {Parent = basketGui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.Bg})
		UI.Corner(f, 10); UI.Stroke(f, UI.C.Outline, 3)
		UI.Icon(f, "feather", UDim2.fromOffset(48, 48), UDim2.fromOffset(2, 4))
		UI.Label(f, "0", UDim2.new(1, -60, 0, 30), UDim2.fromOffset(54, 4), {Name = "Amount", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 190, 210)})
		UI.Label(f, "ready to collect", UDim2.new(1, -60, 0, 18), UDim2.fromOffset(54, 34), {Name = "Sub", TextXAlignment = Enum.TextXAlignment.Left, Font = UI.Body, TextColor3 = UI.C.Sub})
	end
	local amt = basketGui:FindFirstChild("Amount", true)
	local txt = UI.Abbrev(player:GetAttribute("FeatherBank") or 0) .. "  <font color=\"#FFD84A\">\u{1F4B0}" .. UI.Abbrev(player:GetAttribute("CoinBank") or 0) .. "</font>"
	if amt and amt.Text ~= txt then amt.Text = txt end
	local sub = basketGui:FindFirstChild("Sub", true)
	if sub then
		local rate = player:GetAttribute("FeatherRate") or 0
		local crate = player:GetAttribute("CoinRate") or 0
		local s = if rate > 0 then string.format("+%s & +%s coins / min", UI.Abbrev(math.floor(rate * 10 + 0.5) / 10), UI.Abbrev(math.floor(crate * 10 + 0.5) / 10)) else "put ducks in your coop!"
		if sub.Text ~= s then sub.Text = s end
	end
end

---------------------------------------------------------------- showcase: your odds
local oddsGuis = {}
local function fmt(n)
	n = math.max(1, math.floor(n + 0.5))
	local s = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (s:gsub("^,", ""))
end
local function updateOdds()
	local d = State.Data
	if not d then return end
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	for _, wf in map:GetChildren() do
		local sc = wf:FindFirstChild("Showcase")
		if not sc then continue end
		for _, sign in sc:GetChildren() do
			local r = sign:IsA("BasePart") and sign:GetAttribute("ShowcaseTier")
			if not r then continue end
			local world = sign:GetAttribute("WorldId")
			local g = oddsGuis[sign]
			if not g then
				g = new("BillboardGui", {Parent = player:WaitForChild("PlayerGui"), Adornee = sign, Size = UDim2.fromOffset(200, 40), StudsOffset = Vector3.new(0, 2.8, 0), MaxDistance = 90, ResetOnSpawn = false, LightInfluence = 0})
				local l = UI.Label(g, "", UDim2.fromScale(1, 1), nil, {StrokeTh = 2.5, TextColor3 = Color3.fromRGB(150, 255, 160)})
				l.Name = "T"
				oddsGuis[sign] = g
			end
			local tier = Rarity.List[r]
			local luck = math.clamp(Stats.Luck(d), 1, Rarity.MAX_LUCK)
			local mult = luck * (if r >= 4 then Stats.WorldBoost(d, world) else 1) * (if r >= 8 then math.clamp(Stats.HighBoost(d) or 1, 1, 10) else 1)
			local txt = "Your odds: 1 in " .. fmt(tier.OneIn / mult)
			if g.T.Text ~= txt then g.T.Text = txt end
		end
	end
end

function Fx.Init()
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		animateCosmetics(t)
		animateCoopDucks(workspace:GetServerTimeNow())
	end)
	task.spawn(function()
		while true do
			pcall(updateBasket)
			task.wait(0.5)
		end
	end)
	task.spawn(function()
		while true do
			pcall(updateOdds)
			task.wait(2)
		end
	end)
end

return Fx
