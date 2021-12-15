local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local RepData = ReplicatedStorage:WaitForChild("Data")
local EffectData = require(RepData:WaitForChild("EffectData"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
local PlayerControls = PlayerModule:GetControls()

local PlayerServices = PlayerScripts:WaitForChild("Services")
local OverheadService = require(PlayerServices:WaitForChild("OverheadService"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EffectRemote = Remotes:WaitForChild("Effects")

local EffectReplicator = {}
EffectReplicator.CurrentEffects = {}

local function checkTarget(targetModel)
	if not EffectReplicator.CurrentEffects[targetModel] then
		EffectReplicator.CurrentEffects[targetModel] = {}
	end
end

local function setPlayerControls(toggle)
	if toggle then
		PlayerControls:Enable()
	else
		PlayerControls:Disable()
	end
end

function EffectReplicator:IsCCed(target)
	if self.CurrentEffects[target] then
		if self.CurrentEffects[target]["Fear"] then return true end
		if self.CurrentEffects[target]["Stun"] then return true end
	end
	
	return false
end

EffectRemote.OnClientEvent:Connect(function(target, effect, value, args)
	if not target then return nil end
	if not args then args = {} end
	
	local targetModel = target.model
	
	checkTarget(targetModel)
	
	EffectReplicator.CurrentEffects[targetModel][effect] = value
	
	if args.fromPlayer then
		OverheadService:Effect(args.fromPlayer, targetModel, effect)
	end
	
	if targetModel == LocalPlayer.Character then
		local effectData = EffectData[effect]
		if effectData then
			if effectData.lockControls then
				if value then
					setPlayerControls(false)
					task.delay(value - SharedFunctions:GetTime(), function()
						if EffectReplicator.CurrentEffects[targetModel][effect] == value then
							setPlayerControls(true)
						end
					end)
				else
					setPlayerControls(true)
				end
			end
		end
	end
end)
return EffectReplicator