local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RepData = ReplicatedStorage.Data
local ErrorCodes = require(RepData.ErrorCodes)

local Helpers = ReplicatedStorage.Helpers
local ErrorCodeHelper = require(Helpers.ErrorCodeHelper)

local SerServices = ServerScriptService.Services
local DataHandler = require(SerServices.DataHandler)
local ClientService = require(SerServices.ClientService)

local PlayerProfiles = {}

local function loadPlayerProfile(player, profile)
	ClientService.InitializeClient(player, profile)
end

local function characterAdded(newCharacter)
	newCharacter.ChildAdded:Connect(function()
		CollectionService:AddTag(newCharacter, "Player")
	end)
	
	CollectionService:AddTag(newCharacter, "Player")
end

local function playerAdded(newPlayer)
	task.spawn(function()
		print(newPlayer.Character or newPlayer.CharacterAdded:Wait())
		characterAdded(newPlayer.Character or newPlayer.CharacterAdded:Wait())
	end)
	
	newPlayer.CharacterAdded:Connect(characterAdded)
	
	local profile = DataHandler:Initialize(newPlayer)
	if profile ~= nil then
		loadPlayerProfile(newPlayer, profile)
	end
end

local function playerRemoved(player)
	local profile = PlayerProfiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoved)

for _,player in ipairs(Players:GetPlayers()) do
	task.spawn(playerAdded, player)
end