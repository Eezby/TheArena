local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local TweenService = require(Utility:WaitForChild("TweenService"))
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local GameSignals = require(Utility:WaitForChild("GameSignals"))

local AbilityUsedSignal = GameSignals:Get("AbilityUsed")
local ChargeSignal = GameSignals:Get("Charge")

local LocalPlayer, PlayerUi

local IsClient = RunService:IsClient()

if IsClient then
    LocalPlayer = Players.LocalPlayer
    PlayerUi = LocalPlayer:WaitForChild("PlayerGui")
end

local AnimationIdentifier = 0

local PlayerCooldowns = {}
PlayerCooldowns.Cooldowns = {}
PlayerCooldowns.Charges = {}

function PlayerCooldowns:Cooldown(player, cooldown, duration)
	AnimationIdentifier += 1
	
	local currentIdentifier = AnimationIdentifier
	
    if not PlayerCooldowns.Cooldowns[player] then
        PlayerCooldowns.Cooldowns[player] = {}
    end

	PlayerCooldowns.Cooldowns[player][cooldown] = {
		ready = true,
		start = SharedFunctions:GetTime(),
		duration = duration,
		id = AnimationIdentifier,
	}

	PlayerCooldowns.Cooldowns[player][cooldown].ready = false
	
	task.wait(duration)
	
	if PlayerCooldowns.Cooldowns[player][cooldown] and PlayerCooldowns.Cooldowns[player][cooldown].id == currentIdentifier then
		PlayerCooldowns.Cooldowns[player][cooldown].ready = true
	end
end

function PlayerCooldowns:UseCharge(player, cooldown, duration, maxCharge)
	if not PlayerCooldowns.Charges[player] then
		PlayerCooldowns.Charges[player] = {}
	end
	
	if not PlayerCooldowns.Charges[player][cooldown] then
		PlayerCooldowns.Charges[player][cooldown] = maxCharge
	end
	
	PlayerCooldowns.Charges[player][cooldown] = math.clamp(PlayerCooldowns.Charges[player][cooldown]-1, 0, maxCharge)
	
	ChargeSignal:Fire({
		player = player, 
		ability = cooldown, 
		duration = duration, 
		charges = PlayerCooldowns.Charges[player][cooldown]
	})
	
	task.wait(duration)
	
	PlayerCooldowns.Charges[player][cooldown] = math.clamp(PlayerCooldowns.Charges[player][cooldown]+1, 0, maxCharge)
	
	ChargeSignal:Fire({
		player = player, 
		ability = cooldown, 
		duration = duration, 
		charges = PlayerCooldowns.Charges[player][cooldown]
	})
end

function PlayerCooldowns:GetChargesLeft(player, cooldown)
	if not PlayerCooldowns.Charges[player] then
		PlayerCooldowns.Charges[player] = {}
	end

	return PlayerCooldowns.Charges[player][cooldown] or 0
end

function PlayerCooldowns:HasCharge(player, cooldown)
	if not PlayerCooldowns.Charges[player] then
		PlayerCooldowns.Charges[player] = {}
	end

	return PlayerCooldowns.Charges[player][cooldown] == nil or PlayerCooldowns.Charges[player][cooldown] > 0
end

function PlayerCooldowns:IsReady(player, cooldown)
    return not PlayerCooldowns.Cooldowns[player] or not PlayerCooldowns.Cooldowns[player][cooldown] or (PlayerCooldowns.Cooldowns[player][cooldown] and PlayerCooldowns.Cooldowns[player][cooldown].ready) -- if cooldown doesnt exist or it does and its ready
end

function PlayerCooldowns:GetRemainingTime(player, cooldown)
	if PlayerCooldowns.Cooldowns[player] then
		if PlayerCooldowns.Cooldowns[player][cooldown] then
			return math.clamp(
				PlayerCooldowns.Cooldowns[player][cooldown].duration
				- (SharedFunctions:GetTime() - PlayerCooldowns.Cooldowns[player][cooldown].start), 
				0, 
				PlayerCooldowns.Cooldowns[player][cooldown].duration
			)
		end
	end
	return 0
end

AbilityUsedSignal.Event:Connect(function(action, args)
	if action == "cooldown" then
		PlayerCooldowns:Cooldown(args.player, args.ability, args.duration)
	elseif action == "use-charge" then
		PlayerCooldowns:UseCharge(args.player, args.ability, args.duration, args.maxCharge)
	end
end)
return PlayerCooldowns