local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerServices = PlayerScripts:WaitForChild("Services")
local MouseSelect = require(PlayerServices:WaitForChild("MouseSelect"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local CollectionSelect = require(Utility:WaitForChild("CollectionSelect"))

local Assets = ReplicatedStorage:WaitForChild("Assets")
local MiscAssets = Assets:WaitForChild("Misc")
local TargetPart = MiscAssets:WaitForChild("TargetPart")

local Mouse = LocalPlayer:GetMouse()

local StatusMap = {
	[0] = false,
	[1] = true,
	[2] = false
}

local PlacementTarget = {}
PlacementTarget.ClickConnection = nil
PlacementTarget.MoveConnection = nil
PlacementTarget.Status = nil
PlacementTarget.ActivePlacements = {}

function PlacementTarget:Start(fromObject, castIdentifier, range, area)
	self:Stop(castIdentifier)
	
	self.Status = 0
	
	local newPart = TargetPart:Clone()
	newPart.Size = Vector3.new(area*2, 0.001, area*2)
	
	local initialMouseResult = MouseSelect:Whitelist(CollectionSelect:SelectAll({"Map"}))
	if initialMouseResult and initialMouseResult.Position then
		newPart.CFrame = CFrame.new(initialMouseResult.Position)
	else
		newPart.Position = fromObject:GetPivot().Position
	end
	
	newPart.Parent = workspace.Dynamic
	
	self.ActivePlacements[castIdentifier] = {
		object = newPart
	}
	
	self.MoveConnection = Mouse.Move:Connect(function()
		local mouseResult = MouseSelect:Whitelist(CollectionSelect:SelectAll({"Map"}))
		if mouseResult and mouseResult.Position then
			newPart.CFrame = CFrame.new(mouseResult.Position)
			
			if (mouseResult.Position - fromObject:GetPivot().Position).Magnitude <= range then
				newPart.Symbol.Color3 = Color3.fromRGB(60, 255, 60)
			else
				newPart.Symbol.Color3 = Color3.fromRGB(255, 58, 58)
			end
		end
	end)
	
	self.ClickConnection = UserInputService.InputEnded:Connect(function(input, override)
		if not override then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if (newPart.Position - fromObject:GetPivot().Position).Magnitude <= range then
					self.ClickConnection:Disconnect()
					self.MoveConnection:Disconnect()
					self.Status = 1
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				self.ClickConnection:Disconnect()
				self.MoveConnection:Disconnect()
				self:Stop(castIdentifier)
			end
		end
	end)
	
	repeat
		task.wait()
	until self.Status ~= 0 or not self.ActivePlacements[castIdentifier]
	
	local currentStatus = self.Status
	self.Status = 0
	
	local finalMousePosition = newPart.Position
	
	self:Stop(castIdentifier)
	
	
	return StatusMap[currentStatus], finalMousePosition
end

function PlacementTarget:Stop(castIdentifier)
	if self.ClickConnection then
		self.ClickConnection:Disconnect()
	end
	
	if self.MoveConnection then
		self.MoveConnection:Disconnect()
	end
	
	for _,info in pairs(self.ActivePlacements) do
		if info.object then
			info.object:Destroy()
		end
	end
	
	self.ActivePlacements[castIdentifier] = {}
end

return PlacementTarget
