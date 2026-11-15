-- DUCK DATABASE
-- 200 fishable ducks (25 per world) + boss-exclusive + rebirth-exclusive ducks.
-- Line format: Name|bodyHex|accentHex|Element|accessories(comma)|material|AbilityName:type (optional)
-- Per world, ducks are listed in rarity order using WORLD_RARITY_LAYOUT.
local Rarity = require(script.Parent.Rarity)
local WorldData = require(script.Parent.WorldData)

local DuckData = {}

local WORLD_RARITY_LAYOUT = {1,1,1,1,1, 2,2,2,2, 3,3,3,3, 4,4,4, 5,5,5, 6,6, 7, 8, 9, 10}

local RAW = {
[1] = [[
Classic Yellow Duck|FFD93D|FF8C1A|Normal||P
Blue Duck|4DA6FF|FF8C1A|Water||P
Red Duck|FF4D4D|FFB01A|Fire||P
Green Duck|5ED16A|FF8C1A|Nature||P
Pink Duck|FF8AD8|FF8C1A|Normal||P
Party Duck|FFD93D|FF4FA0|Normal|partyHat|P
Balloon Duck|7FD6FF|FF5A5A|Normal|balloon|P
Popcorn Duck|FFF3D6|E8392E|Normal|popcorn|P
Clown Duck|FFFFFF|FF2E2E|Normal|clownNose,afro|P
Ringmaster Duck|D62D3B|FFD54A|Normal|tophat,cape|P
Juggler Duck|9B5BFF|FFD93D|Normal|orbitBalls,jesterHat|P
Ticket Duck|FFB347|E8392E|Normal|visor|P
Cotton Candy Duck|FFB6E6|9AD8FF|Light|cloudHat|P
Pirate Duck|FFD93D|7A4A2A|Water|pirateHat,eyepatch,sword|P
Ninja Duck|2B2B3A|D62D3B|Shadow|ninjaMask,katana|P|Shadow Strike:crit
Magician Duck|3B2D6E|FFD54A|Cosmic|tophat,wand,cape|P
Golden Duck|FFC92E|FF9A1A|Light|sparkle|M|Golden Splash:nuke
Carousel Knight Duck|E8E8F0|D62D3B|Normal|armor,helmet,lance|M
King Duck|FFD93D|D62D3B|Light|crown,cape,scepter|P
Diamond Duck|BFF4FF|FFFFFF|Light|tiara,sparkle|G
Jackpot Duck|FFD24A|2EC45E|Normal|coinOrbit,tophat|M
Angel Duck|FFFFFF|FFD54A|Light|halo,angelWings|P
Starlight Carousel Duck|FFE9A8|7AD3FF|Cosmic|orbitRings,halo,crown|G
Glitch Duck|00FFB3|FF00E6|Void|glitch|N
Carnival Overlord Duck|FFD93D|FF2E6E|Cosmic|crown,angelWings,staff,orbitShards,cape|M
]],
[2] = [[
Coconut Duck|8B5A2B|F2E3C6|Nature||P
Palm Duck|6CCF5C|8B5A2B|Nature||P
Sandy Duck|F3D9A0|FF8C1A|Normal||P
Mango Duck|FFA62B|5ABF4A|Nature||P
Lagoon Duck|3DD6C8|FF8C1A|Water||P
Surfer Duck|FFD93D|1AA3FF|Water|sunglasses,surfboard|P
Lei Duck|FFE36B|FF4FA0|Nature|lei|P
Hula Duck|FF9F6B|5ABF4A|Nature|flower,skirt|P
Snorkel Duck|5BC8FF|FFEC3D|Water|goggles|P
Parrot Duck|2ECC40|FF3B3B|Nature|crest|P
Tiki Duck|A0522D|FFB000|Fire|tikiMask|P
Pineapple Duck|FFD23F|3FAF3F|Nature|leafCrown|P
Seashell Duck|FFD9E6|FF9EC4|Water|shellHat|P
Toxic Duck|8CFF3D|5A1AFF|Nature|gasAura|N|Toxic Cloud:poison
Jungle Ranger Duck|6B8E23|C2A86B|Nature|rangerHat,spear|P
Volcano Islander Duck|FF6B3D|FFD23F|Fire|flower,spear,fireAura|P
Captain Coral Duck|FF7F7F|FFD54A|Water|pirateHat,armor,sword|P
Shark Rider Duck|7F9CB0|FFFFFF|Water|finHelmet,trident|M
Sun Spirit Duck|FFE066|FF8C1A|Light|sunHalo,sparkle|N
Tsunami Duck|1E90FF|BFF4FF|Water|trident,waveAura,crown|G
Emerald Serpent Duck|1ECC6E|FFD54A|Nature|horns,crystalSpikes|G
Rainbow Reef Duck|FF7AD9|7AF0FF|Light|halo,rainbow,angelWings|P
Solar Eclipse Duck|1A1A1A|FFB000|Cosmic|sunHalo,orbitRings|N
Ghost Pirate Duck|BFFFF0|5AFFC8|Shadow|pirateHat,eyepatch,sword|F
Leviathan Duck|0B4F8A|3DFFE0|Water|horns,crown,trident,waveAura,orbitShards|G
]],
[3] = [[
Snowy Duck|FFFFFF|FF8C1A|Ice||P
Frost Duck|CFEFFF|FF8C1A|Ice||P
Slush Duck|9FD8E8|FFAA4A|Ice||P
Icicle Duck|E0F7FF|7AC8FF|Ice||G
Mitten Duck|FF6B6B|FFFFFF|Normal||P
Earmuff Duck|FFD93D|FF4FA0|Ice|earmuffs|P
Scarf Duck|FFF0C8|E8392E|Ice|scarf,beanie|P
Ski Duck|FF8C1A|1AA3FF|Ice|goggles,beanie|P
Snowball Duck|F5FBFF|7AC8FF|Ice|orbitBalls|P
Ice Duck|9CE6FF|E0FBFF|Ice|iceAura|I|Freezing Quack:freeze
Penguin Pal Duck|222233|FFFFFF|Ice|bowtie|P
Igloo Duck|EAF6FF|8AC6E8|Ice|helmet|P
Aurora Duck|7AF0C8|C07AFF|Light|sparkle|G
Yeti Duck|F0F0F5|5AA0FF|Ice|horns,furCollar|P
Frost Archer Duck|BFE6FF|3D7AFF|Ice|bow,hood|P
Ice Skater Duck|FFE0F0|9CE6FF|Ice|tiara,scarf|P
Glacier Knight Duck|AEE4FF|FFFFFF|Ice|armor,helmet,sword|I
Blizzard Duck|DFF4FF|6FB7FF|Ice|iceAura,crown|G
Frost Queen Duck|C8F0FF|7A5AFF|Ice|tiara,cape,staff|G
Crystal Wyrm Duck|7FD8FF|E0FBFF|Ice|horns,wings,crystalSpikes|G
Polar Titan Duck|F5FAFF|3D7AFF|Ice|armor,hammer,horns|I
Northern Light Duck|5AFFC8|C07AFF|Light|halo,sparkle,angelWings|N
Absolute Zero Duck|E8FDFF|00C8FF|Ice|crown,iceAura,orbitShards|F
Frozen Phantom Duck|A8E8FF|FFFFFF|Shadow|hood,scythe,iceAura|F
Eternal Winter Duck|FFFFFF|5AC8FF|Ice|crown,wings,staff,iceAura,orbitShards|I
]],
[4] = [[
Ember Duck|FF7A3D|FFD23F|Fire||P
Ash Duck|8A8A8A|FF6B3D|Fire||P
Magma Duck|D9411E|FFAA1A|Fire||P
Charcoal Duck|3A3A3A|FF8C1A|Fire||P
Spark Duck|FFB347|FF4D1A|Fire||P
Firefighter Duck|FFD93D|D62D3B|Water|helmet|P
Chili Duck|E8392E|3FAF3F|Fire|leafCrown|P
Torch Duck|FFAA4A|8B5A2B|Fire|torch|P
Smoky Duck|6E6E6E|C0C0C0|Shadow|smoke|P
Fire Duck|FF5A1F|FFD23F|Fire|fireAura|P|Fire Splash:burn
Obsidian Duck|1C1428|9B5BFF|Shadow||G
Lava Golem Duck|5A2A1A|FF6B1A|Fire|crystalSpikes|P
Phoenix Chick Duck|FF8C3D|FFE066|Fire|crest,fireAura|P
Blacksmith Duck|8B5A2B|7F7F7F|Fire|hammer,goggles|P
Fire Knight Duck|C0392B|FFD54A|Fire|armor,helmet,sword,fireAura|M
Inferno Duck|FF3D00|FFD000|Fire|fireAura,horns|N
Phoenix Duck|FF6A00|FFE066|Fire|wingsFire,crest,fireAura|N
Volcano Lord Duck|4A1A10|FF5A1F|Fire|crown,horns,cape,staff|P
Demon Duck|8B0000|FF3D3D|Shadow|horns,batWings,fireAura|P|Hellish Quack:drain
Dragon Duck|C0392B|FFD23F|Fire|horns,wings,crystalSpikes,fireAura|M|Dragon Breath:aoe
Hellfire Duck|2A0A0A|FF2A00|Fire|horns,crown,fireAura,scythe|N
Solar Flare Duck|FFD000|FF5A00|Light|sunHalo,wingsFire,fireAura|N
Supernova Duck|FFF0A0|FF3DFF|Cosmic|orbitRings,sunHalo,fireAura|N
Molten Core Duck|FF4A00|2A0A00|Fire|crystalSpikes,fireAura,crown|N
Primordial Flame Duck|FF7A00|FFFFFF|Fire|crown,wingsFire,staff,fireAura,orbitShards|N
]],
[5] = [[
Murky Duck|5A6B45|C8A86B|Nature||P
Moss Duck|6B8E3D|FF8C1A|Nature||P
Bog Duck|4A5A3A|D9A040|Nature||P
Lily Pad Duck|7AC85A|FF8AD8|Nature||P
Mushroom Duck|E8D8C8|D62D3B|Nature||P
Pumpkin Duck|FF8C1A|3FAF3F|Nature|pumpkinHat|P
Zombie Duck|8FB07A|5A3A2A|Shadow|bandage|P
Witch Duck|5A3A8A|3FAF3F|Shadow|witchHat|P
Bat Duck|3A2A4A|FF5AA0|Shadow|batWings|P
Ghost Duck|F0FFFF|9AD8FF|Shadow||F
Mummy Duck|EDE3C8|7A6A4A|Shadow|bandage,eyepatch|P
Vampire Duck|E8E0F0|8B0000|Shadow|cape,fangs|P
Skeleton Duck|F5F5F0|2A2A2A|Shadow|fangs,hood|P
Shadow Duck|1A1A2A|9B5BFF|Shadow|shadowAura|N
Grim Reaper Duck|1A1A1A|B0B0B0|Shadow|hood,scythe|P
Voodoo Duck|8B5A2B|E8392E|Shadow|bandage,tikiMask|P
Lich Duck|3A4A5A|5AFFC8|Shadow|crown,staff,shadowAura|G
Werewolf Duck|6B5A4A|FFD23F|Shadow|ears,claws|P
Headless Duck|2A2A3A|FF8C1A|Shadow|pumpkinHat,cape,sword|P
Nightmare Duck|1A0A2A|FF2A6A|Shadow|horns,shadowAura,batWings|N
Swamp Monster Duck|3A5A2A|9AFF3D|Nature|crystalSpikes,gasAura|P
Soul Keeper Duck|D8E8FF|7A5AFF|Shadow|halo,scythe,shadowAura|F
Blood Moon Duck|8B0000|FF3D3D|Cosmic|crown,orbitRings,batWings|N
Cursed Duck|2A0A2A|FF00C8|Shadow|glitch,shadowAura|N
Death Lord Duck|0A0A0A|5AFFC8|Shadow|crown,hood,scythe,batWings,orbitShards|N
]],
[6] = [[
Bubble Duck|BFF0FF|FF8C1A|Water||G
Pearl Duck|FFF8F0|FFB0C8|Water||P
Aqua Duck|3DC8FF|FF8C1A|Water||P
Kelp Duck|3A8A4A|C8E05A|Nature||P
Coral Duck|FF7F8A|FFD23F|Water||P
Diver Duck|FFD93D|7F7F7F|Water|diverHelmet|P
Jellyfish Duck|FFB0F0|C07AFF|Water|tentacles|G
Starfish Duck|FF9A5A|FFE066|Water|starHat|P
Sailor Duck|FFFFFF|1A4AFF|Water|sailorHat|P
Mermaid Duck|7AF0E0|C07AFF|Water|tiara,fishTail|P
Octopus Duck|C05AFF|FF8AD8|Water|tentacles|P
Prism Duck|FFFFFF|7AF0FF|Light|prism|G
Sapphire Duck|1A4AFF|BFDFFF|Water|sparkle|G
Crystal Duck|C8F8FF|FF9AF0|Light|crystalSpikes|G
Kraken Duck|5A1A6A|FF5A8A|Water|tentacles,crown|P
Atlantis Guard Duck|3DC8C8|FFD54A|Water|armor,helmet,trident|M
Poseidon Duck|1E90FF|FFD54A|Water|crown,trident,cape|M
Ruby Duck|E0115F|FFC0D0|Fire|sparkle,tiara|G
Abyssal Duck|0A1A3A|3DFFE0|Shadow|tentacles,shadowAura|N
Crystal Titan Duck|AEE8FF|FF7AF0|Light|armor,crystalSpikes,hammer|G
Ocean Sovereign Duck|0B5FA0|FFD54A|Water|crown,trident,waveAura,cape|G
Opal Goddess Duck|FFF0FA|7AF0FF|Light|tiara,halo,angelWings,sparkle|G
Tidal Moon Duck|C8D8FF|3D5AFF|Cosmic|orbitRings,waveAura,halo|N
Deep Sea Anomaly Duck|050A1A|00FFE0|Void|tentacles,glitch|N
Crystal Heart Duck|FF9AF0|FFFFFF|Light|crown,angelWings,crystalSpikes,orbitShards,staff|G
]],
[7] = [[
Cloud Duck|FFFFFF|9AD8FF|Light||P
Feather Duck|FFF8E0|FFD54A|Light||P
Sunbeam Duck|FFE680|FF8C1A|Light||P
Dew Duck|C8FFF0|7AC8FF|Water||G
Breeze Duck|D8F0FF|FF8C1A|Normal||P
Cherub Duck|FFE0E8|FFD54A|Light|halo|P
Star Duck|FFE066|FFFFFF|Cosmic|starHat|P
Moon Duck|D8D8F0|5A5AFF|Cosmic|moonHat|P
Comet Duck|7AD8FF|FFFFFF|Cosmic|sparkle|P
Sky Knight Duck|E8F0FF|FFD54A|Light|armor,helmet,wings|M
Meteor Duck|8A5A3A|FF7A00|Fire|fireAura,crystalSpikes|P
Zodiac Duck|3A2A8A|FFD54A|Cosmic|orbitRings|P
Harp Duck|FFF0C8|FFD54A|Light|harp,halo|P
Galaxy Duck|2A1A5A|FF7AF0|Cosmic|galaxy,sparkle|N
Seraph Duck|FFFFF0|FFD54A|Light|halo,angelWings,sword|P
Constellation Duck|0A0A3A|FFFFFF|Cosmic|galaxy,orbitRings|N
Archangel Duck|FFFFFF|FFD54A|Light|halo,angelWings,armor,sword|M
Nebula Duck|8A3AFF|FF7AC8|Cosmic|galaxy,orbitRings|N
Valkyrie Duck|E8E8F0|FFD54A|Light|helmet,wings,spear,armor|M
Cosmic Duck|1A0A4A|7AF0FF|Cosmic|galaxy,orbitRings,crown|N
Celestial Dragon Duck|FFF0C8|7AD8FF|Cosmic|horns,angelWings,crystalSpikes|G
Divine Guardian Duck|FFFFFF|FFD000|Light|halo,angelWings,armor,shield|M
Celestial Emperor Duck|FFF8E0|7AD8FF|Cosmic|crown,cape,staff,orbitRings,halo|M
Fallen Star Duck|2A2A4A|FFE066|Shadow|batWings,halo,sparkle|N
Astral God Duck|FFFFFF|FF7AF0|Cosmic|crown,angelWings,staff,galaxy,orbitShards|N
]],
[8] = [[
Static Duck|7F7F8A|C8C8D8|Void||P
Null Duck|2A2A3A|8A8AFF|Void||P
Pixel Duck|5A5AFF|FF5AF0|Void|sunglasses|P
Echo Duck|8A5AFF|C8B0FF|Void||P
Dusk Duck|3A2A5A|FF8C5A|Shadow||P
Rift Duck|5A1AAA|00FFE0|Void|sparkle|P
Warp Duck|00C8FF|FF00C8|Void|goggles|P
Portal Duck|FF7A00|1A8AFF|Void|orbitRings|P
Shade Duck|1A1A2A|5A5AAA|Shadow|hood|P
Dark Matter Duck|0A0A14|7A3DFF|Void|shadowAura|N
Quantum Duck|00FFE0|5A00FF|Void|orbitBalls|N
Entropy Duck|5A005A|FF3DFF|Void|glitch|P
Paradox Duck|FFFFFF|000000|Void|monocle,tophat|P
Void Duck|14001F|B03DFF|Void|shadowAura,crystalSpikes|N|Reality Break:pierce
Abyss Walker Duck|0A0A1A|7A3DFF|Void|hood,staff,shadowAura|N
Singularity Duck|000000|FFFFFF|Void|orbitRings,orbitShards|N
Black Hole Duck|050505|FF8C00|Void|orbitRings,shadowAura,crown|N
Chaos Duck|FF003D|5A00FF|Void|glitch,horns,orbitShards|N
Oblivion Duck|1A0A2A|00FFE0|Void|hood,scythe,shadowAura|F
Reality Eater Duck|2A003A|FF00C8|Void|horns,batWings,glitch|N
Void Emperor Duck|0A001A|B03DFF|Void|crown,cape,staff,shadowAura|N
Infinity Duck|FFFFFF|7A3DFF|Cosmic|halo,orbitRings,orbitShards|F
Omega Duck|000000|FF3D3D|Void|crown,angelWings,orbitShards|N
Error 404 Duck|FF00FF|00FF00|Void|glitch,orbitShards|N
Omniduck|FFFFFF|FFD000|Cosmic|crown,angelWings,staff,halo,galaxy,orbitShards|F
]],
}

-- Exclusive ducks: Name|body|accent|Element|acc|mat|ability|rarity|world|source|req
-- source boss: req = boss id that drops it. source rebirth: req = rebirths needed to fish it.
local EXCLUSIVE = [[
Slime Duck|7CFF6B|2EAF3A|Nature|gasAura|G|Goo Slam:stun|4|1|boss|1
Captain Quackbeard|FFD93D|1A1A1A|Water|pirateHat,eyepatch,sword,cape|P|Cannon Volley:multi|5|2|boss|2
Frostbite Titan Duck|AEE4FF|FFFFFF|Ice|armor,hammer,iceAura|I|Glacier Crush:freeze|5|3|boss|3
Wyrmling Duck|E8392E|FFD23F|Fire|horns,wingsFire,fireAura|M|Inferno Breath:burn|6|4|boss|4
Umbra Duck|0A0A14|9B5BFF|Shadow|hood,shadowAura,claws|N|Umbral Rend:execute|6|5|boss|5
Guardian Duck|FFD54A|FFFFFF|Light|armor,helmet,shield,spear|M|Aegis Wall:shield|7|6|boss|6
Infernal Prince Duck|5A0000|FF3D00|Fire|horns,crown,batWings,fireAura|N|Hellgate:aoe|7|6|boss|7
Starbeast Duck|1A0A4A|FFE066|Cosmic|horns,galaxy,orbitRings|N|Starfall:aoe|8|7|boss|8
Destroyer Duck|050010|FF00C8|Void|crystalSpikes,glitch,orbitShards|N|Annihilate:pierce|9|8|boss|9
Royal Heir Duck|FFFFFF|FFD000|Cosmic|crown,angelWings,cape,scepter,orbitShards|M|Royal Decree:buff|10|8|boss|10
Reborn Duck|FFD93D|FF7AF0|Light|halo,sparkle|N|Rebirth Light:heal|5|1|rebirth|1
Ascended Duck|FFFFFF|7AF0FF|Light|halo,angelWings,sparkle|G|Ascension:buff|6|1|rebirth|3
Eternal Duck|FFE066|B03DFF|Cosmic|crown,orbitRings,sparkle|N|Eternity:drain|7|1|rebirth|5
Paragon Duck|FFFFFF|FFD000|Light|crown,armor,angelWings,sword|M|Paragon Strike:crit|8|1|rebirth|10
Godslayer Duck|0A0A0A|FF2A2A|Void|horns,crown,scythe,batWings,orbitShards|N|Godslayer:execute|10|1|rebirth|20
]]

local ABILITY_NOUN = {
	nuke="Splash", burn="Blaze", freeze="Frost Quack", poison="Toxin", crit="Strike", aoe="Wave",
	heal="Blessing", shield="Bubble Guard", drain="Siphon", stun="Quake", buff="Rally", multi="Flurry",
	execute="Finisher", pierce="Lance",
}
local ABILITY_DESC = {
	nuke="Deals %d%% bonus damage to one enemy.",
	burn="Hits for %d%% damage and burns the target for 3 turns.",
	freeze="Hits for %d%% damage and freezes the target, slowing it and possibly skipping its turn.",
	poison="Hits for %d%% damage and poisons the target, stacking damage each turn.",
	crit="A guaranteed critical hit for %d%% damage.",
	aoe="Strikes every enemy for %d%% damage (bosses take extra).",
	heal="Heals the whole team for %d%% of this duck's attack.",
	shield="Shields the team, cutting damage taken by 40%% for 2 turns, and hits for %d%%.",
	drain="Hits for %d%% damage and heals this duck for half the damage dealt.",
	stun="Hits for %d%% damage with a high chance to stun for 1 turn.",
	buff="Raises team attack by 35%% for 3 turns and hits for %d%%.",
	multi="Attacks three times, each for %d%% damage.",
	execute="Hits for %d%% damage, doubled against targets under 35%% health.",
	pierce="Hits for %d%% damage that ignores all defense.",
}
local ELEMENT_ABILITIES = {
	Normal={"nuke","multi","buff","crit","shield"}, Water={"heal","shield","aoe","nuke"},
	Fire={"burn","aoe","nuke"}, Ice={"freeze","shield","stun"}, Nature={"poison","heal","drain"},
	Shadow={"crit","drain","execute"}, Light={"heal","shield","buff","nuke"},
	Cosmic={"aoe","pierce","buff","stun"}, Void={"pierce","execute","drain","aoe"},
}
local ELEMENT_COLORS = {
	Normal=Color3.fromRGB(220,220,220), Water=Color3.fromRGB(70,160,255), Fire=Color3.fromRGB(255,110,50),
	Ice=Color3.fromRGB(160,230,255), Nature=Color3.fromRGB(110,220,90), Shadow=Color3.fromRGB(150,90,220),
	Light=Color3.fromRGB(255,235,140), Cosmic=Color3.fromRGB(255,120,220), Void=Color3.fromRGB(170,60,255),
}
DuckData.ElementColors = ELEMENT_COLORS
DuckData.AbilityDesc = ABILITY_DESC

local OPENERS = {
	"A %s duck that bobs happily around the pools of %s.",
	"Fishers in %s whisper about this %s duck.",
	"This %s duck was first spotted paddling through %s.",
	"Few have held this %s duck from %s for long.",
	"Born in the waters of %s, this %s duck never stops quacking.",
	"A %s duck with a mind of its own, native to %s.",
	"Legends from %s say this %s duck brings luck to its owner.",
	"The proud %s duck of %s floats like it owns the place.",
}
local RARITY_FLAVOR = {
	"Simple, squeaky and adorable.", "A little faster than its friends.", "Quick and slippery on the hook.",
	"Changes direction without warning.", "Its very presence makes the water shimmer.", "Radiates raw, untamed power.",
	"Blessed by forces beyond the pools.", "Its glow can be seen from across the sky.", "Nobody is sure it should exist.",
	"A being beyond rarity itself.",
}

local function hash(s: string): number
	local h = 5381
	for i = 1, #s do h = (h * 33 + string.byte(s, i)) % 2147483647 end
	return h
end
DuckData.Hash = hash

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

DuckData.List = {}   -- array by Id
DuckData.ByName = {}
DuckData.Pools = {}  -- Pools[world][rarity] = {ids} (fishable only)
DuckData.RebirthDucks = {} -- {id=..., req=...}
DuckData.BossDrops = {}    -- [bossId] = {ids}

local function build(id, world, rarityIndex, fields, source, req)
	local name = fields[1]
	local h = hash(name)
	local function var(k) return 0.88 + ((h // k) % 25) / 100 end -- 0.88..1.12
	local elem = fields[4]
	local accessories = {}
	if fields[5] and fields[5] ~= "" then
		for a in string.gmatch(fields[5], "[^,]+") do table.insert(accessories, a) end
	end
	local abilityName, abilityType
	if fields[7] and fields[7] ~= "" then
		abilityName, abilityType = string.match(fields[7], "^(.-):(%a+)$")
	end
	if not abilityType then
		local opts = ELEMENT_ABILITIES[elem] or ELEMENT_ABILITIES.Normal
		abilityType = opts[(h % #opts) + 1]
		local first = string.match(name, "^(%S+)") or "Quack"
		if first == "Classic" then first = "Squeaky" end
		abilityName = first .. " " .. ABILITY_NOUN[abilityType]
	end
	local tier = Rarity.List[rarityIndex]
	local w = WorldData.List[world]
	local sm = tier.StatMult * w.StatMult
	local power = math.floor((1.5 + 0.22 * rarityIndex) * 100) -- % of attack
	if abilityType == "multi" then power = math.floor(power * 0.45) end
	if abilityType == "heal" then power = math.floor(power * 0.6) end
	local opener = OPENERS[(h % #OPENERS) + 1]
	local adj = string.lower(tier.Name)
	local desc
	if string.find(opener, "^Born") or string.find(opener, "^Fishers") or string.find(opener, "^Legends") or string.find(opener, "^The proud") then
		desc = string.format(opener, w.Name, adj)
	else
		desc = string.format(opener, adj, w.Name)
	end
	if string.find(opener, "^The proud") then desc = string.format(opener, adj, w.Name) end
	desc ..= " " .. RARITY_FLAVOR[rarityIndex]
	local duck = {
		Id = id, Name = name, World = world, Rarity = rarityIndex, RarityName = tier.Name,
		Body = hex(fields[2]), Accent = hex(fields[3]), Element = elem,
		Accessories = accessories, Material = fields[6] ~= "" and fields[6] or "P",
		Attack = math.floor(10 * sm * var(7)), Health = math.floor(60 * sm * var(11)),
		Defense = math.floor(4 * sm * var(13)), Speed = math.floor((10 + rarityIndex * 2.5) * var(17)),
		Crit = math.floor((5 + rarityIndex * 1.6) * 10) / 1000, -- fraction
		Ability = {Name = abilityName, Type = abilityType, Power = power,
			Cooldown = (abilityType == "heal" or abilityType == "shield" or abilityType == "buff") and 3 or 2,
			Desc = string.format(ABILITY_DESC[abilityType], power)},
		CatchDifficulty = math.floor(rarityIndex * 10 * var(19)) / 10, -- shown in UI (1..~11)
		CatchSpeedMult = var(23), -- per-duck tweak to minigame duck speed
		Description = desc,
		Source = source, SourceReq = req,
		Scale = 1 + (rarityIndex - 1) * 0.045,
		SellValue = math.floor(tier.Coins * 0.6 * w.StatMult),
	}
	DuckData.List[id] = duck
	DuckData.ByName[name] = duck
	return duck
end

local function split(line)
	local f = {}
	for part in string.gmatch(line .. "|", "(.-)|") do table.insert(f, part) end
	return f
end

local nextId = 1
for world = 1, #WorldData.List do
	DuckData.Pools[world] = {}
	for r = 1, #Rarity.List do DuckData.Pools[world][r] = {} end
	local i = 0
	for line in string.gmatch(RAW[world], "[^\n]+") do
		i += 1
		local rarityIndex = WORLD_RARITY_LAYOUT[i]
		assert(rarityIndex, "Too many ducks in world " .. world)
		local d = build(nextId, world, rarityIndex, split(line), "fish", 0)
		table.insert(DuckData.Pools[world][rarityIndex], d.Id)
		nextId += 1
	end
	assert(i == 25, "World " .. world .. " has " .. i .. " ducks")
end
DuckData.FISHABLE_COUNT = nextId - 1

for line in string.gmatch(EXCLUSIVE, "[^\n]+") do
	local f = split(line)
	local rarityIndex, world, source, req = tonumber(f[8]), tonumber(f[9]), f[10], tonumber(f[11])
	local d = build(nextId, world, rarityIndex, f, source, req)
	if source == "boss" then
		DuckData.BossDrops[req] = DuckData.BossDrops[req] or {}
		table.insert(DuckData.BossDrops[req], d.Id)
	else
		table.insert(DuckData.RebirthDucks, {Id = d.Id, Req = req, Rarity = rarityIndex})
	end
	nextId += 1
end
DuckData.TOTAL = nextId - 1

-- Picks a duck for a world+rarity. Rebirth-exclusive ducks join the pool once unlocked.
function DuckData.Pick(rng: Random, world: number, rarityIndex: number, rebirths: number): number
	local pool = table.clone(DuckData.Pools[world][rarityIndex])
	for _, rd in DuckData.RebirthDucks do
		if rd.Rarity == rarityIndex and rebirths >= rd.Req then table.insert(pool, rd.Id) end
	end
	if #pool == 0 then pool = DuckData.Pools[world][1] end
	return pool[rng:NextInteger(1, #pool)]
end

-- Stats at a given duck level (+8% per level)
function DuckData.StatsAt(duck, level: number)
	local m = 1 + (level - 1) * 0.08
	return {
		Attack = math.floor(duck.Attack * m), Health = math.floor(duck.Health * m),
		Defense = math.floor(duck.Defense * m), Speed = duck.Speed + math.floor((level - 1) * 0.3),
		Crit = duck.Crit,
	}
end

function DuckData.Power(duck, level: number): number
	local s = DuckData.StatsAt(duck, level)
	return math.floor(s.Attack * 2 + s.Health * 0.5 + s.Defense * 1.5 + s.Speed)
end

DuckData.MAX_LEVEL = 50
function DuckData.LevelCost(duck, level: number): number
	return math.floor(15 * (level ^ 1.6) * Rarity.List[duck.Rarity].StatMult * WorldData.List[duck.World].StatMult)
end

return DuckData
