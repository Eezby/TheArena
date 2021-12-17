local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage.Utility
local PlayerRemoteService = require(Utility.PlayerRemoteService)

local Remotes = ReplicatedStorage.Remotes

local EntityRemote = Instance.new("RemoteEvent")
EntityRemote.Name = "Entity"
EntityRemote.Parent = Remotes

local UPDATE_TIME_STEP = 0.1
local NextEntityId = 0

local function getNextEntityId()
    NextEntityId += 1
    return tostring(NextEntityId)
end

local function trimVector(vec)
	return Vector3int16.new(
		math.floor(vec.X*10+0.5),
		math.floor(vec.Y*10+0.5),
		math.floor(vec.Z*10+0.5))
end

local EntityService = {}
EntityService.__index = EntityService

EntityService.ActiveEntities = {}

function EntityService.init()
    while true do
        task.wait(UPDATE_TIME_STEP)

        local entitiesToReplicate = {}

        for _,entity in pairs(EntityService.ActiveEntities) do
            if entity.replicate then
                table.insert(entitiesToReplicate, entity:GetEfficientData())
            end
        end

        PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-update", entitiesToReplicate)
    end
end

function EntityService.new(info)
    local newEntity = {}
    setmetatable(newEntity, EntityService)

    newEntity.id = getNextEntityId()
    newEntity.name = info.name

    newEntity.cframe = CFrame.new(info.position)
    newEntity.speed = 5
    newEntity.health = 25
    newEntity.maxHealth = 25
    
    newEntity.behavior = info.behavior or "Passive"
    newEntity.replicate = true

    EntityService.ActiveEntities[tostring(newEntity.id)] = newEntity

    PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-create", newEntity)

    return newEntity
end

function EntityService.GetEntities()
    return EntityService.ActiveEntities
end

function EntityService.GetEntityFromId(id)
    return EntityService.ActiveEntities[id]
end

-------------------------------------------------------------------------
function EntityService:GetEfficientData()
    local _, orientation, _ = self.cframe:ToOrientation()
	orientation = math.floor(orientation * 10 + 0.5)

	local efficientData = {
		Vector3int16.new(self.id, orientation, math.floor(self.speed * 10 + 0.5)),
		trimVector(self.cframe.Position),
	}

    local healthPercentage = self.health / self.maxHealth
    healthPercentage = math.floor(healthPercentage * 1000 + 0.5)
    table.insert(efficientData, healthPercentage)

	return efficientData
end

function EntityService:SetBehavior(behavior)
    self.behavior = behavior
end

function EntityService:SetReplicateStatus(status)
    self.replicate = status
end

return EntityService