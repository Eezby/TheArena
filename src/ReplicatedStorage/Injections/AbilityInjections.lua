local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RepData = ReplicatedStorage:WaitForChild("Data")
local RepServices = ReplicatedStorage:WaitForChild("Services")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local RepAssets = ReplicatedStorage:WaitForChild("Assets")
local Helpers = ReplicatedStorage:WaitForChild("Helpers")

local IsServer = RunService:IsServer()

local AbilityInjections = {}

AbilityInjections.AbilityData = require(RepData:WaitForChild("AbilityData"))
AbilityInjections.AnimationData = require(RepData:WaitForChild("AnimationData"))
AbilityInjections.AbilityAssets = RepAssets:WaitForChild("Ability")
AbilityInjections.AbilityHelper = require(Helpers:WaitForChild("AbilityHelper"))
AbilityInjections.TargetHelper = require(Helpers:WaitForChild("TargetHelper"))

AbilityInjections.DefaultAnimations = require(RepData:WaitForChild("DefaultAnimations"))
AbilityInjections.GameSignals = require(Utility:WaitForChild("GameSignals"))
AbilityInjections.TweenService = require(Utility:WaitForChild("TweenService"))

AbilityInjections.PlayerValues = require(RepServices:WaitForChild("PlayerValues"))
AbilityInjections.PlayerCooldowns = require(RepServices:WaitForChild("PlayerCooldowns"))
AbilityInjections.ProjectileService = require(RepServices:WaitForChild("ProjectileService"))
AbilityInjections.PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))

AbilityInjections.SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
AbilityInjections.StatFunctions = require(Utility:WaitForChild("StatFunctions"))

if IsServer then
	local SerServices = ServerScriptService.Services
	AbilityInjections.DamageService = require(SerServices.DamageService)
	AbilityInjections.EffectService = require(SerServices.EffectService)
else
	local LocalPlayer = Players.LocalPlayer
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerServices = PlayerScripts:WaitForChild("Services")
	AbilityInjections.PlacementTarget = require(PlayerServices:WaitForChild("PlacementTarget"))
	AbilityInjections.AbilityService = require(PlayerServices:WaitForChild("AbilityService"))
end

return AbilityInjections
