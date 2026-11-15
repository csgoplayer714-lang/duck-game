-- Background music that follows what you're doing: calm island tunes while you hunt,
-- mysterious tracks in the far worlds, a cosy tune at the coop, a frantic chase song
-- while Mom is after you, and an epic theme in battles. Tracks crossfade.
-- All tracks are licensed APM Music / DistroKid tracks from the Roblox Creator Store.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Music = {}
local player = Players.LocalPlayer

local PLAYLISTS = {
	bright = {1839578771, 1845913205, 1839821481, 1839401276}, -- Charming View Ukulele, Walking On The Beach, Optimistic Side, Get Together
	mystic = {124064284287798, 1847430400}, -- Hollowtide, Entrancing Beats
	coop = {1839273044, 9038116813}, -- Childhood Song, Flirty Flutter
	chase = {1848294293}, -- Runaway Carousel (speeds up!)
	battle = {9043656661}, -- Star Chasing
}
local VOLUME = {bright = 0.28, mystic = 0.3, coop = 0.28, chase = 0.42, battle = 0.34}
local MYSTIC_FROM_WORLD = 4

Music.Enabled = true
Music.IsCarrying = function() return false end -- set by ClientMain
Music.World = function() return 1 end -- set by ClientMain

local group = Instance.new("SoundGroup")
group.Name = "Music"
group.Volume = 1
group.Parent = SoundService

local current -- {key, sound}
local nextIndex = {}

local function fade(s, vol, t, thenDestroy)
	local tw = TweenService:Create(s, TweenInfo.new(t, Enum.EasingStyle.Sine), {Volume = vol})
	tw:Play()
	if thenDestroy then tw.Completed:Once(function() s:Destroy() end) end
end

local function start(key)
	local list = PLAYLISTS[key]
	local i = nextIndex[key] or math.random(1, #list)
	nextIndex[key] = i % #list + 1
	local s = Instance.new("Sound")
	s.Name = "Music_" .. key
	s.SoundId = "rbxassetid://" .. list[i]
	s.Volume = 0
	s.Looped = #list == 1
	s.SoundGroup = group
	s.Parent = SoundService
	s:Play()
	fade(s, VOLUME[key] or 0.3, if key == "chase" then 0.4 else 1.6)
	local me = {key = key, sound = s}
	-- playlist: when a song ends, roll on to the next one in the same mood
	s.Ended:Connect(function()
		if current == me then
			s:Destroy()
			current = nil
			Music._Switch(key)
		end
	end)
	return me
end

function Music._Switch(key)
	if current and current.key == key then return end
	if current then
		fade(current.sound, 0, if key == "chase" then 0.35 else 1.2, true)
		current = nil
	end
	if key then current = start(key) end
end

local function want()
	if not Music.Enabled then return nil end
	if player:GetAttribute("InBattleView") or player:GetAttribute("InBattle") then return "battle" end
	local ok, carrying = pcall(Music.IsCarrying)
	if ok and carrying then return "chase" end
	if player:GetAttribute("AtCoop") then return "coop" end
	local okW, w = pcall(Music.World)
	if okW and (w or 1) >= MYSTIC_FROM_WORLD then return "mystic" end
	return "bright"
end

function Music.SetEnabled(v)
	Music.Enabled = v
	Music._Switch(want())
end

function Music.Init()
	task.spawn(function()
		while true do
			local k = want()
			if (current and current.key) ~= k then Music._Switch(k) end
			task.wait(0.25)
		end
	end)
end

function Music.Current() return current and current.key end

return Music
