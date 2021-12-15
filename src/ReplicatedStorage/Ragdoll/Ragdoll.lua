local Ragdoll = {}

--[[
	Module that can be used to ragdoll arbitrary R6/R15 rigs or set whether players ragdoll or fall to pieces by default
--]]

local EVENT_NAME = "Event"
local RAGDOLLED_TAG = "__Ragdoll_Active"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local RigTypes = require(script.Parent:WaitForChild("RigTypes"))

local StoredRagdollJoints = {}

if RunService:IsServer() then
		
	-- Used for telling the client to set their own character to Physics mode:
	local event = Instance.new("RemoteEvent")
	event.Name = EVENT_NAME
	event.Parent = script
	
	-- Whether players ragdoll by default: (true = ragdoll, false = fall into pieces)
	local playerDefault = false
	
	-- Activating ragdoll on an arbitrary model with a Humanoid:
	local function activateRagdoll(model, humanoid, args)
		if not args then args = {} end

		assert(humanoid:IsDescendantOf(model))
		if CollectionService:HasTag(model, RAGDOLLED_TAG) then
			return
		end
		CollectionService:AddTag(model, RAGDOLLED_TAG)
		
		-- Propagate to player if applicable:
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			event:FireClient(player, true, model, humanoid)
		elseif model.PrimaryPart then
			event:FireAllClients(false, model, humanoid)
		end
		
		StoredRagdollJoints[model] = {}
		
		-- Turn into loose body:
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		
		-- Instantiate BallSocketConstraints:
		local attachments = RigTypes.getAttachments(model, humanoid.RigType)
		for name, objects in pairs(attachments) do
			local parent = model:FindFirstChild(name)
			if parent then
				local constraint = Instance.new("BallSocketConstraint")
				constraint.Name = "RagdollBallSocketConstraint"
				constraint.Attachment0 = objects.attachment0
				constraint.Attachment1 = objects.attachment1
				constraint.LimitsEnabled = true
				constraint.UpperAngle = objects.limits.UpperAngle
				constraint.TwistLimitsEnabled = true
				constraint.TwistLowerAngle = objects.limits.TwistLowerAngle
				constraint.TwistUpperAngle = objects.limits.TwistUpperAngle
				constraint.Parent = parent
				
				table.insert(StoredRagdollJoints[model] , constraint)
			end
		end
		
		-- Instantiate NoCollisionConstraints:
		local parts = RigTypes.getNoCollisions(model, humanoid.RigType)
		for _, objects in pairs(parts) do
			local constraint = Instance.new("NoCollisionConstraint")
			constraint.Name = "RagdollNoCollisionConstraint"
			constraint.Part0 = objects[1]
			constraint.Part1 = objects[2]
			constraint.Parent = objects[1]
			
			table.insert(StoredRagdollJoints[model] , constraint)
		end
		
		-- Destroy all regular joints and make baseparts collidable:
		for _, object in pairs(model:GetDescendants()) do
			if object:IsA("Motor6D") and object.Part0 ~= model.PrimaryPart then
				local isWeaponWeld = string.find(object.Name, "WeaponWeld")
				if not isWeaponWeld or (isWeaponWeld and args.disableWeaponWeld) then
					object.Enabled = false
				end
			elseif object:IsA("BasePart") and not object.Parent:IsA("Accessory") then
				if object ~= model.PrimaryPart and not CollectionService:HasTag(object, "HitBox") then
					object.CanCollide = true
				else
					object.CanCollide = false
				end
			end
		end
		
		return true
	end
	
	local function deactivateRagdoll(model, humanoid)
		if StoredRagdollJoints[model] then
			local player = Players:GetPlayerFromCharacter(model)
			if player then
				event:FireClient(player, true, model, humanoid, true)
			elseif model.PrimaryPart then
				event:FireAllClients(false, model, humanoid, true)
			end
			
			CollectionService:RemoveTag(model, RAGDOLLED_TAG)
			
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

			for _, object in pairs(model:GetDescendants()) do
				if object:IsA("Motor6D") then
					object.Enabled = true
				elseif object:IsA("BasePart") then
					object.Velocity = Vector3.new(0,0,0)

					if object.Parent.Name == "Weapons" or object.Parent.Parent.Name == "Weapons" then
						object.CanCollide = false
					end
				end
			end
			
			for _,joint in pairs(StoredRagdollJoints[model]) do
				joint:Destroy()
			end
		end
	end
	
	-- Activating the ragdoll on a specific model
	function Ragdoll:Activate(model, args)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			error("bad argument #1 to 'Activate' (Model expected, got " .. typeof(model) .. ")", 2)
		end
		
		-- Model must have a humanoid:
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return warn("[Ragdoll] Could not ragdoll " .. model:GetFullName() .. " because it has no Humanoid")
		end
		
		return activateRagdoll(model, humanoid, args)
	end
	
	function Ragdoll:Deactivate(model)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			error("bad argument #1 to 'Activate' (Model expected, got " .. typeof(model) .. ")", 2)
		end
		
		-- Model must have a humanoid:
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return warn("[Ragdoll] Could not ragdoll " .. model:GetFullName() .. " because it has no Humanoid")
		end
		
		deactivateRagdoll(model, humanoid)
	end
	
	-- Setting whether players ragdoll when dying by default: (true = ragdoll, false = fall into pieces)
	function Ragdoll:SetPlayerDefault(enabled)
		if enabled ~= nil and typeof(enabled) ~= "boolean" then
			error("bad argument #1 to 'SetPlayerDefault' (boolean expected, got " .. typeof(enabled) .. ")", 2)
		end
		
		playerDefault = enabled
		
		-- Update BreakJointsOnDeath for all alive characters:
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.BreakJointsOnDeath = not playerDefault
				end
			end
		end
	end
	
else -- Client
	-- Client sets their own character to Physics mode when told to:
	script:WaitForChild(EVENT_NAME).OnClientEvent:Connect(function(isSelf, model, humanoid, deactivate)
		print'received'
		if not deactivate then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			
			if isSelf then
				local head = model:FindFirstChild("Head")
				if head then
					task.spawn(function()
						repeat
							workspace.CurrentCamera.CameraSubject = head
							task.wait()
						until workspace.CurrentCamera.CameraSubject == head
					end)				
				end
			end
		else
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			if isSelf then
				task.spawn(function()
					repeat
						workspace.CurrentCamera.CameraSubject = humanoid
						task.wait()
					until workspace.CurrentCamera.CameraSubject == humanoid
				end)
			end
		end
	end)
	
	-- Other API not available from client-side:
	
	function Ragdoll:Activate()
		error("Ragdoll::Activate cannot be used from the client", 2)
	end
	
	function Ragdoll:SetPlayerDefault()
		error("Ragdoll::SetPlayerDefault cannot be used from the client", 2)
	end

end

return Ragdoll
