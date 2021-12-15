local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Database = ReplicatedStorage:WaitForChild("Database")

local IsServer = RunService:IsServer()

local WeaponTypes = {}
local WeaponsFolder = ReplicatedStorage:WaitForChild("WeaponTypes")
for _,weapon in pairs(WeaponsFolder:GetChildren()) do
    task.spawn(function()
        WeaponTypes[weapon.Name] = require(weapon)
    end)
end

local WeaponFunctions = {}

function WeaponFunctions:GetWeaponScripts(types)
	types = types or {}
	
	local typeScripts = {}

	for t,v in pairs(types) do
		table.insert(typeScripts, WeaponTypes[t])
	end

	return typeScripts
end

function WeaponFunctions:GetWeaponScript(t)
	return WeaponTypes[t]
end

return WeaponFunctions