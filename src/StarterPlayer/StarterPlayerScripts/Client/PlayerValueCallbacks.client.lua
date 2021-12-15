local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerUiModules = PlayerScripts:WaitForChild("Ui")
local HotbarUi = require(PlayerUiModules:WaitForChild("HotbarUi"))
local TargetUi = require(PlayerUiModules:WaitForChild("TargetUi"))

local PlayerServices = PlayerScripts:WaitForChild("Services")
local TargetService = require(PlayerServices:WaitForChild("TargetService"))

local function classChanged(player, currentClass)
	if player == LocalPlayer then
		HotbarUi:SetKeybinds(currentClass)
	end
end
PlayerValues:SetCallback("Class", classChanged)

local function targetValueChanged(player, value)
	local currentLocalTarget = TargetService:GetCurrentTarget()
	if currentLocalTarget then
		if currentLocalTarget.model == player.Character then
			TargetUi:UpdateTargetProfile(currentLocalTarget)
		end
	end
	
	if player == LocalPlayer then
		TargetUi:UpdateMainProfile()
	end
end

PlayerValues:SetCallback("Health", targetValueChanged)
PlayerValues:SetCallback("MaxHealth", targetValueChanged)
PlayerValues:SetCallback("Power", targetValueChanged)
PlayerValues:SetCallback("MaxPower", targetValueChanged)
PlayerValues:SetCallback("CastInfo", targetValueChanged)
PlayerValues:SetCallback("Target", targetValueChanged)
