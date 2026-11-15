-- DUCK RNG client bootstrap
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Client = RS:WaitForChild("Client")
local UI = require(Client.UIKit)
local State = require(Client.State)
local Panels = require(Client.Panels)
local HUD = require(Client.HUD)
local Effects = require(Client.Effects)
local Fishing = require(Client.Fishing)
local WorldFx = require(Client.WorldFx)
local BattleView = require(Client.BattleView)
local PanelDucks = require(Client.PanelDucks)
local PanelMisc = require(Client.PanelMisc)
local WorldData = require(RS.Shared.WorldData)
local FP = require(Client.FirstPerson)
local Followers = require(Client.Followers)
local RigAnimator = require(Client.RigAnimator)
local PanelCoop = require(Client.PanelCoop)
local CoopFx = require(Client.CoopFx)
local Music = require(Client.Music)
local Tutorial = require(Client.Tutorial)

-- ScreenGui with a scaled root so every offset-based layout fits any screen
local gui = Instance.new("ScreenGui")
gui.Name = "DuckRNG"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- keep everything out of phone notches / rounded corners / the home indicator
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Scaled"
root.BackgroundTransparency = 1
root.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = root
local function rescale()
	local vp = gui.AbsoluteSize -- the safe area, not the whole screen
	if vp.X < 10 then vp = workspace.CurrentCamera.ViewportSize end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local s = math.min(vp.X / 1366, vp.Y / 768)
	-- phones: never shrink below what a thumb can hit / eyes can read
	s = math.clamp(s, if touch then 0.5 else 0.5, 1.2)
	if touch then s = math.max(s, math.min(vp.X / 1300, vp.Y / 700)) end
	scale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

-- loading screen
local loading = UI.new("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.Bg, ZIndex = 100})
UI.Gradient(loading, Color3.fromRGB(60, 150, 255), Color3.fromRGB(30, 40, 110), 90)
local title = UI.Label(loading, "\u{1F986} DUCK RNG", UDim2.fromScale(0.6, 0.16), UDim2.fromScale(0.2, 0.3), {ZIndex = 101, StrokeTh = 5, TextColor3 = UI.C.Yellow})
UI.Label(loading, "The Ultimate Duck Hunt", UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.25, 0.47), {ZIndex = 101, StrokeTh = 3})
local loadText = UI.Label(loading, "Filling the ponds...", UDim2.fromScale(0.4, 0.04), UDim2.fromScale(0.3, 0.62), {ZIndex = 101, Font = UI.Body})
task.spawn(function()
	local s = UI.new("UIScale", {Parent = title})
	while loading.Parent do
		UI.Tween(s, 0.6, {Scale = 1.06}, Enum.EasingStyle.Sine); task.wait(0.6)
		UI.Tween(s, 0.6, {Scale = 1}, Enum.EasingStyle.Sine); task.wait(0.6)
	end
end)

State.Load()
loadText.Text = "Quack!"

Panels.Init(root)
HUD.Build(root)
Effects.Init(root)
PanelDucks.Register()
PanelMisc.Register()
PanelCoop.Register()
BattleView.Init(root)
BattleView.Register()
Fishing.Init(root)
WorldFx.Init()
FP.Init(root)
Followers.Init()
RigAnimator.Init()
CoopFx.Init()
FP.AddWatcher(function() return Panels.Current() ~= nil end)
FP.AddWatcher(function() return Effects.IsRevealing() end)
FP.AddWatcher(function() return player:GetAttribute("InBattleView") == true end)
FP.AddWatcher(function() return Tutorial.Active end)

-- settings
UI.SfxEnabled = State.Data.settings.sfx
WorldFx.LowFx = State.Data.settings.lowFx
PanelMisc.OnLowFx = function(v) WorldFx.LowFx = v end
-- background music (follows hunting / chase / coop / battle)
Music.IsCarrying = Fishing.IsCarrying
Music.World = function() return State.Data and State.Data.world or 1 end
Music.Enabled = State.Data.settings.music ~= false
Music.Init()
PanelMisc.OnMusic = function(v) Music.SetEnabled(v) end

-- server events
State.OnEvent("Notify", function(p) UI.Toast(p.Text, p.Kind) end)
State.OnEvent("LevelUp", Effects.LevelUp)
State.OnEvent("Achievement", Effects.Achievement)
State.OnEvent("Announce", function(p)
	-- your own catches already get the big reveal; still show spawn alerts and others' catches
	if p.UserId == player.UserId and p.Kind == "catch" then
		if p.Rarity >= 8 then Effects.Announce(p) end
		return
	end
	Effects.Announce(p)
end)
State.OnEvent("RebirthFx", function(p) task.spawn(Effects.Rebirth, p) end)
State.OnEvent("LuckEvent", function(p)
	Effects.Flash(Color3.fromRGB(120, 255, 140), 0.5)
	UI.Chime(8, 0.9)
	Effects.Confetti(60, {UI.C.Green, Color3.fromRGB(180, 255, 160), UI.C.Gold})
end)

-- replace Roblox's hotbar (it overlapped the cast button) with our own rod toggle
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY then
		if not Fishing.Busy() then HUD.ToggleRod() end
	end
end)

-- world prompts
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then return end
	local action = prompt:GetAttribute("Action")
	if action == "Shop" then Panels.Open("Shop")
	elseif action == "Collection" then Panels.Open("Collection", "Index")
	elseif action == "PvP" then Panels.Open("Battle", "PvP")
	elseif action == "Boss" then Panels.Open("Battle", "Bosses")
	elseif action == "Rebirth" then Panels.Open("Rebirth")
	elseif action == "Quests" then Panels.Open("Quests")
	elseif action == "Daily" then Panels.Open("Daily")
	elseif action == "Worlds" then Panels.Open("Worlds")
	elseif action == "Style" then Panels.Open("Style")
	elseif action == "CoopCollect" then
		local r = State.Request("CoopCollect")
		if r.ok then UI.Sound("coins", 1, 0.7); UI.Chime(5, 1.1); UI.Toast("+" .. UI.Abbrev(r.amount) .. " Feathers & +" .. UI.Abbrev(r.coins or 0) .. " Coins!", "good") else UI.Toast(r.err or "Nothing yet", "warn") end
	elseif action == "Coop" then
		if player:GetAttribute("AtCoop") then Panels.Open("Coop") else
			local r = State.Request("GoCoop")
			if not r.ok then UI.Toast(r.err or "Can't go there now", "warn") else UI.Sound("swoosh", 0.8, 0.6) end
		end
	elseif action == "LeaveCoop" then
		local r = State.Request("LeaveCoop")
		if r.ok then UI.Sound("swoosh", 0.8, 0.6) else UI.Toast(r.err or "Wait a moment", "warn") end
	elseif action == "World" then
		local id = prompt:GetAttribute("WorldId")
		if State.Data.worlds[tostring(id)] then
			local r = State.Request("Travel", id)
			if r.ok then UI.Sound("swoosh", 0.8, 0.6) else UI.Toast(r.err or "Can't travel", "error") end
		else
			Panels.Open("Worlds")
			UI.Toast(WorldData.List[id].Name .. " is locked - unlock it here!", "info")
		end
	end
end)

-- fade out loading
UI.Tween(loading, 0.6, {BackgroundTransparency = 1})
for _, c in loading:GetDescendants() do
	if c:IsA("TextLabel") then UI.Tween(c, 0.5, {TextTransparency = 1}) end
	if c:IsA("UIStroke") then UI.Tween(c, 0.5, {Transparency = 1}) end
end
task.delay(0.65, function() loading:Destroy() end)

-- new players: cinematic tour + guided first steps (replayable from Settings)
Tutorial.IsCarrying = Fishing.IsCarrying
PanelMisc.OnReplayTutorial = function() Panels.Close(); Tutorial.Run() end
Tutorial.MaybeStart()
if State.MemoryOnly then
	task.delay(3, function() UI.Toast("Studio test: DataStores unavailable, progress won't save.", "warn") end)
end

-- Studio-only test hook (never created in live servers)
if game:GetService("RunService"):IsStudio() then
	local dbg = Instance.new("BindableFunction")
	dbg.Name = "DuckDebug"
	dbg.OnInvoke = function(cmd, a, b)
		if cmd == "open" then Panels.Open(a, b) return Panels.Current()
		elseif cmd == "close" then Panels.Close() return true
		elseif cmd == "cast" then task.spawn(Fishing.Cast) return true
		elseif cmd == "fight" then Fishing._Fight(a) return true
		elseif cmd == "req" then return State.Request(a, b)
		elseif cmd == "tutorial" then Tutorial.Run(a) return true
		elseif cmd == "tutShot" then return Tutorial._shot
		elseif cmd == "tutSkip" then if Tutorial._skipNow then Tutorial._skipNow() end return true
		elseif cmd == "tutNext" then if Tutorial._nextNow then Tutorial._nextNow() end return true
		elseif cmd == "tutState" then return {active = Tutorial.Active, guiding = Tutorial.Guiding}
		elseif cmd == "busy" then return Fishing.Busy()
		elseif cmd == "boss" then task.spawn(BattleView.StartBoss, a) return true
		elseif cmd == "reveal" then Effects.Reveal({duckId = a, coins = 10, xp = 5, isNew = true}) return true
		elseif cmd == "announce" then Effects.Announce(a) return true
		elseif cmd == "data" then return State.Data
		elseif cmd == "battleState" then return BattleView.DebugState()
		elseif cmd == "battleAuto" then BattleView.DebugAuto() return true
		elseif cmd == "battleLeave" then BattleView.DebugLeave() return true
		elseif cmd == "anim" then RigAnimator.Play(a, b) return true end
	end
	dbg.Parent = player
end
