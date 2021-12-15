local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerValuesConnection

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

if IsServer then
    PlayerValuesConnection = Instance.new("RemoteEvent")
    PlayerValuesConnection.Name = "PlayerValuesConnection"
    PlayerValuesConnection.Parent = Remotes
elseif IsClient then
    PlayerValuesConnection = Remotes:WaitForChild("PlayerValuesConnection")
end

local StoredValues = {}
local StoredCallbacks = {}

local function checkCallbacks(player, property, value)
	if StoredCallbacks[property] then
		for _,callback in pairs(StoredCallbacks[property]) do
			task.spawn(callback, player, value)
		end
	end
end

local PlayerValues = {}

if IsClient then
	PlayerValuesConnection.OnClientEvent:Connect(function(player, property, value)
		if not StoredValues[player] then
			StoredValues[player] = {}
		end
		
		StoredValues[player][property] = value
		checkCallbacks(player, property, value)
	end)
end

function PlayerValues:SetValue(player, property, value, replicate)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end
	
	StoredValues[player][property] = value
	checkCallbacks(player, property, value)
	
	if replicate and IsServer then
		PlayerValuesConnection:FireAllClients(player, property, value)
	end
end

function PlayerValues:IncrementValue(player, property, value, replicate)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end

	StoredValues[player][property] = (StoredValues[player][property] or 0) + value
	checkCallbacks(player, property, StoredValues[player][property])
	
	if replicate and IsServer then
		PlayerValuesConnection:FireAllClients(player, property, StoredValues[player][property])
	end
end

function PlayerValues:GetValue(player, property)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end
	
	return StoredValues[player][property]
end

function PlayerValues:SetCallback(property, callback)
	if not StoredCallbacks[property] then
		StoredCallbacks[property] = {}
	end

	table.insert(StoredCallbacks[property], callback)
end

function PlayerValues:SyncProperty(syncPlayer, property)
	for player, values in pairs(StoredValues) do
		if player ~= syncPlayer then
			if values[property] then
				PlayerValuesConnection:FireClient(syncPlayer, player, property, values[property])
			end
		end
	end
end

return PlayerValues
