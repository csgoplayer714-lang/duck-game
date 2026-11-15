-- New-player tutorial.
--  1) CINEMATIC: letterboxed camera flights over the island with captions (pond, sneaking, Mom,
--     the showcase, shop, bosses, coop, worlds). Click / tap / Space = next shot, SKIP skips it all.
--  2) GUIDED STEPS: an objective card, a golden trail in the world and a pulsing ring on the right
--     HUD button walk you through your first catch, escaping Mom, your coop and battles.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Shared = RS:WaitForChild("Shared")
local PoolSim = require(Shared.PoolSim)
local CoopData = require(Shared.CoopData)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local HUD = require(script.Parent.HUD)
local new = UI.new

local T = {}
T.Active = false -- cinematic running
T.Guiding = false -- guided steps running
T.IsCarrying = function() return false end -- set by ClientMain
local player = Players.LocalPlayer
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

---------------------------------------------------------------- helpers
local function hub() return workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("World_1") end
local function where(name, fallback)
	local h = hub()
	local m = h and h:FindFirstChild(name)
	if m then
		local ok, p = pcall(function() return m:GetPivot().Position end)
		if ok then return p end
	end
	return fallback
end
local function momPos(world)
	for _, m in workspace:GetDescendants() do
		if m:IsA("Model") and m:GetAttribute("Mom") and (m:GetAttribute("World") or world) == world then
			local ok, p = pcall(function() return m:GetPivot().Position end)
			if ok then return p end
		end
	end
	return nil
end
local function myWorld() return player:GetAttribute("World") or (State.Data and State.Data.world) or 1 end
local function hrp() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
-- freeze the character during the cinematic (restores the previous speeds afterwards)
local frozen
local function controls(on)
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not h then return end
	if not on then
		frozen = {h, h.WalkSpeed, h.JumpPower, h.JumpHeight}
		h.WalkSpeed = 0; h.JumpPower = 0; h.JumpHeight = 0
	elseif frozen then
		local fh = frozen[1]
		if fh.Parent then fh.WalkSpeed = frozen[2]; fh.JumpPower = frozen[3]; fh.JumpHeight = frozen[4] end
		frozen = nil
	end
end

---------------------------------------------------------------- cinematic UI
local gui, top, bot, black, card, cardTitle, cardText, cardScale, dots, skipBtn, nextHint
local function buildGui()
	if gui then return end
	gui = new("ScreenGui", {Name = "Cinematic", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false, Parent = player:WaitForChild("PlayerGui")})
	-- letterbox bars slide in from the top / bottom
	top = new("Frame", {Parent = gui, Size = UDim2.new(1, 0, 0.11, 0), Position = UDim2.fromScale(0, -0.11), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2})
	bot = new("Frame", {Parent = gui, Size = UDim2.new(1, 0, 0.11, 0), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2})
	black = new("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 20})
	-- caption card in the game's studded style
	card = new("Frame", {Parent = gui, Size = UDim2.fromOffset(700, 150), Position = UDim2.new(0.5, 0, 0.89, -8), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = UI.C.Bg, ZIndex = 5})
	UI.Corner(card, 14); UI.Studs(card, UI.Darken(UI.C.Bg, 0.45), 0.35, 24, 14); UI.Stroke(card, UI.C.Outline, 5)
	cardScale = new("UIScale", {Parent = card})
	local head = new("Frame", {Parent = card, Size = UDim2.fromOffset(340, 46), Position = UDim2.new(0, 18, 0, -26), BackgroundColor3 = UI.C.Gold, ZIndex = 6})
	UI.Corner(head, 12); UI.Gradient(head, Color3.fromRGB(255, 236, 120), Color3.fromRGB(242, 160, 18), 90)
	UI.Studs(head, Color3.fromRGB(214, 130, 0), 0.4, 18, 12); UI.Stroke(head, UI.C.Outline, 4)
	cardTitle = UI.Label(head, "", UDim2.new(1, -20, 1, -10), UDim2.fromOffset(10, 5), {ZIndex = 7, StrokeTh = 3, TextXAlignment = Enum.TextXAlignment.Left})
	cardText = UI.Label(card, "", UDim2.new(1, -40, 1, -58), UDim2.fromOffset(20, 30), {ZIndex = 6, Font = UI.Body, TextScaled = false, TextSize = 24, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, StrokeTh = 2})
	dots = new("Frame", {Parent = card, Size = UDim2.new(0, 300, 0, 14), Position = UDim2.new(0, 20, 1, -22), BackgroundTransparency = 1, ZIndex = 6})
	UI.List(dots, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
	nextHint = UI.Label(card, if isTouch then "Tap for next  \u{25B6}" else "Click / Space for next  \u{25B6}", UDim2.fromOffset(260, 20), UDim2.new(1, -276, 1, -28),
		{ZIndex = 6, Font = UI.Body, TextColor3 = UI.C.Sub, TextXAlignment = Enum.TextXAlignment.Right, StrokeTh = 1.5})
	skipBtn = UI.Button(gui, {Text = "SKIP \u{23E9}", Color = UI.C.Red, Size = UDim2.fromOffset(130, 46), Position = UDim2.new(1, -20, 0, 18), Anchor = Vector2.new(1, 0), Z = 8, Radius = 10, StrokeTh = 3})
	-- full-screen catcher for "next" (below the skip button)
	local catcher = new("TextButton", {Parent = gui, Name = "Next", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1, AutoButtonColor = false})
	T._catcher = catcher
end

local function fit()
	local vp = gui.AbsoluteSize
	cardScale.Scale = math.clamp(math.min(vp.X / 760, vp.Y / 560), 0.55, 1.15)
end

-- typewriter caption
local typeToken = 0
local function caption(title, text, idx, total)
	cardTitle.Text = title
	cardText.Text = text
	cardText.MaxVisibleGraphemes = 0
	typeToken += 1
	local my = typeToken
	task.spawn(function()
		local n = utf8.len(text) or #text
		local i = 0
		while i < n and my == typeToken do
			i += 2
			cardText.MaxVisibleGraphemes = i
			task.wait(0.012)
		end
		if my == typeToken then cardText.MaxVisibleGraphemes = -1 end
	end)
	for _, c in dots:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	for k = 1, total do
		local d = new("Frame", {Parent = dots, Size = UDim2.fromOffset(if k == idx then 30 else 14, 14), BackgroundColor3 = if k <= idx then UI.C.Gold else UI.C.Dark, LayoutOrder = k, ZIndex = 6})
		UI.Corner(d, 7); UI.Stroke(d, UI.C.Outline, 2)
	end
	local head = cardTitle.Parent
	local s = head:FindFirstChild("Pop") or new("UIScale", {Parent = head, Name = "Pop"})
	s.Scale = 0.6; UI.Tween(s, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
end

---------------------------------------------------------------- shots
-- each shot: camera flies from -> to (both look at `at`), with a caption
local function shots()
	local w = myWorld()
	local pc = PoolSim.Center(if hub() then 1 else w)
	local mom = momPos(1) or (pc + Vector3.new(0, 0, 10))
	local show = where("Showcase", Vector3.new(0, 10, 94))
	local shop = where("Booth_NET SHOP", Vector3.new(-100, 8, -7))
	local boss = where("Portal_BOSS PORTAL", Vector3.new(95, 7, 80))
	local arena = where("PvPArena", Vector3.new(-95, 5, 80))
	local portals = where("Portal_HAUNTED SWAMP", Vector3.new(0, 7, -192))
	local altar = where("RebirthAltar", Vector3.new(0, 6, 160))
	local coop = CoopData.PlotCFrame(player:GetAttribute("CoopPlot") or 1).Position
	local swing = if isTouch then "tap SWING" else "click"
	return {
		{title = "WELCOME TO DUCK RNG!", text = "This is Carnival Island, your home base. Let's take a quick tour so you know where everything is!",
			from = CFrame.lookAt(Vector3.new(-160, 140, 220), Vector3.new(0, 0, 0)), to = CFrame.lookAt(Vector3.new(140, 110, 200), Vector3.new(0, 0, -20)), t = 7},
		{title = "THE DUCK POND", text = "Ducks swim in the pond. Grab your net (" .. (if isTouch then "Net button" else "press 1") .. "), wade in and " .. swing .. " to POUNCE on a duck. Rare ducks are faster and can dodge!",
			from = CFrame.lookAt(pc + Vector3.new(70, 45, 70), pc), to = CFrame.lookAt(pc + Vector3.new(-50, 28, 55), pc), t = 7},
		{title = "SNEAK UP ON THEM", text = "Running splashes and scares ducks away. " .. (if isTouch then "Tap SNEAK" else "Hold Ctrl") .. " to tiptoe through the water so they don't hear you coming.",
			from = CFrame.lookAt(pc + Vector3.new(22, 4, 30), pc + Vector3.new(0, 1, 0)), to = CFrame.lookAt(pc + Vector3.new(-18, 3.5, 26), pc + Vector3.new(0, 1, -6)), t = 6.5},
		{title = "BEWARE OF MOM!", text = "Mom guards her babies. When you scoop a duck she chases you, so RUN out of the water before she bonks you, or the duck swims back!",
			follow = function() return momPos(1) or mom end, fromOff = Vector3.new(34, 14, 40), toOff = Vector3.new(-18, 11, 34), lookOff = Vector3.new(0, 4, 0), t = 7},
		{title = "RARE DUCKS FIGHT BACK", text = "Rare ducks wriggle in your net. When the dial appears, click or tap ANYWHERE when the needle hits the green! Here are the rarest ducks and your odds.",
			from = CFrame.lookAt(show + Vector3.new(-46, 20, -72), show + Vector3.new(0, -5, 0)), to = CFrame.lookAt(show + Vector3.new(38, 16, -66), show + Vector3.new(0, -5, 0)), t = 7.5},
		{title = "THE SHOP", text = "Spend your coins on better nets, lures and potions. Bigger nets = longer reach, better luck and faster swings.",
			from = CFrame.lookAt(shop + Vector3.new(40, 14, 30), shop), to = CFrame.lookAt(shop + Vector3.new(34, 8, -24), shop), t = 6},
		{title = "BOSSES & BATTLES", text = "Put your 3 best ducks in YOUR TEAM, then fight bosses through the Boss Portal, or battle other players in the PvP arena for titles!",
			from = CFrame.lookAt(boss + Vector3.new(-30, 16, -30), boss), to = CFrame.lookAt(arena + Vector3.new(40, 26, -30), arena), t = 7.5},
		{title = "YOUR COOP", text = "Every player gets a coop. Ducks you put inside make Feathers and Coins, even while you're offline! Feathers buy animated cosmetics in the Style shop.",
			from = CFrame.lookAt(coop + Vector3.new(52, 36, 44), coop + Vector3.new(0, 4, 0)), to = CFrame.lookAt(coop + Vector3.new(28, 22, 36), coop + Vector3.new(0, 4, 0)), t = 7.5},
		{title = "NEW WORLDS & REBIRTH", text = "Unlock new worlds through these portals for rarer ducks and better rewards. When you're strong enough, Rebirth at the altar for permanent boosts!",
			from = CFrame.lookAt(portals + Vector3.new(0, 40, 90), portals), to = CFrame.lookAt(altar + Vector3.new(0, 30, -50), altar), t = 7.5},
	}
end

---------------------------------------------------------------- cinematic runner
local function hideHud(on)
	local g = player.PlayerGui:FindFirstChild("DuckRNG")
	if g then g.Enabled = not on end
end

function T.PlayCinematic(startAt)
	if T.Active then return end
	buildGui()
	T.Active = true
	Panels.Close()
	local cam = workspace.CurrentCamera
	local list = shots()
	local skip, advance = false, false
	local conns = {}
	table.insert(conns, skipBtn.Activated:Connect(function() skip = true; advance = true end))
	T._skipNow = function() skip = true; advance = true end
	T._nextNow = function() advance = true end
	table.insert(conns, T._catcher.Activated:Connect(function() advance = true end))
	table.insert(conns, UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.Return or i.KeyCode == Enum.KeyCode.ButtonA then advance = true end
		if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.ButtonB then skip = true; advance = true end
	end))
	controls(false)
	gui.Enabled = true
	fit()
	-- open: fade from black with the bars sliding in
	black.BackgroundTransparency = 0
	card.Visible = false
	hideHud(true)
	cam.CameraType = Enum.CameraType.Scriptable
	UI.Tween(top, 0.6, {Position = UDim2.fromScale(0, 0)}, Enum.EasingStyle.Quint)
	UI.Tween(bot, 0.6, {Position = UDim2.fromScale(0, 0.89)}, Enum.EasingStyle.Quint)
	for i, shot in list do
		if skip then break end
		if i < (startAt or 1) then continue end
		advance = false
		cam.FieldOfView = 60
		local tw
		if shot.follow then
			-- moving subject (Mom): glide around her while keeping her framed
			local t0 = os.clock()
			local conn = RunService.RenderStepped:Connect(function()
				local a = math.clamp((os.clock() - t0) / shot.t, 0, 1)
				a = a * a * (3 - 2 * a)
				local p = shot.follow()
				cam.CFrame = CFrame.lookAt(p + shot.fromOff:Lerp(shot.toOff, a), p + shot.lookOff)
			end)
			tw = {Cancel = function() conn:Disconnect() end}
		else
			cam.CFrame = shot.from
			tw = TweenService:Create(cam, TweenInfo.new(shot.t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = shot.to, FieldOfView = 52})
			tw:Play()
		end
		T._shot = i
		UI.Tween(black, 0.45, {BackgroundTransparency = 1})
		card.Visible = true
		caption(shot.title, shot.text, i, #list)
		UI.Sound("swoosh", 0.9, 0.35)
		local t0 = os.clock()
		while os.clock() - t0 < shot.t and not advance do task.wait() end
		-- cut: quick dip to black
		UI.Tween(black, 0.25, {BackgroundTransparency = 0})
		task.wait(0.27)
		tw:Cancel()
	end
	-- back to the player: swoop down behind your character
	local root = hrp()
	card.Visible = false
	if root then
		-- turn to face the pond so the golden trail starts right in front of you
		local pc = PoolSim.Center(myWorld())
		local flat = Vector3.new(pc.X, root.Position.Y, pc.Z)
		if (flat - root.Position).Magnitude > 2 then root.CFrame = CFrame.lookAt(root.Position, flat) end
		local look = root.CFrame.LookVector
		cam.CFrame = CFrame.lookAt(root.Position - look * 40 + Vector3.new(0, 30, 0), root.Position)
		UI.Tween(black, 0.35, {BackgroundTransparency = 1})
		local tw = TweenService:Create(cam, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {CFrame = CFrame.lookAt(root.Position - look * 12 + Vector3.new(0, 5, 0), root.Position + Vector3.new(0, 2, 0)), FieldOfView = 70})
		tw:Play()
		card.Visible = true
		caption("YOUR ADVENTURE STARTS NOW!", "Follow the golden trail and the glowing buttons. Let's catch your first duck!", #list, #list)
		task.wait(if skip then 0.6 else 2.2)
	end
	UI.Tween(top, 0.5, {Position = UDim2.fromScale(0, -0.11)}, Enum.EasingStyle.Quint)
	UI.Tween(bot, 0.5, {Position = UDim2.fromScale(0, 1)}, Enum.EasingStyle.Quint)
	card.Visible = false
	task.wait(0.4)
	for _, c in conns do c:Disconnect() end
	gui.Enabled = false
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 70
	hideHud(false)
	controls(true)
	T.Active = false
	-- remember it so the cinematic only plays once (it can be replayed from Settings)
	if State.Data and State.Data.settings then State.Data.settings.tutorialDone = true end
	pcall(State.Request, "SetSetting", "tutorialDone", true)
end

---------------------------------------------------------------- guided steps
local guide = {}
local function buildGuide()
	if guide.card then return end
	local screen = player.PlayerGui:WaitForChild("DuckRNG"):WaitForChild("Scaled")
	local c = new("Frame", {Parent = screen, Name = "Objective", Size = UDim2.fromOffset(440, 74), Position = UDim2.new(0.5, 0, 0, (HUD.TopY or 66) + 4), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = UI.C.Bg, ZIndex = 30, Visible = false})
	UI.Corner(c, 12); UI.Studs(c, UI.Darken(UI.C.Bg, 0.45), 0.35, 20, 12); UI.Stroke(c, UI.C.Outline, 4)
	local tag = new("Frame", {Parent = c, Size = UDim2.fromOffset(130, 26), Position = UDim2.fromOffset(12, -13), BackgroundColor3 = UI.C.Gold, ZIndex = 31})
	UI.Corner(tag, 8); UI.Gradient(tag, Color3.fromRGB(255, 236, 120), Color3.fromRGB(242, 160, 18), 90); UI.Stroke(tag, UI.C.Outline, 2.5)
	guide.step = UI.Label(tag, "STEP 1/7", UDim2.new(1, -8, 1, -4), UDim2.fromOffset(4, 2), {ZIndex = 32, StrokeTh = 2})
	guide.text = UI.Label(c, "", UDim2.new(1, -70, 1, -22), UDim2.fromOffset(14, 16), {ZIndex = 31, TextXAlignment = Enum.TextXAlignment.Left, StrokeTh = 2.5})
	local x = UI.Button(c, {Text = "X", Color = UI.C.Red, Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -44, 0.5, -17), Z = 32, Radius = 8, StrokeTh = 2.5, OnClick = function() T.StopGuide(false) end})
	guide.close = x
	guide.scale = new("UIScale", {Parent = c})
	guide.card = c
	-- pulsing ring that sits on top of the HUD button you should press
	local ring = new("Frame", {Parent = screen, Name = "TutorialRing", Size = UDim2.fromOffset(100, 100), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 45, Visible = false})
	UI.Corner(ring, 22)
	guide.ringStroke = new("UIStroke", {Parent = ring, Color = Color3.fromRGB(255, 240, 90), Thickness = 5})
	guide.arrow = UI.Label(ring, "\u{25BC}", UDim2.fromOffset(40, 40), UDim2.new(0.5, -20, 0, -46), {ZIndex = 46, TextColor3 = Color3.fromRGB(255, 240, 90), StrokeTh = 3})
	guide.ring = ring
	-- golden trail in the world
	local a1 = new("Attachment", {Name = "TutA"})
	local holder = new("Part", {Name = "TutorialTarget", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1), Parent = workspace.CurrentCamera})
	local a2 = new("Attachment", {Parent = holder, Name = "TutB"})
	local beam = new("Beam", {Attachment0 = a1, Attachment1 = a2, Width0 = 1.2, Width1 = 1.2, FaceCamera = true, Segments = 30, LightEmission = 0.8, Color = ColorSequence.new(Color3.fromRGB(255, 230, 80)),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.15, 0.25), NumberSequenceKeypoint.new(1, 0.1)}), CurveSize0 = 0, CurveSize1 = 0, Parent = holder, Enabled = false})
	local bb = new("BillboardGui", {Parent = holder, Size = UDim2.fromOffset(150, 80), StudsOffsetWorldSpace = Vector3.new(0, 6, 0), AlwaysOnTop = true, LightInfluence = 0, Enabled = false})
	guide.marker = UI.Label(bb, "\u{25BC}", UDim2.fromScale(1, 1), nil, {TextColor3 = Color3.fromRGB(255, 230, 80), StrokeTh = 4})
	guide.a1, guide.holder, guide.beam, guide.bb = a1, holder, beam, bb
end

local function setTarget(pos)
	if pos then
		guide.holder.Position = pos
		local r = hrp()
		if r and guide.a1.Parent ~= r then guide.a1.Parent = r end
		guide.beam.Enabled = r ~= nil
		guide.bb.Enabled = true
	else
		guide.beam.Enabled = false
		guide.bb.Enabled = false
	end
end

local function setRing(btn)
	guide.ringBtn = btn
	guide.ring.Visible = btn ~= nil and btn.Visible
end

local function inWater()
	local r = hrp()
	if not r then return false end
	local w = myWorld()
	return PoolSim.EdgeDistance(w, r.Position) > 0 and math.abs(r.Position.Y - PoolSim.Center(w).Y) < 6
end
local function hasNet()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Tool") ~= nil
end
local function caught() return State.Data and State.Data.stats and State.Data.stats.caught or 0 end

local function steps()
	local base = caught()
	return {
		{text = if isTouch then "Grab your net: tap the NET button" else "Grab your net: press 1 or click NET", button = "Net", done = hasNet},
		{text = "Follow the golden trail into the Duck Pond", target = function() return PoolSim.Center(myWorld()) + Vector3.new(0, 2, 0) end, done = inWater},
		{text = if isTouch then "Sneak up, aim the ring and tap SWING on a duck!" else "Sneak up (hold Ctrl), aim and CLICK on a duck!", target = function() return PoolSim.Center(myWorld()) + Vector3.new(0, 2, 0) end,
			done = function() return T.IsCarrying() or caught() > base end},
		{text = "RUN! Get out of the water before Mom bonks you!", back = 3, done = function() return caught() > base end,
			failed = function() return not T.IsCarrying() and caught() <= base end},
		{text = "Nice catch! Now visit your Coop", button = "Coop", done = function() return player:GetAttribute("AtCoop") == true end},
		{text = "Open your coop and press ADD on a duck (or Auto-fill)", button = "Coop", done = function() return State.Data and State.Data.coop and #State.Data.coop.ducks > 0 end},
		{text = "Last one: open BATTLE to fight bosses with your team!", button = "Battle", done = function() return Panels.Current() == "Battle" end},
	}
end

local guideToken = 0
function T.StopGuide(completed)
	guideToken += 1
	T.Guiding = false
	if guide.card then
		guide.card.Visible = false
		guide.ring.Visible = false
		setTarget(nil)
	end
	if completed then
		UI.Sound("fanfare", 1, 0.55)
		UI.Toast("\u{1F389} Tutorial complete! You're ready to become the ultimate duck hunter!", "good")
	end
end

function T.StartGuide()
	buildGuide()
	guideToken += 1
	local my = guideToken
	T.Guiding = true
	local list = steps()
	local i = 1
	local function show()
		local s = list[i]
		guide.step.Text = string.format("STEP %d/%d", i, #list)
		guide.text.Text = s.text
		guide.card.Visible = true
		guide.scale.Scale = 0.5
		UI.Tween(guide.scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
		setRing(s.button and HUD.Buttons[s.button])
		setTarget(s.target and s.target())
	end
	show()
	-- keep the ring glued to its button and pulsing; move the marker; bob the arrow
	task.spawn(function()
		while my == guideToken do
			local t = os.clock()
			local b = guide.ringBtn
			if b and b.Parent and b.AbsoluteSize.X > 0 then
				local scr = guide.ring.Parent
				local sc0 = scr:FindFirstChildOfClass("UIScale")
				local k = if sc0 then sc0.Scale else 1
				local p = (b.AbsolutePosition - scr.AbsolutePosition + b.AbsoluteSize / 2) / k
				guide.ring.Position = UDim2.fromOffset(p.X, p.Y)
				local sz = b.AbsoluteSize / k + Vector2.new(18, 18) * (1 + 0.12 * math.sin(t * 6))
				guide.ring.Size = UDim2.fromOffset(sz.X, sz.Y)
				guide.ringStroke.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * 6))
				guide.arrow.Position = UDim2.new(0.5, -20, 0, -46 - 6 * math.abs(math.sin(t * 4)))
				guide.ring.Visible = Panels.Current() == nil or list[i].button == "Coop" and Panels.Current() ~= "Coop"
			elseif guide.ring.Visible then
				guide.ring.Visible = false
			end
			if guide.bb.Enabled then guide.bb.StudsOffsetWorldSpace = Vector3.new(0, 6 + math.abs(math.sin(t * 3)) * 1.5, 0) end
			RunService.RenderStepped:Wait()
		end
	end)
	-- progress
	task.spawn(function()
		while my == guideToken do
			task.wait(0.25)
			if T.Active then continue end
			local s = list[i]
			if not s then break end
			if s.failed and s.failed() then
				i = s.back or i - 1
				UI.Toast("Mom got the duck back! Try again - sneak up and grab another one.", "warn")
				show()
			elseif s.done() then
				UI.Sound("sting", 1.1, 0.4)
				UI.Chime(3, 1.2)
				i += 1
				if i > #list then T.StopGuide(true) break end
				show()
			elseif s.target then
				-- keep the trail fresh (the pond centre for the world you're in)
				setTarget(s.target())
			end
		end
	end)
end

---------------------------------------------------------------- entry points
function T.Run(startAt)
	task.spawn(function()
		T.PlayCinematic(startAt)
		T.StartGuide()
	end)
end

function T.MaybeStart()
	local d = State.Data
	if d and d.settings and d.settings.tutorialDone then return end
	task.delay(1.2, T.Run)
end

return T
