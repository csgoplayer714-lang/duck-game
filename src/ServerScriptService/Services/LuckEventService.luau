-- Server-wide Luck Events: every 12-20 minutes, luck is multiplied for everyone for 5 minutes.
-- Replicated through workspace attributes; Stats.Luck reads them on both server and client.
local Net = require(script.Parent.Net)

local LuckEvents = {}
local DURATION = 300

function LuckEvents.Start(mult: number, duration: number?)
	workspace:SetAttribute("LuckEventMult", mult)
	workspace:SetAttribute("LuckEventEnd", workspace:GetServerTimeNow() + (duration or DURATION))
	Net.FireAll("Notify", {Text = string.format("\u{1F340} LUCK EVENT! Everyone gets x%d luck for %d minutes!", mult, math.floor((duration or DURATION) / 60)), Kind = "good"})
	Net.FireAll("LuckEvent", {Mult = mult})
end

function LuckEvents.Init()
	workspace:SetAttribute("LuckEventMult", 1)
	workspace:SetAttribute("LuckEventEnd", 0)
	task.spawn(function()
		task.wait(180) -- first event a few minutes after the server starts
		while true do
			local roll = math.random()
			local mult = if roll < 0.05 then 5 elseif roll < 0.3 then 3 else 2
			LuckEvents.Start(mult)
			task.wait(DURATION)
			workspace:SetAttribute("LuckEventMult", 1)
			task.wait(math.random(720, 1200))
		end
	end)
end

return LuckEvents
