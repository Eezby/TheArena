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

function Ability:ClientAbility(player, castIdentifier, args, startTime)
	local character = player.Character
	
	local timeDifference = AbInject.SharedFunctions:GetTimeDifference(startTime, SelfAbilityData.castTime, 1)
	
	Ability.ActiveTracks = AbInject.AbilityHelper:StopCastAnimations(Ability.ActiveTracks, player)
	Ability:Fire(player, castIdentifier, args.target)
end

function Ability:ServerAbility(player, castIdentifier, args, startTime)
	AbInject.PlayerRemoteService:FireAllClientsExclude(Signal, player, "ability", player, castIdentifier, args, startTime)
	
	AbInject.DamageService:DoDamage(args.target.object, {
		ability = SelfAbilityData.name,
		damageType = "direct",
		fromPlayer = player
	})
end

function Ability:Fire(player, castIdentifier, currentTarget)
	local playerHaste = AbInject.PlayerValues:GetValue(player, "Haste")
	local animationHasteAdjustment = math.pow(AbInject.StatFunctions:AdjustForHaste(1, playerHaste), -1) * 0.75
	
	AbInject.GameSignals:Fire("AbilityUsed", "use-charge", {player = player, ability = SelfAbilityData.name, duration = SelfAbilityData.cooldown, maxCharge = SelfAbilityData.maxCharge})
	local trackLength = AbInject.AnimationData:GetAnimationTrackLength(FireAnimationid)

	local fireTrack = player.Character.Humanoid:LoadAnimation(SelfAnimations.CastFire)
	Ability.ActiveTracks[player]["fire"] = fireTrack

	fireTrack:Play(0.1, 1, animationHasteAdjustment)
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
