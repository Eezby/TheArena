local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RepData = ReplicatedStorage:WaitForChild("Data")
local AbilityData = require(RepData:WaitForChild("AbilityData"))
local DefaultAnimations = require(RepData:WaitForChild("DefaultAnimations"))

local Utility = ReplicatedStorage:WaitForChild("Utility")

local SetupRig = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Rigs"):WaitForChild("CustomRig"):Clone()
SetupRig:SetPrimaryPartCFrame(CFrame.new(1000000, 10, 10))
SetupRig.Parent = workspace

local LoadedAnimations = {}
local WaitCount = 0
local IsLoaded = false

local function loadAnimation(temporaryAnimation, animationId, keyframes)
	temporaryAnimation.AnimationId = "rbxassetid://"..animationId

	WaitCount += 1
	coroutine.wrap(function()
		local animator = SetupRig.Humanoid:FindFirstChild("Animator") or SetupRig.Humanoid
		local temporaryTrack = animator:LoadAnimation(temporaryAnimation)
		repeat task.wait() until temporaryTrack.Length > 0

		local animationObject = {keyframes = {}, length = temporaryTrack.Length}
		for _,keyframe in pairs(keyframes) do
			table.insert(animationObject.keyframes, {name = keyframe, t = temporaryTrack:GetTimeOfKeyframe(keyframe)})
		end

		LoadedAnimations[animationId] = animationObject
		WaitCount -= 1
	end)()
end

coroutine.wrap(function()
	local temporaryAnimation = Instance.new("Animation")
	
	for _,ability in pairs(AbilityData) do
		for animation,info in pairs(ability.animations or {}) do
			loadAnimation(temporaryAnimation, tostring(info.id), info.keyframes)
		end
	end
	
	for _,animation in pairs(DefaultAnimations) do
		loadAnimation(temporaryAnimation, tostring(animation), {})
	end

	repeat task.wait() until WaitCount == 0

	IsLoaded = true
end)()

local AnimationData = {}

function AnimationData:GetData()
	return LoadedAnimations
end

function AnimationData:GetAnimationKeyframeTime(id, keyframe)
	local animationData = LoadedAnimations[tostring(id)]
	if animationData then
		for _,keyframeData in pairs(animationData.keyframes) do
			if keyframeData.name == keyframe then
				return keyframeData.t
			end
		end
	end

	return 0
end

function AnimationData:GetAnimationTrackLength(id)
	local animationData = LoadedAnimations[tostring(id)]
	if animationData then
		return animationData.length
	end

	return 0
end

return AnimationData