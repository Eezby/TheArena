local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local TweenService = require(Utility:WaitForChild("TweenService"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Castbar = PlayerGui:WaitForChild("Castbar")
local Frame = Castbar:WaitForChild("Frame")

local function formatTime(s)
	s = math.floor(s * 10 + 0.5) / 10
	s = math.clamp(s, 0, 99e99)
	
	return s.."s"
end

local CastbarUi = {}
CastbarUi.CurrentTween = nil
CastbarUi.HeartbeatConnection = nil

function CastbarUi:Cast(ability, castTime)
	if CastbarUi.CurrentTween then
		CastbarUi.CurrentTween:Cancel()
	end
	
	Frame.Visible = true
	Frame.Container.Bar.Size = UDim2.new(0,0,1,0)
	
	local goal = {Size = UDim2.new(1,0,1,0)}
	local properties = {Time = castTime}
	CastbarUi.CurrentTween = TweenService.tween(Frame.Container.Bar, goal, properties)
	
	Frame.Container.Ability.Text = ability
	Frame.Container.CastTime.Text = formatTime(castTime)
	
	local startTime = tick()
	CastbarUi.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		local remainingTime = castTime - (tick() - startTime)
		Frame.Container.CastTime.Text = formatTime(remainingTime)
		
		if remainingTime <= 0 then
			CastbarUi:Cancel()
		end
	end)
end

function CastbarUi:SimulateCast(castFrame, ability, castTime, castStartTime)
	local timeElasped = math.clamp(math.abs(SharedFunctions:GetTime() - castStartTime), 0, castTime * 0.01)
	local adjustedCastTime = math.clamp(castTime - timeElasped, 0, castTime)
	
	--print(timeElasped, adjustedCastTime)
	
	castFrame.Container.Bar.Size = UDim2.new(timeElasped/castTime,0,1,0)

	local goal = {Size = UDim2.new(1,0,1,0)}
	local properties = {Time = adjustedCastTime}
	local tween = TweenService.tween(castFrame.Container.Bar, goal, properties)

	castFrame.Container.Ability.Text = ability
	castFrame.Container.CastTime.Text = formatTime(adjustedCastTime)

	local startTime = SharedFunctions:GetTime()
	local heartbeatConnection
	heartbeatConnection	= RunService.Heartbeat:Connect(function()
		local remainingTime = adjustedCastTime - (SharedFunctions:GetTime() - startTime)
		castFrame.Container.CastTime.Text = formatTime(remainingTime)

		if remainingTime <= 0 then
			heartbeatConnection:Disconnect()
		end
	end)
	
	return tween, heartbeatConnection
end

function CastbarUi:Cancel()
	if CastbarUi.CurrentTween then
		CastbarUi.CurrentTween:Cancel()
	end
	
	if CastbarUi.HeartbeatConnection then
		CastbarUi.HeartbeatConnection:Disconnect()
	end
	
	Frame.Visible = false
end

return CastbarUi
