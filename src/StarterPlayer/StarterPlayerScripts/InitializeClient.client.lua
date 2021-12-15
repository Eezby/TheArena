local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerStatusService = require(RepServices:WaitForChild("PlayerStatusService"))

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"):WaitForChild("Ragdoll"))

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local function clientModuleLoad(object)
    if object:IsA("ModuleScript") then
        local uselessReference = require(object)
        if typeof(uselessReference) == "table" and uselessReference["Init"] then
            uselessReference:Init()
        end
    end
end

PlayerScripts.DescendantAdded:Connect(function(object)
    clientModuleLoad(object)
end)

for _,object in pairs(PlayerScripts:GetDescendants()) do
    clientModuleLoad(object)
end

PlayerStatusService:AddPlayer(LocalPlayer)