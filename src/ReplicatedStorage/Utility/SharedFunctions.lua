local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local Utility = ReplicatedStorage:WaitForChild("Utility")
local TweenService = require(Utility:WaitForChild("TweenService"))

local TIME_OFFSET = math.floor((os.time() - tick()) / 100 + 0.5) * 100

local SharedFunctions = {}

function SharedFunctions:GetPositionMagnitude(position1, position2) -- TODO: Raycast Y values
	local modPosition1 = position1 * Vector3.new(1,0,1)
	local modPosition2 = position2 * Vector3.new(1,0,1)

	return (modPosition1 - modPosition2).Magnitude
end

function SharedFunctions:GetRandomMapPosition(optionalMap)
	local map = optionalMap or CollectionService:GetTagged("Map")[1]

	if map then
		local mapSize = map.MapParts:GetExtentsSize()
		local randomPosition

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = map.MapParts:GetDescendants()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		
		repeat
			randomPosition = map:GetPivot().Position + Vector3.new(math.random(-mapSize.X/2, mapSize.X/2), 500, math.random(-mapSize.Z/2, mapSize.Z/2))

			local raycastResult = workspace:Raycast(randomPosition, Vector3.new(0,-1,0) * 550, raycastParams)
			if raycastResult and raycastResult.Position then
				randomPosition = raycastResult.Position
			else
				randomPosition = nil
			end
		until randomPosition

		return randomPosition
	end

	return false
end

function SharedFunctions:ClearAllChildrenOfType(parent, objectType)
	for _,child in ipairs(parent:GetChildren()) do
		if child.ClassName == objectType then
			child:Destroy()
		end
	end
end

function SharedFunctions:GetTime()
	return workspace:GetServerTimeNow()
	--return tick() + TIME_OFFSET
end

function SharedFunctions:GetTimeDifference(startTime, marginLimit, marginOfError)
	return math.clamp(math.abs(self:GetTime() - startTime), 0, marginLimit * marginOfError)
end
return SharedFunctions
