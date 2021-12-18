local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local CollectionSelect = require(Utility:WaitForChild("CollectionSelect"))

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerServices = PlayerScripts:WaitForChild("Services")
local MouseSelect = require(PlayerServices:WaitForChild("MouseSelect"))
local EntityHandler = require(PlayerServices:WaitForChild("EntityHandler"))

local PlayerUiModules = PlayerScripts:WaitForChild("Ui")
local TargetUi = require(PlayerUiModules:WaitForChild("TargetUi"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TargetRemote = Remotes:WaitForChild("Target")

local PlayerEntity = EntityHandler.GetPlayerEntity(LocalPlayer, true)

local TargetService = {}
TargetService.CurrentTarget = nil

function TargetService:Init()
	UserInputService.InputEnded:Connect(function(input, override)
		if not override then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				TargetService:FindTarget()
				TargetUi:UpdateTargetProfile(TargetService.CurrentTarget)
			end
		end
	end)
end

function TargetService:FindTarget()
	local whitelist = CollectionSelect:SelectAll({"Entity"})
	local result = MouseSelect:Whitelist(whitelist)
	
	if result then
		if result.Instance then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local entity = EntityHandler.GetEntityFromModel(model)
				if entity then
					TargetService.CurrentTarget = {
						entity = entity
					}

					PlayerEntity:SetTarget(TargetService.CurrentTarget)
					TargetRemote:FireServer({
						entityId = TargetService.CurrentTarget.entity.Id
					})
				else
					warn("Could not link model with entity")
				end

				return TargetService.CurrentTarget
			end
		end
	end
	
	return nil
end

function TargetService:GetCurrentTarget()
	return TargetService.CurrentTarget
end

return TargetService
