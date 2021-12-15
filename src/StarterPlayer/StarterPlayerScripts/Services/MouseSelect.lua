local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local MouseSelect = {}

function MouseSelect:Whitelist(whitelist)
	local Camera = workspace.CurrentCamera

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = whitelist
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

	local raycastResult = workspace:Raycast(Camera.CFrame.Position, (Mouse.Hit.Position - Camera.CFrame.Position).Unit * 500, raycastParams)
	return raycastResult
end

function MouseSelect:Blacklist(blacklist)
	local Camera = workspace.CurrentCamera

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = blacklist
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = workspace:Raycast(Camera.CFrame.Position, (Mouse.Hit.Position - Camera.CFrame.Position).Unit * 500, raycastParams)
	return raycastResult
end

return MouseSelect