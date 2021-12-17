local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local EntityAssets = Assets:WaitForChild("Entities")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EntityRemote = Remotes:WaitForChild("Entity")

local EntityHandler = {}
EntityHandler.ActiveEntities = {}

EntityHandler.__index = EntityHandler

local function createNewEntity(entity)
    local newEntity = entity
    setmetatable(newEntity, EntityHandler)

    newEntity.visual = EntityAssets[entity.name]:Clone()
    newEntity.visual.Parent = workspace.Entities

    return newEntity
end

local function convertEntityInfo(entity)
    local convertedEntity = {
        id = tostring(entity[1].X),
        orientation = entity[1].Y/10,
        speed = entity[1].Z/10,
        position = entity[2], healthPercentage = entity[3]
    }

    convertedEntity.position = Vector3.new(entity[2].X/10, entity[2].Y/10, entity[2].Z/10)
    convertedEntity.healthPercentage /= 1000

    return convertedEntity
end

function EntityHandler.GetEntityFromModel(model)
    for _,entity in pairs(EntityHandler.ActiveEntities) do
        if entity.visual == model then
            return entity
        end
    end

    return false
end

function EntityHandler.GetEntityFromId(id)
   return EntityHandler.ActiveEntities[id]
end

-------------------------------------------------------------------------

function EntityHandler:Update(entityInfo)
    local serverCFrame = CFrame.new(entityInfo.position) * CFrame.Angles(0,entityInfo.orientation,0)
    self.visual:PivotTo(serverCFrame)
end

-------------------------------------------------------------------------

EntityRemote.OnClientEvent:Connect(function(action, args)
    local action = PlayerRemoteService:GetActionFromId(action)

    if action == "entity-create" then
        local convertedEntity = args
        EntityHandler.ActiveEntities[convertedEntity.id] = createNewEntity(convertedEntity)
    end

    if action == "entity-update" then
        for _,entity in ipairs(args) do
            local convertedEntity = convertEntityInfo(entity)
            local storedEntity = EntityHandler.ActiveEntities[convertedEntity.id]

            if storedEntity then
                storedEntity:Update(convertedEntity)
            end
        end
    end
end)
return EntityHandler