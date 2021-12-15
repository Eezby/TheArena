local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"):WaitForChild("Ragdoll"))

local RagdollService = {}

function RagdollService.SetRagdoll(character, state, args)
	if character then
		if state then
			return Ragdoll:Activate(character, args)
		else
			return Ragdoll:Deactivate(character)
		end
	end
end

return RagdollService