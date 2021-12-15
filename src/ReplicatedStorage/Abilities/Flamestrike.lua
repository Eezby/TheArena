local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Injections = ReplicatedStorage:WaitForChild("Injections")
local AbInject = require(Injections:WaitForChild("AbilityInjections"))

local SelfAssets = AbInject.AbilityAssets:WaitForChild(script.Name)

local IsServer = RunService:IsServer()

local Signal = nil

if IsServer then
	Signal = Instance.new("RemoteEvent")
	Signal.Name = "Signal"
	Signal.Parent = script
else
	Signal = script:WaitForChild("Signal")
end

local SelfAbilityData = AbInject.AbilityData[script.Name]

local CastAnimationId = AbInject.DefaultAnimations.CastLoop
local FireAnimationid = AbInject.DefaultAnimations.CastFire

local SelfAnimations = {}
SelfAnimations.CastLoop = Instance.new("Animation")
SelfAnimations.CastLoop.AnimationId = "rbxassetid://"..CastAnimationId

SelfAnimations.CastFire = Instance.new("Animation")
SelfAnimations.CastFire.AnimationId = "rbxassetid://"..FireAnimationid


local Ability = {}
Ability.ActiveTracks = {}

function Ability:StartPlacement(player, castIdentifier, startTime)
	local character = player.Character
	
	local timeDifference = AbInject.SharedFunctions:GetTimeDifference(startTime, SelfAbilityData.castTime, 1)
	local placementStatus, placementPosition = AbInject.PlacementTarget:Start(character, castIdentifier, SelfAbilityData.range, SelfAbilityData.area)
	if placementStatus then
		AbInject.AbilityService:NormalAbility(castIdentifier, SelfAbilityData.name, {placementPosition = placementPosition})
	end
end

function Ability:ClientAbility(player, castIdentifier, args, startTime)
	local character = player.Character

	if not Ability.ActiveTracks[player] then
		Ability.ActiveTracks[player] = {}
	end

	local timeDifference = AbInject.SharedFunctions:GetTimeDifference(startTime, SelfAbilityData.castTime, 1)
	
	Ability:StartCast(player, castIdentifier, args.target, startTime)
	task.wait(SelfAbilityData.castTime - timeDifference)
	Ability:Fire(player, castIdentifier, args.placementPosition)
end

function Ability:ServerAbility(player, castIdentifier, args, startTime)
	AbInject.PlayerRemoteService:FireAllClientsExclude(Signal, player, "ability", player, castIdentifier, args, startTime)

	AbInject.PlayerValues:SetValue(player, "CastInfo", {
		ability = SelfAbilityData.name,
		castIdentifier = castIdentifier,
		startTime = startTime
	})

	local character = player.Character
	local playerHaste = AbInject.PlayerValues:GetValue(player, "Haste")

	local timeDifference = AbInject.SharedFunctions:GetTimeDifference(startTime, SelfAbilityData.castTime, 1)
	
	local playerCastInfo = AbInject.PlayerValues:GetValue(player, "CastInfo")
	if playerCastInfo and playerCastInfo.castIdentifier == castIdentifier then
		task.wait(SelfAbilityData.castTime - timeDifference)

		local targets = AbInject.TargetHelper:GetNearbyTargets(player.Character, args.placementPosition, "enemy", {
			range = SelfAbilityData.area
		})
		
		AbInject.DamageService:DoDamage(targets, {
			ability = SelfAbilityData.name,
			damageType = "direct",
			splitDamage = true,
			fromPlayer = player
		})
	end
end

function Ability:StartCast(player, castIdentifier, currentTarget, startTime)
	AbInject.AbilityHelper:StartCast(
		player, 
		Ability.ActiveTracks, 
		SelfAnimations, 
		SelfAbilityData, 
		castIdentifier, 
		startTime
	)
end

function Ability:StopCast(player, castIdentifier)
	if IsServer then
		AbInject.PlayerRemoteService:FireAllClientsExclude(Signal, player, "stop", player, castIdentifier)
	end

	AbInject.AbilityHelper:StopCast(
		player,
		Ability.ActiveTracks,
		castIdentifier
	)
end

function Ability:Fire(player, castIdentifier, placementPosition)
	local playerCastInfo = AbInject.PlayerValues:GetValue(player, "CastInfo")
	local character = player.Character

	if playerCastInfo and playerCastInfo.castIdentifier == castIdentifier then
		local playerHaste = AbInject.PlayerValues:GetValue(player, "Haste")
		local animationHasteAdjustment = math.pow(AbInject.StatFunctions:AdjustForHaste(1, playerHaste), -1) * 0.75
		
		AbInject.GameSignals:Fire("AbilityUsed", "cooldown", {player = player, ability = SelfAbilityData.name, duration = SelfAbilityData.cooldown})
		local trackLength = AbInject.AnimationData:GetAnimationTrackLength(FireAnimationid)
		
		Ability:StopCast(player, castIdentifier)
		
		local fireTrack = player.Character.Humanoid:LoadAnimation(SelfAnimations.CastFire)
		Ability.ActiveTracks[player]["fire"] = fireTrack
		
		fireTrack:Play(0.1, 1, animationHasteAdjustment)
	end
end

if not IsServer then
	Signal.OnClientEvent:Connect(function(action, ...)
		if action == "ability" then
			Ability:ClientAbility(...)
		elseif action == "stop" then
			Ability:StopCast(...)
		end
	end)
end


return Ability
