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

	local timeDifference = AbInject.SharedFunctions:GetTimeDifference(startTime, SelfAbilityData.projectileSpeed, 1)

	task.wait(SelfAbilityData.castTime - timeDifference)

	local debugProjectile = Instance.new("Part")
	debugProjectile.Size = Vector3.new(1,1,1)
	debugProjectile.Transparency = 0.5
	debugProjectile.Shape = "Ball"
	debugProjectile.CanCollide = false
	debugProjectile.Anchored = true
	debugProjectile.Parent = workspace


	local projectileValues = AbInject.ProjectileService:FireAtTarget(args.placementPosition, {
		startCFrame = CFrame.new(args.placementPosition) + Vector3.new(0,10,0),
		projectile = debugProjectile,
		projectileSpeed = SelfAbilityData.projectileSpeed
	})

	projectileValues.Finished.Event:Wait()

	debugProjectile:Destroy()
	
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

function Ability:Fire(player, castIdentifier, placementPosition)
	local character = player.Character
	
	local playerHaste = AbInject.PlayerValues:GetValue(player, "Haste")
	local animationHasteAdjustment = math.pow(AbInject.StatFunctions:AdjustForHaste(1, playerHaste), -1) * 0.75
	
	AbInject.GameSignals:Fire("AbilityUsed", "cooldown", {player = player, ability = SelfAbilityData.name, duration = SelfAbilityData.cooldown})
	local trackLength = AbInject.AnimationData:GetAnimationTrackLength(FireAnimationid)
	
	local fireTrack = player.Character.Humanoid:LoadAnimation(SelfAnimations.CastFire)
	Ability.ActiveTracks[player]["fire"] = fireTrack
	
	fireTrack:Play(0.1, 1, animationHasteAdjustment)
	
	local meteorProjectile = SelfAssets.Meteor:Clone()
	meteorProjectile.Parent = workspace.Dynamic
	
	local projectileValues = AbInject.ProjectileService:FireAtTarget(placementPosition, {
		startCFrame = CFrame.new(placementPosition) + Vector3.new(0,10,0),
		projectile = meteorProjectile,
		projectileSpeed = SelfAbilityData.projectileSpeed
	})
	
	projectileValues.Finished.Event:Wait()
	
	meteorProjectile:Destroy()
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
