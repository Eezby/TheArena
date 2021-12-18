local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EntityRemote = Remotes:WaitForChild("EntityRemote")

local EntityHandler = {}
EntityHandler.__index = EntityHandler

EntityHandler.ActiveEntities = {}

local function convertEntityInfo(entity)
	local convertedEntity = {
		Id = tostring(entity[1].X),
		Orientation = entity[1].Y/10,
		Speed = entity[1].Z/10,
		Position = entity[2], 
		HealthPercentage = entity[3]
	}

	convertedEntity.Position = Vector3.new(entity[2].X/10, entity[2].Y/10, entity[2].Z/10)
	
	if convertedEntity.HealthPercentage then
		convertedEntity.HealthPercentage /= 1000
	end

	return convertedEntity
end

function EntityHandler.new(entity)
	local newEntity = entity
	setmetatable(newEntity, EntityHandler)

	if entity.Visual then
		newEntity.Visual = entity.Visual:Clone()
		newEntity.Visual.Parent = workspace
		newEntity.Visual:PivotTo(newEntity.CFrame)

		CollectionService:AddTag(newEntity.Visual, "Entity")
	end

	return newEntity
end

function EntityHandler.GetEntityFromModel(model)
	for _,entity in pairs(EntityHandler.ActiveEntities) do
		if entity.Visual == model or entity.BoundObject == model then
			return entity
		end
	end

	return false
end

function EntityHandler.GetEntityFromId(id)
	return EntityHandler.ActiveEntities[id]
end

function EntityHandler.GetPlayerEntity(player, loopUntilFound)
	local foundEntity = nil

	while foundEntity == nil do
		for _,entity in pairs(EntityHandler.ActiveEntities) do
			if entity.Player == player then
				foundEntity = entity
				break
			end
		end

		if not loopUntilFound then break end
	end

	return foundEntity
end

-------------------------------------------------------------------------

function EntityHandler:Update(entityInfo)
	local serverCFrame = CFrame.new(entityInfo.Position) * CFrame.Angles(0,entityInfo.Orientation,0)
	self.Visual:PivotTo(serverCFrame)
end

function EntityHandler:SetTarget(target)
	self.Target = target
end

function EntityHandler:GetModel()
	return self.Visual or self.BoundObject
end

function EntityHandler:GetCFrame()
	if self.BoundObject then
		return self.BoundObject:GetPivot()
	end

	return self.CFrame
end
-------------------------------------------------------------------------

EntityRemote.OnClientEvent:Connect(function(action, args)
	local action = PlayerRemoteService:GetActionFromId(action)

	if action == "entity-create" then
		local convertedEntity = args
		EntityHandler.ActiveEntities[convertedEntity.Id] = EntityHandler.new(convertedEntity)
	end

	if action == "entity-update" then
		for _,entity in ipairs(args) do
			local convertedEntity = convertEntityInfo(entity)
			local storedEntity = EntityHandler.ActiveEntities[convertedEntity.Id]

			if storedEntity then
				storedEntity:Update(convertedEntity)
			end
		end
	end
end)
return EntityHandler