local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SerServices = ServerScriptService.Services
local DamageServiceSignal = SerServices.DamageService:WaitForChild("Signal")

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility.SharedFunctions)

local RepData = ReplicatedStorage.Data
local EffectData = require(RepData.EffectData)

local Remotes = ReplicatedStorage.Remotes

local EffectsRemote = Instance.new("RemoteEvent")
EffectsRemote.Name = "Effects"
EffectsRemote.Parent = Remotes

local Animations = {}
Animations.Fear = Instance.new("Animation")
Animations.Fear.AnimationId = "rbxassetid://5149265517"

local EffectService = {}
EffectService.CurrentEffects = {}

local function checkTarget(targetObject)
	if not EffectService.CurrentEffects[targetObject] then
		EffectService.CurrentEffects[targetObject] = {}
	end
end

function EffectService:IsCCed(target)
	if self.CurrentEffects[target] then
		if self.CurrentEffects[target]["Fear"] then return true end
		if self.CurrentEffects[target]["Stun"] then return true end
	end

	return false
end

function EffectService:RemoveEffect(target, effect)
	local targetObject = target.object
	
	checkTarget(targetObject)
	
	local effectObject = self.CurrentEffects[targetObject][effect]
	if effectObject then
		effectObject.connection:Disconnect()
		effectObject.track:Stop()
		self.CurrentEffects[targetObject][effect] = nil
	end
	
	EffectsRemote:FireAllClients(target, effect, nil)
end

function EffectService:TookDamage(target, damageType, fromPlayer)
	print('took damage', target)
	checkTarget(target)
	
	for effect, info in pairs(self.CurrentEffects[target]) do
		local effectData = EffectData[effect]
		if effectData.breakFromDamageChance then
			local randomChance = math.random(1,100)
			if randomChance <= effectData.breakFromDamageChance[damageType] * 100 then
				self:RemoveEffect({model = target}, effect, {fromPlayer = fromPlayer})
			end
		end
	end
end

function EffectService:Fear(target, duration, args)
	local targetObject = target.object
	local targetCharacter = targetObject.Character

	checkTarget(targetObject)
	
	if target.targetType == "Player" then
		EffectsRemote:FireAllClients(targetObject, "Fear", SharedFunctions:GetTime() + duration, args)
	end
	
	if self.CurrentEffects[targetObject]["Fear"] then
		self.CurrentEffects[targetObject]["Fear"].endTime = SharedFunctions:GetTime() + duration
		return self.CurrentEffects[targetObject]["Fear"]
	end
	
	local effectObject = {
		endTime = SharedFunctions:GetTime() + duration, 
		duration = duration, 
	}
	
	self.CurrentEffects[targetObject]["Fear"] = effectObject
	
	if targetCharacter then
		effectObject.track = targetCharacter.Humanoid:LoadAnimation(Animations.Fear)
		effectObject.track:Play()
	end
	
	local position = nil
	local walking = false
	
	effectObject.connection = RunService.Heartbeat:Connect(function()
		if effectObject then
			local targetPosition

			if target.targetType == "Player" then
				targetPosition = targetCharacter:GetPivot()
			elseif target.targetType == "NPC" then
				targetPosition = target.object.cframe.Position
			end
			
			if not position then
				position = targetPosition + Vector3.new(math.random(-5,5), targetPosition.Y, math.random(-5,5))
				walking = true
			end
			
			if walking then
				if target.targetType == "Player" then
					targetCharacter.Humanoid:MoveTo(position)
				elseif target.targetType == "NPC" then
					target.object.cframe = target.object.cframe + (position - target.object.cframe.Position).Unit * 0.25
				end
				
				if (targetPosition - position).Magnitude <= 5 then
					walking = false
					position = nil
				end
				
				if SharedFunctions:GetTime() >= effectObject.endTime then
					self:RemoveEffect(target, "Fear")
				end
			end
		else
			self:RemoveEffect(target, "Fear")
		end
	end)
	
	return effectObject
end

function EffectService:Stun(target, duration)
	checkTarget(target.model)
end

return EffectService
