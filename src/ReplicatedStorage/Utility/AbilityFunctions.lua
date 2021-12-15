local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local Signal
if IsServer then
	Signal = Instance.new("BindableEvent")
	Signal.Name = "Signal"
	Signal.Parent = script
else
	Signal = script:WaitForChild("Signal")
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
	local abilityScript = Abilities[ability]
	if abilityScript and abilityScript[func] then
		abilityScript[func](self, ...)
	end
end

function AbilityFunctions:GetAbilityScript(ability)
	return Abilities[ability]
end

Signal.Event:Connect(function(func, ...)
	AbilityFunctions[func](self, ...)
end)
return AbilityFunctions