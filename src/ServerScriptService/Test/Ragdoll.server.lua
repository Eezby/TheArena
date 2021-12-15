local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SerServices = ServerScriptService.Services
local RagdollService = require(SerServices.RagdollService)


Players.PlayerAdded:Wait()

local player = Players:GetChildren()[1]
local character = player.Character or player.CharacterAdded:Wait()

task.wait(2)

RagdollService.SetRagdoll(character, true)
