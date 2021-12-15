local MAX_STAT_AMOUNT = 20

local function clampStat(stat)
	return math.clamp(stat or 0, 0, MAX_STAT_AMOUNT)
end

local StatFunctions = {}

function StatFunctions:AdjustForHaste(baseValue, haste)
	haste = clampStat(haste)
	return baseValue * (1 - haste/25)
end

function StatFunctions:AdjustForStrength(baseValue, strength)
	strength = clampStat(strength)
	return baseValue * (1+strength/10)
end

function StatFunctions:AdjustForDefense(baseValue, defense)
	defense = clampStat(defense)
	return baseValue * (1+defense/10)
end

function StatFunctions:AdjustForMagic(baseValue, magic)
	magic = clampStat(magic)
	return baseValue * (1+magic/10)
end

function StatFunctions:AdjustForHealth(baseValue, health)
	health = clampStat(health)
	return baseValue * (1+health/10)
end

function StatFunctions:AdjustForAgility(baseValue, agility, adjustType)
	agility = clampStat(agility)

	if not adjustType then
		return baseValue * (1+agility/10)
	elseif adjustType == "speed" then
		return baseValue * (1+agility/20)
	elseif adjustType == "jump" then
		return baseValue * (1+agility/30)
	end
end

function StatFunctions:AdjustDamageForPlayerShields(player, damage)
	local playerCharacter = player.Character
	local playerShields = playerCharacter.Shields

	for _,shield in pairs(playerShields:GetChildren()) do
		local shieldValue = shield.Value
		shield.Value -= damage
		damage = math.clamp(damage - shieldValue, 0, 1000000)

		if shield.Value <= 0 then shield:Destroy() end
		if damage <= 0 then break end
	end

	return damage
end

return StatFunctions