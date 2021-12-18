local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local EntityService
local EntityHandler

if IsServer then
	local SerServices = ServerScriptService.Services
	EntityService = require(SerServices.EntityService)
else
	local LocalPlayer = Players.LocalPlayer
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerServices = PlayerScripts:WaitForChild("Services")

	EntityHandler = require(PlayerServices:WaitForChild("EntityHandler"))
end

local function getTargetPosition(target)
	if typeof(target) == "table" then
		return target:GetCFrame().Position
	elseif typeof(target) == "CFrame" then
		return target.Position
	end
	
	return target
end

local ProjectileService = {}
function ProjectileService:FireAtTarget(target, args)
	local finishedEvent = Instance.new("BindableEvent")
	
	local interactable = {
		Finished = finishedEvent,
		target = target,
		projectile = args.projectile,
		cframe = args.startCFrame or CFrame.new()
	}

	interactable.connection = RunService.Heartbeat:Connect(function(dt)
		local targetDirection = (getTargetPosition(interactable.target) - interactable.cframe.Position).Unit
		interactable.cframe += targetDirection * args.projectileSpeed * dt
		
		if (interactable.cframe.Position - getTargetPosition(interactable.target)).Magnitude <= 1.5 then
			interactable.connection:Disconnect()
			interactable.Finished:Fire()
		end

		if args.projectile then
			args.projectile:PivotTo(interactable.cframe)
		end
	end)
	
	return interactable
end
return ProjectileService
