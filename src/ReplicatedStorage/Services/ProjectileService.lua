local RunService = game:GetService("RunService")

local function getTargetPosition(target)
	if typeof(target) == "Instance" then
		return target:GetPivot().Position
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
		
		projectile = args.projectile,
		target = target,
		cframe = args.startCFrame or CFrame.new()
	}
	
	interactable.connection = RunService.Heartbeat:Connect(function(dt)
		local targetDirection = (getTargetPosition(target) - interactable.cframe.Position).Unit
		interactable.cframe += targetDirection * args.projectileSpeed * dt
		
		if (interactable.cframe.Position - getTargetPosition(target)).Magnitude <= 1.5 then
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
