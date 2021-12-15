local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local RepData = ReplicatedStorage:WaitForChild("Data")
local AbilityData = require(RepData:WaitForChild("AbilityData"))

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local TweenService = require(Utility:WaitForChild("TweenService"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Targets = PlayerGui:WaitForChild("Targets")
local MainProfile = Targets:WaitForChild("MainProfile")
local TargetProfile = Targets:WaitForChild("TargetProfile")

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerUiModules = PlayerScripts:WaitForChild("Ui")
local CastbarUi = require(PlayerUiModules:WaitForChild("CastbarUi"))

local function getTargetInfo(target)
	local info = {}
	info.model = target.model
	info.targetType = target.targetType
	info.name = info.model.Name
	
	if target.targetType == "Player" then
		info.player = Players:GetPlayerFromCharacter(info.model)
		
		info.health = PlayerValues:GetValue(info.player, "Health") or 1
		info.maxHealth = PlayerValues:GetValue(info.player, "MaxHealth") or 1
		info.power = PlayerValues:GetValue(info.player, "Power") or 1
		info.maxPower = PlayerValues:GetValue(info.player, "MaxPower") or 1
		info.castInfo = PlayerValues:GetValue(info.player, "CastInfo")
		info.target = PlayerValues:GetValue(info.player, "Target")
		info.class = PlayerValues:GetValue(info.player, "Class") or "???"
	elseif target.targetType == "NPC" then
		info.health = 25
		info.maxHealth = 25
		info.power = 25
		info.maxPower = 25
		info.castInfo = nil
		info.target = nil
		info.class = "NPC"
	end
	
	return info
end

local function getSelfInfo()
	local info = {}
	info.model = LocalPlayer.Character
	info.name = LocalPlayer.Name
	info.player = LocalPlayer
	info.health = PlayerValues:GetValue(LocalPlayer, "Health") or 1
	info.maxHealth = PlayerValues:GetValue(LocalPlayer, "MaxHealth") or 1
	info.power = PlayerValues:GetValue(LocalPlayer, "Power") or 1
	info.maxPower = PlayerValues:GetValue(LocalPlayer, "MaxPower") or 1
	info.class = PlayerValues:GetValue(LocalPlayer, "Class") or "???"
	
	return info
end

local function updateHealthbar(profile, health, maxHealth)
	health = math.clamp(health, 0, maxHealth)
	
	profile.HealthFrame.HealthLabel.Text = health.." / "..maxHealth
	profile.HealthFrame.Bar.Size = UDim2.new(health / maxHealth, 0, 1, 0)
end

local function updatePowerbar(profile, power, maxPower)
	power = math.clamp(power, 0, maxPower)
	
	profile.PowerFrame.PowerLabel.Text = power.." / "..maxPower
	profile.PowerFrame.Bar.Size = UDim2.new(power / maxPower, 0, 1, 0)
end

local function updateInfo(profile, name, class)
	profile.InfoFrame.PlayerName.Text = name
	profile.InfoFrame.PlayerClass.Text = class
end

local function tweenTargetCastbar(targetInfo)
	local castFrame = TargetProfile.CastFrame
	local abilityInfo = AbilityData[targetInfo.castInfo.ability]
	if abilityInfo then
		local tween, heartbeatConnection = CastbarUi:SimulateCast(castFrame, targetInfo.castInfo.ability, abilityInfo.castTime, targetInfo.castInfo.startTime)
		return tween, heartbeatConnection
	end
end

local TargetsUi = {}
TargetsUi.CurrentCastId = nil
TargetsUi.CurrentCastTween = nil
TargetsUi.CurrentHeartbeatConnection = nil

local function stopCasting()
	if TargetsUi.CurrentCastTween then
		TargetsUi.CurrentCastTween:Cancel()
	end

	if TargetsUi.CurrentHeartbeatConnection then
		TargetsUi.CurrentHeartbeatConnection:Disconnect()
	end
end

function TargetsUi:UpdateMainProfile()
	local selfInfo = getSelfInfo()
	
	updateInfo(MainProfile, selfInfo.name, selfInfo.class)
	updateHealthbar(MainProfile, selfInfo.health, selfInfo.maxHealth)
	updatePowerbar(MainProfile, selfInfo.power, selfInfo.maxPower)
end

function TargetsUi:UpdateTargetProfile(target)
	if target then
		TargetProfile.Visible = true
		
		local targetInfo = getTargetInfo(target)
		updateInfo(TargetProfile, targetInfo.name, targetInfo.class)
		updateHealthbar(TargetProfile, targetInfo.health, targetInfo.maxHealth)
		updatePowerbar(TargetProfile, targetInfo.power, targetInfo.maxPower)
		
		if targetInfo.castInfo then
			TargetProfile.CastFrame.Visible = true
			
			local castId = targetInfo.name..targetInfo.castInfo.ability..targetInfo.castInfo.castIdentifier
			if TargetsUi.CurrentCastId ~= castId then
				TargetsUi.CurrentCastId = castId
				
				stopCasting()
				
				TargetsUi.CurrentCastTween, TargetsUi.CurrentHeartbeatConnection = tweenTargetCastbar(targetInfo)
			end
		else
			TargetProfile.CastFrame.Visible = false
			TargetsUi.CurrentCastId = nil
			
			stopCasting()
		end
	else
		TargetProfile.Visible = false
	end
end

return TargetsUi
