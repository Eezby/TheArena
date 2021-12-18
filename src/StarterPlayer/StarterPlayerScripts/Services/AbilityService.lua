local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local RepData = ReplicatedStorage:WaitForChild("Data")
local AbilityData = require(RepData:WaitForChild("AbilityData"))

local Helpers = ReplicatedStorage:WaitForChild("Helpers")
local TargetHelper = require(Helpers:WaitForChild("TargetHelper"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local AbilityFunctionsSignal = Utility:WaitForChild("AbilityFunctions"):WaitForChild("Signal")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerUiModules = PlayerScripts:WaitForChild("Ui")
local CastbarUi = require(PlayerUiModules:WaitForChild("CastbarUi"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClientInputRemote = Remotes:WaitForChild("ClientInput")

local function cancelOnMove(ability, castTime, identifier)
	local endTime = tick() + castTime

	while tick() < endTime do
		if PlayerValues:GetValue(LocalPlayer, "IsMoving") then
			AbilityFunctionsSignal:Fire("RunAbilityFunction", ability, "StopCast", LocalPlayer, identifier)
			CastbarUi:Cancel()
			break
		end

		task.wait()
	end
end

local AbilityService = {}

function AbilityService:NormalAbility(castIdentifier, ability, args)
	local abilityData = AbilityData[ability]

	local abilityIsAvailable, errorMessage = TargetHelper:CanUseAbility(LocalPlayer, abilityData, args.target)
	if abilityIsAvailable then
		local argsToSend = {}
		for property,value in pairs(args) do
			argsToSend[property] = value
		end

		if argsToSend.target then
			argsToSend.target = {
				entityId = argsToSend.target.entity.Id
			}
		end

		ClientInputRemote:FireServer("ability-start", SharedFunctions:GetTime(), {
			ability = ability,
			id = castIdentifier,
			args = argsToSend
		})
		
		AbilityFunctionsSignal:Fire("RunAbilityFunction", ability, "ClientAbility", LocalPlayer, castIdentifier, argsToSend, SharedFunctions:GetTime())

		if (abilityData.castTime and abilityData.castTime > 0) then
			CastbarUi:Cast(ability, abilityData.castTime)

			if not abilityData.movingCast then
				task.spawn(cancelOnMove, ability, abilityData.castTime, castIdentifier)
			end
		end
	else
		warn(errorMessage)
	end
end


function AbilityService:PlacementAbility(castIdentifier, ability)
	local abilityData = AbilityData[ability]
	
	AbilityFunctionsSignal:Fire("RunAbilityFunction", ability, "StartPlacement", LocalPlayer, castIdentifier, SharedFunctions:GetTime())
end

return AbilityService