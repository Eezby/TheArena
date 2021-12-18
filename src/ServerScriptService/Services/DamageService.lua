local Signal = Instance.new("BindableEvent")
Signal.Name = "Signal"
Signal.Parent = script

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RepData = ReplicatedStorage.Data
local AbilityData = require(RepData.AbilityData)

local Helpers = ReplicatedStorage.Helpers
local TargetHelper = require(Helpers.TargetHelper)

local SerServices = ServerScriptService.Services
local EffectService = require(SerServices.EffectService)
local ShieldService = require(SerServices.ShieldService)

local Utility = ReplicatedStorage.Utility
local StatFunctions = require(Utility.StatFunctions)

local RepServices = ReplicatedStorage.Services
local PlayerValues = require(RepServices.PlayerValues)

local Remotes = ReplicatedStorage.Remotes
local OverheadRemote = Instance.new("RemoteEvent")
OverheadRemote.Name = "Overhead"
OverheadRemote.Parent = Remotes

local function convertDictionaryToTable(dictionary)
	local tbl = {}

	for player,_ in pairs(dictionary) do
		table.insert(tbl, player)
	end

	return tbl
end

local function testCriticalHit(args)
	local isCritical = false
	local critChance = math.random(1,100)
	local extraCritChance = 0
	
	if args.ability then
		local abilityData = AbilityData[args.ability]
		extraCritChance += (abilityData.critChance or 0)
	end
	
	if critChance <= (0.25 + extraCritChance)*100 then
		return true
	end
	
	return false
end

local DamageService = {}

function DamageService:DoDamage(targets, args)
	if not args then args = {} end
	if typeof(targets) ~= "table" then targets = {targets} end
	if #targets == 0 then targets = {targets} end

	if not targets[1] then targets = convertDictionaryToTable(targets) end
	
	local damage = args.damage
	
	if args.ability then
		local abilityData = AbilityData[args.ability]
		damage = abilityData.damage
	end

	for _,target in pairs(targets) do
		local player = target
		if not player then
			if target:IsDescendantOf(Players) then
				player = target
			end
		end
		
		local maxHealth = nil
		
		if player then
			maxHealth = PlayerValues:GetValue(player, "MaxHealth")
		end
		
		local adjustedDamage = damage

		if args.percent then
			adjustedDamage = maxHealth * damage
		end
		
		if args.splitDamage then
			adjustedDamage /= #targets
		end
		
		local isCriticalHit = testCriticalHit(args)
		if isCriticalHit then
			adjustedDamage *= 2
		end
		
		adjustedDamage = ShieldService:TakeDamage(args.fromPlayer, target, adjustedDamage)
		
		if adjustedDamage > 0 then
			if player and player.Character then
				PlayerValues:IncrementValue(player, "Health", -adjustedDamage, true)
			elseif not player then
				target.Humanoid:TakeDamage(adjustedDamage)
			end
			
			EffectService:TookDamage(target, args.damageType, args.fromPlayer)
			
			if args.fromPlayer then
				OverheadRemote:FireAllClients("damage", args.fromPlayer, target:GetCFrame().Position, adjustedDamage, {
					isCrit = isCriticalHit
				})
			end
		end
	end
end

function DamageService:GiveShield(targets, args)
	if not args then args = {} end
	if typeof(targets) ~= "table" then targets = {targets} end

	if not targets[1] then targets = convertDictionaryToTable(targets) end
	
	local shield = args.shield
	
	if args.ability then
		local abilityData = AbilityData[args.ability]
		shield = abilityData.shield
	end
	
	for _,target in pairs(targets) do
		local player = Players:GetPlayerFromCharacter(target)
		if not player then
			if target:IsDescendantOf(Players) then
				player = target
			end
		end

		local maxHealth = nil


		local adjustedShield = shield

		if args.percent then
			adjustedShield = maxHealth * shield
		end

		adjustedShield = adjustedShield -- adjust for shields and reductions
		
		ShieldService:GiveShield(args.fromPlayer, target, adjustedShield, args.shieldIdentifier, args)
	end
end

Signal.Event:Connect(function(func, ...)
	if DamageService[func] then
		DamageService[func](...)
	end
end)

return DamageService