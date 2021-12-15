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

local function checkTarget(targetModel)
	if not EffectService.CurrentEffects[targetModel] then
		EffectService.CurrentEffects[targetModel] = {}
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
	local targetModel = target.model
	
	checkTarget(targetModel)
	
	local effectObject = self.CurrentEffects[targetModel][effect]
	if effectObject then
		effectObject.connection:Disconnect()
		effectObject.track:Stop()
		self.CurrentEffects[targetModel][effect] = nil
	end
	
	EffectsRemote:FireAllClients(target, effect, nil)
end

function EffectService:TookDamage(target, damageType, fromPlayer)
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
	local targetModel = target.model
	
	checkTarget(targetModel)
	
	EffectsRemote:FireAllClients(target, "Fear", SharedFunctions:GetTime() + duration, args)
	
	if self.CurrentEffects[targetModel]["Fear"] then
		self.CurrentEffects[targetModel]["Fear"].endTime = SharedFunctions:GetTime() + duration
		return self.CurrentEffects[targetModel]["Fear"]
	end
	
	local effectObject = {
		endTime = SharedFunctions:GetTime() + duration, 
		duration = duration, 
	}
	
	self.CurrentEffects[targetModel]["Fear"] = effectObject
	
	effectObject.track = targetModel.Humanoid:LoadAnimation(Animations.Fear)
	effectObject.track:Play()
	
	local position = nil
	local walking = false
	
	effectObject.connection = RunService.Heartbeat:Connect(function()
		if effectObject then
			local targetPosition = targetModel:GetPivot().Position 
			
			if not position then
				position = targetPosition
					+ Vector3.new(math.random(-5,5), targetPosition.Y, math.random(-5,5))
				walking = true
			end
			
			if walking then
				targetModel.Humanoid:MoveTo(position)
				
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
