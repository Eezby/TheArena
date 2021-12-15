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
	Ability:Fire(player, castIdentifier)
end

function Ability:Fire(player, castIdentifier)
	local character = player.Character
	
	local playerHaste = AbInject.PlayerValues:GetValue(player, "Haste")
	local animationHasteAdjustment = math.pow(AbInject.StatFunctions:AdjustForHaste(1, playerHaste), -1) * 0.75
	
	AbInject.GameSignals:Fire("AbilityUsed", "cooldown", {player = player, ability = SelfAbilityData.name, duration = SelfAbilityData.cooldown})
	local trackLength = AbInject.AnimationData:GetAnimationTrackLength(FireAnimationid)

	local fireTrack = player.Character.Humanoid:LoadAnimation(SelfAnimations.CastFire)
	Ability.ActiveTracks[player]["fire"] = fireTrack
	
	fireTrack:Play(0.1, 1, animationHasteAdjustment)
	
	local playerSize = player.Character:GetExtentsSize()
	local shieldObject = SelfAssets.Shield:Clone()
	shieldObject.Size = Vector3.new(playerSize.X, playerSize.Y, playerSize.X) * Vector3.new(1.5, 1.1, 1.5)
	shieldObject.Transparency = 1
	shieldObject:PivotTo(CFrame.new(player.Character:GetPivot().Position))
	shieldObject.Parent = workspace.Dynamic
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = player.Character.PrimaryPart
	weld.Part1 = shieldObject
	weld.Parent = shieldObject
	
	local goal = {Transparency = 0}
	local properties = {Time = 1, Reverse = true, Dir = "Out", Style = "Sine"}
	local tween = AbInject.TweenService.tween(shieldObject, goal, properties)
	
	tween.Completed:Wait()
	
	shieldObject:Destroy()
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
	
	AbInject.DamageService:GiveShield(player.Character, {
		ability = SelfAbilityData.name,
		duration = SelfAbilityData.duration,
		shieldIdentifier = SelfAbilityData.name..player.Name,
		fromPlayer = player
	})
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
