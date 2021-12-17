local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SerServices = ServerScriptService.Services
local DamageService = require(SerServices.DamageService)
local EntityService = require(SerServices.EntityService)

task.spawn(EntityService.init)