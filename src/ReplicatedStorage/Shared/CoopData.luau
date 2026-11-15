-- Coop: ducks you put in your coop make Feathers (for cosmetics) and a trickle of Coins over time.
local Rarity = require(script.Parent.Rarity)
local CoopData = {}

CoopData.START_SLOTS = 3
CoopData.MAX_SLOTS = 12
-- coin price of each extra slot (slot 4 .. 12)
CoopData.SlotCost = {[4] = 2500, [5] = 15000, [6] = 75000, [7] = 300000, [8] = 1200000, [9] = 5000000, [10] = 20000000, [11] = 80000000, [12] = 300000000}
-- feathers per minute for one duck, by rarity (duck level adds +3% per level)
CoopData.RATE = {2, 4, 7, 12, 20, 32, 50, 80, 120, 200}
CoopData.OFFLINE_RATE = 0.5 -- coop keeps working while you're away, at half speed
CoopData.OFFLINE_MAX = 8 * 3600 -- for up to 8 hours
CoopData.FIELD_ORIGIN = Vector3.new(-700, 0, 0)
CoopData.PLOTS = 8

function CoopData.DuckRate(rarity: number, level: number): number
	return (CoopData.RATE[rarity] or 1) * (1 + 0.03 * math.max(0, (level or 1) - 1))
end

-- coins per minute for one duck: 2% of what catching that duck pays, per minute, scaled by its
-- world like catch rewards (+3% per duck level). A full coop of good ducks adds roughly a quarter
-- of what active fishing earns - a nice bonus, never a replacement for catching.
CoopData.COIN_FACTOR = 0.02
function CoopData.CoinRate(duck, level: number): number
	local tier = Rarity.List[duck.Rarity]
	local worldMult = 1 + ((duck.World or 1) - 1) * 0.6
	return (tier and tier.Coins or 10) * CoopData.COIN_FACTOR * worldMult * (1 + 0.03 * math.max(0, (level or 1) - 1))
end

-- plot i centre on the field (two rows of four, facing the middle path)
function CoopData.PlotCFrame(i: number): CFrame
	local row = if i <= 4 then -1 else 1
	local col = ((i - 1) % 4) - 1.5
	local pos = CoopData.FIELD_ORIGIN + Vector3.new(col * 52, 0, row * 46)
	-- coops face the central path (z = 0)
	return CFrame.lookAt(pos, Vector3.new(pos.X, 0, CoopData.FIELD_ORIGIN.Z))
end

return CoopData
