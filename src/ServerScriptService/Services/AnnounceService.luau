-- Rare catch announcements: server-wide for Legendary+, cross-server for Celestial+.
local MessagingService = game:GetService("MessagingService")
local RS = game:GetService("ReplicatedStorage")
local Rarity = require(RS.Shared.Rarity)
local Net = require(script.Parent.Net)
local Fishing = require(script.Parent.FishingService)

local Announce = {}
local TOPIC = "DuckRNG_Announce"

local function announce(player, duck, kind)
	local payload = {Name = player.DisplayName, UserId = player.UserId, Duck = duck.Name, DuckId = duck.Id, Rarity = duck.Rarity, Kind = kind}
	Net.FireAll("Announce", payload)
	if kind == "catch" and Rarity.List[duck.Rarity].Announce == "global" then
		payload.Job = game.JobId
		task.spawn(pcall, MessagingService.PublishAsync, MessagingService, TOPIC, payload)
	end
end

function Announce.Init()
	Fishing.Announce = announce
	task.spawn(function()
		pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(msg)
				local data = msg.Data
				if typeof(data) == "table" and data.Job ~= game.JobId and typeof(data.Duck) == "string" then
					data.Kind = "global"
					Net.FireAll("Announce", data)
				end
			end)
		end)
	end)
end

return Announce
