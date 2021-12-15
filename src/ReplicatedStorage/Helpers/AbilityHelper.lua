local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerValues = require(RepServices:WaitForChild("PlayerValues"))

local IsServer = RunService:IsServer()

local AbilityHelper = {}

function AbilityHelper:StartCast(player, tracks, animations, abilityData, castIdentifier, startTime, args)
	local castInfo = {
		ability = abilityData.name,
		castIdentifier = castIdentifier,
		startTime = startTime,
	}

	if args then
		for index, value in pairs(args) do
			castInfo[index] = value
		end
	end

	PlayerValues:SetValue(player, "CastInfo", castInfo)

	local loopTrack = player.Character.Humanoid:LoadAnimation(animations.CastLoop)
	tracks[player]["cast"] = loopTrack

	loopTrack:Play()
end

function AbilityHelper:StopCast(player, tracks, castIdentifier)
	local currentPlayerCast = PlayerValues:GetValue(player, "CastInfo")
	if currentPlayerCast and currentPlayerCast.castIdentifier == castIdentifier then
		PlayerValues:SetValue(player, "CastInfo", nil)
	end

	if tracks[player] then
		if tracks[player]["cast"] then
			tracks[player]["cast"]:Stop()
			tracks[player]["cast"] = nil
		end
	end
end

function AbilityHelper:StopCastAnimations(tracks, player)
	if not tracks[player] then
		tracks[player] = {}
	end

	if tracks[player]["cast"] then
		tracks[player]["cast"]:Stop()
	end

	if tracks[player]["fire"] then
		tracks[player]["fire"]:Stop()
	end
	
	return tracks
end

function AbilityHelper:DestroyProjectile(projectile, waitTime)
	for _,object in ipairs(projectile:GetDescendants()) do
		if object:IsA("ParticleEmitter") then
			object.Enabled = false
		elseif object:IsA("BasePart") or object:IsA("Decal") then
			object.Transparency = 1
		end
	end
	
	if projectile:IsA("BasePart") then
		projectile.Transparency = 1
	end
	
	game.Debris:AddItem(projectile, waitTime or 2)
end

return AbilityHelper