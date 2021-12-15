local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Helpers = ReplicatedStorage.Helpers
local ErrorCodeHelper = require(Helpers.ErrorCodeHelper)

local SerServices = ServerScriptService.Services
local DataStorage = SerServices.DataStorage
	local ProfileService = require(DataStorage.ProfileService)
	local ProfileTemplate = require(DataStorage.ProfileTemplate)

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)

local DataHandler = {}
DataHandler.Profiles = {}

function DataHandler:Initialize(player)
	local profile = ProfileStore:LoadProfileAsync("Player_"..player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			self.Profiles[player] = nil
			player:Kick(ErrorCodeHelper.FormatCode("0001"))
		end)
		
		if player:IsDescendantOf(Players) then
			self.Profiles[player] = profile
		else
			-- player left before data was loaded
			profile:Release()
		end
	else
		player:Kick(ErrorCodeHelper.FormatCode("0002"))
	end
	
	return profile
end

function DataHandler:GetProfile(player)
	return self.Profiles[player]
end

return DataHandler
