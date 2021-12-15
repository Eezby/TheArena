local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local RepServices = ReplicatedStorage.Services
local PlayerValues = require(RepServices.PlayerValues)

local SerServices = ServerScriptService.Services
local RagdollService = require(SerServices.RagdollService)

local function healthChanged(player, health)
	if health <= 0 then
		RagdollService.SetRagdoll(player.Character, true)
		task.wait(4)
		PlayerValues:SetValue(player, "Health", 125, true)
		RagdollService.SetRagdoll(player.Character, false)
	end
end


PlayerValues:SetCallback("Health", healthChanged)
