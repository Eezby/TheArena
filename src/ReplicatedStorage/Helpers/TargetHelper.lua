local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))
local PlayerCooldowns = require(RepServices:WaitForChild("PlayerCooldowns"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local CollectionSelect = require(Utility:WaitForChild("CollectionSelect"))


local EffectService
local EffectReplicator

if not IsServer then
	local LocalPlayer = Players.LocalPlayer
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerServices = PlayerScripts:WaitForChild("Services")
	EffectReplicator = require(PlayerServices:WaitForChild("EffectReplicator"))
else
	local SerServices = ServerScriptService.Services
	EffectService = require(SerServices.EffectService)
end

local TargetHelper = {}

function TargetHelper:CanUseAbility(player, abilityData, target)
	if not IsServer then
		if PlayerValues:GetValue(player, "IsMoving") and not abilityData.movingCast then
			if abilityData.castTime and abilityData.castTime > 0 then
				return false, "Cant cast while moving"
			end
		end
		
		local playerCastInfo = PlayerValues:GetValue(player, "CastInfo")

		if playerCastInfo then
			return false, "Currently casting something"
		end
		
		if EffectReplicator:IsCCed(player.Character) then
			return false, "Crowd controled"
		end
	else
		if EffectService:IsCCed(player.Character) then
			return false, "Crowd controled"
		end
	end
	
	if abilityData.maxCharge then
		if not PlayerCooldowns:HasCharge(player, abilityData.name) then
			return false, "No charges, on cooldown"
		end
	else
		if not PlayerCooldowns:IsReady(player, abilityData.name) then
			return false, "Not off cooldown"
		end
	end

	if not abilityData then
		return false, "No ability data"
	end

	if not TargetHelper:IsViableTarget(player.Character, (target or {model = nil}).model, abilityData.targetType) then
		return false, "Invalid target"
	end

	if target ~= nil and not TargetHelper:IsTargetInRange(player.Character:GetPivot().Position, target.model, abilityData.range) then
		return false, "Target out of range"
	end

	if PlayerValues:GetValue(player, "Health") <= 0 then
		return false, "Cant cast when dead"
	end

	-- check if the ability belongs to the class

	return true
end

function TargetHelper:IsViableTarget(sender, target, targetType)
	if target then
		if targetType == "enemy" then
			if target == sender then
				return false
			end
			
			return true
		elseif targetType == "ally" then
			return true
		elseif targetType == "any" then
			return true
		end
	end
	
	return targetType == "none"
end

function TargetHelper:IsTargetInRange(position, target, range)
	return not target or range == nil or (position - target:GetPivot().Position).Magnitude <= range
end

-- args: 
-- [int] range
function TargetHelper:GetNearbyTargets(sender, position, targetType, args)
	local targets = CollectionSelect:SelectAll({"Player", "NPC"}) -- can probably be optimized with callback
	local filteredTargets = {}
	
	for _,target in ipairs(targets) do
		if self:IsViableTarget(sender, target, targetType) then -- check targetType
			if self:IsTargetInRange(position, target, args.range) then -- check range
				table.insert(filteredTargets, target)
			end
		end
	end
	
	return filteredTargets
end
return TargetHelper