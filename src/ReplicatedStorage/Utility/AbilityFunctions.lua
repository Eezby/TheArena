local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local Signal
if IsServer then
	Signal = Instance.new("BindableEvent")
	Signal.Name = "Signal"
	Signal.Parent = script
else
	Signal = script:WaitForChild("Signal")
end


local EntityService
local EntityHandler

if IsServer then
	local SerServices = ServerScriptService.Services
	EntityService = require(SerServices.EntityService)
else
	local LocalPlayer = Players.LocalPlayer
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerServices = PlayerScripts:WaitForChild("Services")

	EntityHandler = require(PlayerServices:WaitForChild("EntityHandler"))
end

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local RepData = ReplicatedStorage:WaitForChild("Data")
local AbilityData = require(RepData:WaitForChild("AbilityData"))


local Abilities = {}
local AbilitiesFolder = ReplicatedStorage:WaitForChild("Abilities")
for _,ability in pairs(AbilitiesFolder:GetChildren()) do
	task.spawn(function()
		Abilities[ability.Name] = require(ability)
	end)
end

local AbilityFunctions = {}

function AbilityFunctions:RunAbilityFunction(ability, func, ...)
	local args = {...}

	for _,arg in pairs(args) do
		if typeof(arg) == "table" and arg.target then
			if not IsServer then
				arg.target = {
					entity = EntityHandler.GetEntityFromId(arg.target.entityId)
				}
			end
		end
	end

	local abilityScript = Abilities[ability]
	if abilityScript and abilityScript[func] then
		abilityScript[func](self, table.unpack(args))
	end
end

function AbilityFunctions:GetAbilityScript(ability)
	return Abilities[ability]
end

Signal.Event:Connect(function(func, ...)
	AbilityFunctions[func](self, ...)
end)
return AbilityFunctions