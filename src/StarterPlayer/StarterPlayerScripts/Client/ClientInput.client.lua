local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RepData = ReplicatedStorage:WaitForChild("Data")
local AbilityData = require(RepData:WaitForChild("AbilityData"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local AbilityFunctions = require(Utility:WaitForChild("AbilityFunctions"))

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerCooldowns = require(RepServices:WaitForChild("PlayerCooldowns"))
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local Helpers = ReplicatedStorage:WaitForChild("Helpers")
local TargetHelper = require(Helpers:WaitForChild("TargetHelper"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClientInputRemote = Remotes:WaitForChild("ClientInput")

local Utility = ReplicatedStorage.Utility
local StatFunctions = require(Utility:WaitForChild("StatFunctions"))
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerServices = PlayerScripts:WaitForChild("Services")
local EffectReplicator = require(PlayerServices:WaitForChild("EffectReplicator"))
local AbilityService = require(PlayerServices:WaitForChild("AbilityService"))
local EntityHandler = require(PlayerServices:WaitForChild("EntityHandler"))

local PlayerUiModules = PlayerScripts:WaitForChild("Ui")
local HotbarUi = require(PlayerUiModules:WaitForChild("HotbarUi"))
local CastbarUi = require(PlayerUiModules:WaitForChild("CastbarUi"))

local PlayerEntity = EntityHandler.GetPlayerEntity(LocalPlayer, true)

local CastIdentifier = 0

local function getCharacter(keyValue)
	local character = " "
	
	local success, message = pcall(function()
		character = string.char(keyValue)
	end)
	
	return string.upper(character)
end

local function useAbility(ability, keyCharacter)
	local abilityData = AbilityData[ability]
	local currentTarget = PlayerEntity.Target
	
	CastIdentifier += 1
	
	local currentCastIdentifier = CastIdentifier
	
	if abilityData.placement then
		AbilityService:PlacementAbility(currentCastIdentifier, ability)
	else
		AbilityService:NormalAbility(currentCastIdentifier, ability, {
			target = currentTarget
		})
	end
end

local inputBegan = UserInputService.InputBegan:Connect(function(input, override)
	if not override then
		local keyCharacter = getCharacter(input.KeyCode.Value)
		local slot = HotbarUi:GetSlotFromKey(keyCharacter)

		if slot and slot.ability then
			useAbility(slot.ability, keyCharacter)
		end
	end
end)