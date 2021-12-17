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
	local whitelist = CollectionSelect:SelectAll({"Player", "NPC"})
	local result = MouseSelect:Whitelist(whitelist)
	
	if result then
		if result.Instance then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local targetType = nil
				
				if CollectionService:HasTag(model, "Player") then
					targetType = "Player"
				elseif CollectionService:HasTag(model, "NPC") then
					targetType = "NPC"
				end
				
				if targetType then
					TargetService.CurrentTarget = {
						targetType = targetType
					}

					if targetType == "Player" then
						TargetService.CurrentTarget.object = Players:GetPlayerFromCharacter(model)
					elseif targetType == "NPC" then
						TargetService.CurrentTarget.object = EntityHandler.GetEntityFromModel(model)
					end
					
					if TargetService.CurrentTarget.object then
						PlayerValues:SetValue(LocalPlayer, "Target", TargetService.CurrentTarget)
						TargetRemote:FireServer({
							targetType = TargetService.CurrentTarget.targetType,
							object = {id = TargetService.CurrentTarget.object.id}
						})
					else
						warn("Could not link model with entity")
					end
					
					return TargetService.CurrentTarget
				end
			end
		end
	end
	
	return nil
end

function TargetService:GetCurrentTarget()
	return TargetService.CurrentTarget
end

return TargetService
