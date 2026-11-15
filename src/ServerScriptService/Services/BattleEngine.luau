-- Turn-based battle engine (server only). Produces an event log the client plays back.
-- Units act in speed order each round. Player-controlled units wait for an action; others use AI.
local Engine = {}
Engine.__index = Engine

local STRONG = {
	Water = {Fire = true}, Fire = {Nature = true, Ice = true}, Nature = {Water = true}, Ice = {Nature = true},
	Light = {Shadow = true, Void = false}, Shadow = {Light = true, Cosmic = true}, Cosmic = {Void = true}, Void = {Light = true},
}
function Engine.ElementMult(a: string, b: string): (number, string?)
	if STRONG[a] and STRONG[a][b] then return 1.5, "strong" end
	if STRONG[b] and STRONG[b][a] then return 0.75, "weak" end
	return 1, nil
end

-- unit def: {Id, Name, Side, Attack, Health, Defense, Speed, Crit, Element, Ability, SpecialMult, IsBoss, Attacks, Controlled, DuckId, BossId, Level, Stars}
function Engine.new(units, opts)
	local self = setmetatable({}, Engine)
	self.Rng = Random.new(opts and opts.Seed or nil)
	self.Units = {}
	self.ById = {}
	for _, u in units do
		local unit = table.clone(u)
		unit.MaxHp = u.Health
		unit.Hp = u.Health
		unit.Cd = 0
		unit.St = {}
		unit.Alive = true
		table.insert(self.Units, unit)
		self.ById[unit.Id] = unit
	end
	self.Round = 0
	self.Queue = {}
	self.MaxRounds = opts and opts.MaxRounds or 50
	self.Over = false
	self.Winner = nil
	return self
end

function Engine:Snapshot()
	local out = {}
	for _, u in self.Units do
		table.insert(out, {Id = u.Id, Name = u.Name, Side = u.Side, Hp = u.Hp, MaxHp = u.MaxHp, Element = u.Element,
			DuckId = u.DuckId, BossId = u.BossId, Level = u.Level, Stars = u.Stars, Speed = u.Speed,
			Ability = u.Ability and {Name = u.Ability.Name, Type = u.Ability.Type, Cooldown = u.Ability.Cooldown, Desc = u.Ability.Desc} or nil,
			Cd = u.Cd})
	end
	return out
end

local function alive(self, side)
	local list = {}
	for _, u in self.Units do if u.Alive and u.Side == side then table.insert(list, u) end end
	return list
end
Engine.Alive = alive

local function other(side) return if side == "A" then "B" else "A" end

function Engine:_checkEnd(ev)
	local a, b = #alive(self, "A"), #alive(self, "B")
	if a == 0 or b == 0 then
		self.Over = true
		self.Winner = if a > 0 then "A" else "B"
		table.insert(ev, {t = "end", winner = self.Winner})
		return true
	end
	return false
end

function Engine:_damage(ev, src, dst, mult, opts)
	opts = opts or {}
	local em, eff = Engine.ElementMult(src.Element, dst.Element)
	local atk = src.Attack * (if src.St.buff then 1.35 else 1) * (if src.Enraged then 1.4 else 1)
	local base = atk * mult * em * self.Rng:NextNumber(0.9, 1.1)
	local def = if opts.pierce then 0 else dst.Defense
	local dmg = base * (atk / (atk + def))
	local crit = opts.crit or self.Rng:NextNumber() < (src.Crit or 0.05)
	if crit then dmg *= if opts.crit then 1.5 else 1.8 end
	if dst.St.shield then dmg *= 0.6 end
	if opts.pvpScale then dmg *= opts.pvpScale end
	dmg = math.max(1, math.floor(dmg))
	dst.Hp = math.max(0, dst.Hp - dmg)
	table.insert(ev, {t = "hit", src = src.Id, dst = dst.Id, dmg = dmg, crit = crit, eff = eff, skill = opts.skill, kind = opts.kind, hp = dst.Hp})
	if dst.Hp <= 0 and dst.Alive then
		dst.Alive = false
		table.insert(ev, {t = "die", u = dst.Id})
	end
	return dmg
end

function Engine:_heal(ev, src, dst, amount)
	if not dst.Alive then return end
	local amt = math.floor(math.min(dst.MaxHp - dst.Hp, amount))
	dst.Hp += amt
	table.insert(ev, {t = "heal", src = src.Id, dst = dst.Id, amt = amt, hp = dst.Hp})
end

function Engine:_status(ev, dst, s, value)
	dst.St[s] = value
	table.insert(ev, {t = "status", dst = dst.Id, s = s})
end

local function lowest(list)
	local best
	for _, u in list do if not best or u.Hp / u.MaxHp < best.Hp / best.MaxHp then best = u end end
	return best
end

-- Duck special abilities
function Engine:_special(ev, u, target)
	local ab = u.Ability
	local p = ab.Power / 100 * (u.SpecialMult or 1)
	local foes = alive(self, other(u.Side))
	local allies = alive(self, u.Side)
	local o = {skill = ab.Name, kind = ab.Type, pvpScale = u.PvPScale}
	local t = ab.Type
	if t == "nuke" then
		self:_damage(ev, u, target, p, o)
	elseif t == "burn" then
		self:_damage(ev, u, target, p * 0.7, o)
		if target.Alive then self:_status(ev, target, "burn", {turns = 3, dmg = math.floor(u.Attack * 0.25 * (u.PvPScale or 1))}) end
	elseif t == "freeze" then
		self:_damage(ev, u, target, p * 0.7, o)
		if target.Alive then self:_status(ev, target, "freeze", 2) end
	elseif t == "poison" then
		self:_damage(ev, u, target, p * 0.6, o)
		if target.Alive then
			local cur = target.St.poison
			self:_status(ev, target, "poison", {stacks = math.min(5, (cur and cur.stacks or 0) + 1), turns = 4, dmg = math.floor(u.Attack * 0.12 * (u.PvPScale or 1))})
		end
	elseif t == "crit" then
		o.crit = true
		self:_damage(ev, u, target, p, o)
	elseif t == "aoe" then
		local m = if #foes == 1 then p * 0.9 else p * 0.6
		for _, f in foes do self:_damage(ev, u, f, m, o) end
	elseif t == "heal" then
		table.insert(ev, {t = "cast", src = u.Id, skill = ab.Name, kind = t})
		for _, a in allies do self:_heal(ev, u, a, u.Attack * p) end
	elseif t == "shield" then
		for _, a in allies do self:_status(ev, a, "shield", 2) end
		self:_damage(ev, u, target, p * 0.5, o)
	elseif t == "drain" then
		local dmg = self:_damage(ev, u, target, p, o)
		self:_heal(ev, u, u, dmg * 0.5)
	elseif t == "stun" then
		self:_damage(ev, u, target, p * 0.6, o)
		if target.Alive and self.Rng:NextNumber() < (if target.IsBoss then 0.35 else 0.6) then self:_status(ev, target, "stun", 1) end
	elseif t == "buff" then
		for _, a in allies do self:_status(ev, a, "buff", 3) end
		self:_damage(ev, u, target, p * 0.5, o)
	elseif t == "multi" then
		for _ = 1, 3 do
			if not target.Alive then
				target = lowest(alive(self, other(u.Side)))
				if not target then break end
			end
			self:_damage(ev, u, target, p, o)
		end
	elseif t == "execute" then
		local m = if target.Hp / target.MaxHp < 0.35 then p * 1.6 else p * 0.8
		self:_damage(ev, u, target, m, o)
	elseif t == "pierce" then
		o.pierce = true
		self:_damage(ev, u, target, p, o)
	else
		self:_damage(ev, u, target, p, o)
	end
	u.Cd = ab.Cooldown
end

-- Boss AI
function Engine:_bossAct(ev, u)
	local foes = alive(self, other(u.Side))
	local options = {}
	for _, a in u.Attacks do
		local w = 1
		if a.Type == "single" then w = 3 end
		if a.Type == "heal" then w = if u.Hp / u.MaxHp < 0.5 then 1.5 else 0 end
		if a.Type == "enrage" then w = if (not u.Enraged and u.Hp / u.MaxHp < 0.55) then 4 else 0 end
		if a.Type == "shield" then w = if u.St.shield then 0 else 0.8 end
		if w > 0 then table.insert(options, {a = a, w = w}) end
	end
	local total = 0
	for _, o in options do total += o.w end
	local roll = self.Rng:NextNumber() * total
	local pick = options[1].a
	for _, o in options do roll -= o.w; if roll <= 0 then pick = o.a break end end
	local target = if self.Rng:NextNumber() < 0.5 then lowest(foes) else foes[self.Rng:NextInteger(1, #foes)]
	local o = {skill = pick.Name, kind = pick.Type}
	local t = pick.Type
	if t == "aoe" then
		for _, f in foes do self:_damage(ev, u, f, pick.Power, o) end
	elseif t == "burn" then
		self:_damage(ev, u, target, pick.Power, o)
		if target.Alive then self:_status(ev, target, "burn", {turns = 3, dmg = math.floor(u.Attack * 0.2)}) end
	elseif t == "stun" then
		self:_damage(ev, u, target, pick.Power, o)
		if target.Alive and self.Rng:NextNumber() < 0.7 then self:_status(ev, target, "stun", 1) end
	elseif t == "heal" then
		table.insert(ev, {t = "cast", src = u.Id, skill = pick.Name, kind = t})
		self:_heal(ev, u, u, u.MaxHp * pick.Power)
	elseif t == "drain" then
		local dmg = self:_damage(ev, u, target, pick.Power, o)
		self:_heal(ev, u, u, dmg * 0.5)
	elseif t == "enrage" then
		u.Enraged = true
		table.insert(ev, {t = "cast", src = u.Id, skill = pick.Name, kind = t})
		self:_status(ev, u, "enrage", true)
	elseif t == "shield" then
		table.insert(ev, {t = "cast", src = u.Id, skill = pick.Name, kind = t})
		self:_status(ev, u, "shield", 2)
	else
		self:_damage(ev, u, target, pick.Power, o)
	end
end

-- Start-of-turn effects. Returns false if the unit loses its turn.
function Engine:_startTurn(ev, u): boolean
	local st = u.St
	if st.burn then
		local dmg = math.max(1, st.burn.dmg)
		u.Hp = math.max(0, u.Hp - dmg)
		table.insert(ev, {t = "dot", dst = u.Id, dmg = dmg, s = "burn", hp = u.Hp})
		st.burn.turns -= 1
		if st.burn.turns <= 0 then st.burn = nil end
	end
	if st.poison and u.Hp > 0 then
		local dmg = math.max(1, st.poison.dmg * st.poison.stacks)
		u.Hp = math.max(0, u.Hp - dmg)
		table.insert(ev, {t = "dot", dst = u.Id, dmg = dmg, s = "poison", hp = u.Hp})
		st.poison.turns -= 1
		if st.poison.turns <= 0 then st.poison = nil end
	end
	if u.Hp <= 0 then
		u.Alive = false
		table.insert(ev, {t = "die", u = u.Id})
		return false
	end
	if st.shield then st.shield -= 1; if st.shield <= 0 then st.shield = nil end end
	if st.buff then st.buff -= 1; if st.buff <= 0 then st.buff = nil end end
	if u.Cd > 0 then u.Cd -= 1 end
	if st.stun then
		st.stun = nil
		table.insert(ev, {t = "skip", u = u.Id, s = "stun"})
		return false
	end
	if st.freeze then
		st.freeze -= 1
		local skip = self.Rng:NextNumber() < 0.35
		if st.freeze <= 0 then st.freeze = nil end
		if skip then
			table.insert(ev, {t = "skip", u = u.Id, s = "freeze"})
			return false
		end
	end
	return true
end

function Engine:_buildQueue()
	self.Round += 1
	local q = {}
	for _, u in self.Units do if u.Alive then table.insert(q, u) end end
	table.sort(q, function(a, b)
		local sa = a.Speed * (if a.St.freeze then 0.5 else 1)
		local sb = b.Speed * (if b.St.freeze then 0.5 else 1)
		if sa == sb then return a.Id < b.Id end
		return sa > sb
	end)
	self.Queue = q
end

-- Advances automatically until a Controlled unit needs input (returns it) or the battle ends.
function Engine:Advance(ev)
	while not self.Over do
		if #self.Queue == 0 then
			if self.Round >= self.MaxRounds then
				self.Over = true
				self.Winner = self.TimeoutWinner or self:_timeoutWinner()
				table.insert(ev, {t = "end", winner = self.Winner, timeout = true})
				return nil
			end
			self:_buildQueue()
			table.insert(ev, {t = "round", n = self.Round})
		end
		local u = table.remove(self.Queue, 1)
		if u.Alive then
			table.insert(ev, {t = "turn", u = u.Id})
			local canAct = self:_startTurn(ev, u)
			if self:_checkEnd(ev) then return nil end
			if canAct then
				if u.Controlled then
					self.Waiting = u
					return u
				end
				self:_aiAct(ev, u)
				if self:_checkEnd(ev) then return nil end
			end
		end
	end
	return nil
end

function Engine:_aiAct(ev, u)
	if u.IsBoss then return self:_bossAct(ev, u) end
	local foes = alive(self, other(u.Side))
	local target = lowest(foes)
	local useSpecial = u.Ability and u.Cd == 0
	if useSpecial and u.Ability.Type == "heal" then
		local hurt = false
		for _, a in alive(self, u.Side) do if a.Hp / a.MaxHp < 0.7 then hurt = true end end
		useSpecial = hurt
	end
	if useSpecial then
		self:_special(ev, u, target)
	else
		self:_damage(ev, u, target, 1, {pvpScale = u.PvPScale})
	end
end

-- Player action for the waiting unit. action: "attack" | "special"; targetId optional.
function Engine:Act(action: string, targetId: string?)
	local ev = {}
	local u = self.Waiting
	if not u or self.Over then return nil, "Not your turn" end
	local foes = alive(self, other(u.Side))
	local target = targetId and self.ById[targetId]
	if not target or not target.Alive or target.Side == u.Side then target = lowest(foes) end
	if action == "special" then
		if not u.Ability or u.Cd > 0 then return nil, "Special not ready" end
		self:_special(ev, u, target)
	else
		self:_damage(ev, u, target, 1, {pvpScale = u.PvPScale})
	end
	self.Waiting = nil
	if not self:_checkEnd(ev) then
		self:Advance(ev)
	end
	return ev
end

function Engine:_timeoutWinner()
	local function pct(side)
		local hp, max = 0, 0
		for _, u in self.Units do if u.Side == side then hp += u.Hp; max += u.MaxHp end end
		return if max > 0 then hp / max else 0
	end
	return if pct("A") >= pct("B") then "A" else "B"
end

-- Fully automatic battle (PvP)
function Engine:RunAuto()
	local ev = {}
	for _, u in self.Units do u.Controlled = false end
	self:Advance(ev)
	return ev
end

return Engine
