local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RepData = ReplicatedStorage.Data
local AbilityData = require(RepData.AbilityData)
local StatData = require(RepData.StatData)

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility.SharedFunctions)
local AbilityFunctions = require(Utility.AbilityFunctions)

local SerServices = ServerScriptService.Services
local EffectService = require(SerServices.EffectService)

local Helpers = ReplicatedStorage.Helpers
local TargetHelper = require(Helpers.TargetHelper)

local RepServices = ReplicatedStorage.Services
local PlayerValues = require(RepServices.PlayerValues)
local PlayerCooldowns = require(RepServices.PlayerCooldowns)
local PlayerStatusService = require(RepServices.PlayerStatusService)

local Remotes = ReplicatedStorage.Remotes

local ClientInputRemote = Instance.new("RemoteEvent")
ClientInputRemote.Name = "ClientInput"
ClientInputRemote.Parent = Remotes

local TargetRemote = Instance.new("RemoteEvent")
TargetRemote.Name = "Target"
TargetRemote.Parent = Remotes

local function cancelOnMove(player, abilityScript, castTime, identifier)
	local endTime = tick() + castTime
	
	while tick() < endTime do
		if PlayerValues:GetValue(player, "IsMoving") then
			abilityScript:StopCast(player, identifier)
			break
		end
		
		task.wait()
	end
end

local ClientService = {}

function ClientService.InitializeClient(player, profile)
	PlayerStatusService:AddPlayer(player)
	
	task.wait(3)
	PlayerValues:SetValue(player, "Experience", profile.Data.Experience, true)
	PlayerValues:SetValue(player, "Level", profile.Data.Level, true)
	
	for stat, info in pairs(StatData) do
		PlayerValues:SetValue(player, stat, 2.75, true)
	end
	
	PlayerValues:SetValue(player, "Class", "Fire Mage", true)
	PlayerValues:SetValue(player, "Health", 125, true)
	PlayerValues:SetValue(player, "MaxHealth", 125, true)
	PlayerValues:SetValue(player, "Power", 100, true)
	PlayerValues:SetValue(player, "MaxPower", 100, true)
end

function ClientService:UseAbility(player, ability, identifier, args, startTime)
	local timeDifference = math.abs(SharedFunctions:GetTime() - startTime)
	
	local abilityData = AbilityData[ability]
	local abilityIsAvailable, errorMessage = TargetHelper:CanUseAbility(player, abilityData, args.target)
	
	if abilityIsAvailable then		
		local abilityScript = AbilityFunctions:GetAbilityScript(ability)
		if abilityScript then
			task.spawn(abilityScript.ServerAbility, self, player, identifier, args, startTime)
			
			if (abilityData.castTime and abilityData.castTime > 0) and not abilityData.movingCast then
				task.wait(timeDifference * 25)
				task.spawn(cancelOnMove, player, abilityScript, abilityData.castTime, identifier)
			end
		end
	else
		warn("[server]", errorMessage)
	end
end


ClientInputRemote.OnServerEvent:Connect(function(client, action, startTime, args)
	if action == "ability-start" then
		ClientService:UseAbility(client, args.ability, args.id, args.args, startTime)
	end
end)

TargetRemote.OnServerEvent:Connect(function(client, target)
	PlayerValues:SetValue(client, "Target", target, true)
end)

return ClientService
