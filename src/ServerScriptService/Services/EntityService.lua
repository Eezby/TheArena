local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes

local SerServices = ServerScriptService.Services
local Utility = ReplicatedStorage.Utility
local PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))

local UPDATE_TIME_STEP = 0.1
local NextEntityId = 0

local EntityRemote = Instance.new("RemoteEvent")
EntityRemote.Name = "EntityRemote"
EntityRemote.Parent = Remotes

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
			if entity.Replicate and not entity.BoundObject then
				table.insert(entitiesToReplicate, entity:GetEfficientData())
			end
		end

		PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-update", entitiesToReplicate)
	end
end

--[[
	? = optional
	* = required
	
	PROPERTY		TYPE		EXAMPLE
	-------------------------------------------
	*Name 			[string]	"Dummy"
	?CFrame 		[CFrame]	CFrame.new(0,0,0)
	?WalkSpeed 		[number]	7
	?RunSpeed 		[number]	16
	?Health 		[number]	100
	?Replicate		[boolean]	true
	?BoundObject	[Instance]	player.Character
	?Visual			[Instance]	Storage.Zombie
    ?Player         [Instance]  Players.Eezby
--]]
function EntityService.new(info)
	local newEntity = {}
	setmetatable(newEntity, EntityService)

	newEntity.Id = getNextEntityId()
	
	for property, value in pairs(info) do
		newEntity[property] = value
	end
	
	if newEntity.Health then
		newEntity.MaxHealth = newEntity.Health
	end
	
	if info.Replicate == nil then
		newEntity.Replicate = true
	end

    newEntity.CFrame = newEntity.CFrame or CFrame.new(0,0,0)
	
	EntityService.ActiveEntities[newEntity.Id] = newEntity
	PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-create", newEntity)
	
	return newEntity
end

function EntityService.GetEntities()
	return EntityService.ActiveEntities
end

function EntityService.GetEntityFromId(id)
	return EntityService.ActiveEntities[id]
end

function EntityService.GetPlayerEntity(player, loopUntilFound)
	local foundEntity = nil

	while foundEntity == nil do
		for _,entity in pairs(EntityService.ActiveEntities) do
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
function EntityService:Death()
	self.Dead = true
	
	PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-death", self.Id)
	EntityService.ActiveEntities[self.Id] = nil
end

function EntityService:Damage(value)
	if self.Health then
		self.Health = math.clamp(self.Health - value, 0, self.MaxHealth)
		
		if self.Health == 0 then
			self:Death()
		end
	end
end

function EntityService:Heal(value)
	if self.Health then
		self.Health = math.clamp(self.Health + value, 0, self.MaxHealth)
	end
end

function EntityService:MoveTo(position)
	if self.BoundObject then
		local humanoid = self.BoundObject:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:MoveTo(position)
		end
	else
		self.CFrame += (position - self.CFrame.Position).Unit * (self.WalkSpeed or 0)
	end
end

function EntityService:StartFollow(object)

end

function EntityService:StopFollow()

end

function EntityService:SetBoundObject(object)
	self.BoundObject = object
end

function EntityService:SetReplicateStatus(status)
	self.Replicate = status
end

function EntityService:SetTarget(target)
    self.Target = target

    if target then
        PlayerRemoteService:FireAllClientsWithAction(EntityRemote, "entity-target", {
            entityId = target.Id
        })
    end
end

function EntityService:GetCFrame()
	if self.BoundObject then
		return self.BoundObject:GetPivot()
	end

	return self.CFrame
end

function EntityService:GetEfficientData()
	local _, orientation, _ = self.CFrame:ToOrientation()
	orientation = math.floor(orientation * 10 + 0.5)

	local efficientData = {
		Vector3int16.new(self.Id, orientation, math.floor((self.WalkSpeed or 0) * 10 + 0.5)),
		trimVector(self.CFrame.Position),
	}
	
	if self.Health then
		local healthPercentage = self.Health / self.MaxHealth
		healthPercentage = math.floor(healthPercentage * 1000 + 0.5)
		table.insert(efficientData, healthPercentage)
	end

	return efficientData
end

return EntityService
