local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local IsServer = RunService:IsServer()

local PlayerStatusService = {}
PlayerStatusService.Players = {}

function PlayerStatusService:AddPlayer(player)
	table.insert(PlayerStatusService.Players, {
		player = player,
		lastPosition = Vector3.new(0,-500,0)
	})
end

task.spawn(function()
	local increment = 0.05
	while true do
		for _,info in pairs(PlayerStatusService.Players) do
			if info.player and info.player.Character then
				local character = info.player.Character
				local currentPosition = character:GetPivot().Position

				if (currentPosition - info.lastPosition).Magnitude > increment then
					PlayerValues:SetValue(info.player, "IsMoving", true)
				else
					PlayerValues:SetValue(info.player, "IsMoving", false)
				end

				info.lastPosition = currentPosition
			end
		end
		
		task.wait(increment)
	end
end)
return PlayerStatusService
