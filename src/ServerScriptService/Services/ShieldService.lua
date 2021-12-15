local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility.SharedFunctions)

local ShieldService = {}
ShieldService.Shields = {}

function ShieldService:GiveShield(from, to, amount, identifier, args)
	if not self.Shields[to] then
		self.Shields[to] = {}
	end
	
	local endTime = SharedFunctions:GetTime() + (args.duration or 10000)
	
	if self.Shields[to][identifier] then
		self.Shields[to][identifier].endTime = endTime
		self.Shields[to][identifier].amountLeft = amount
	else
		local newShield = {
			id = identifier,
			amountLeft = amount,
			duration = args.duration or 10000,
			endTime = endTime
		}
		
		self.Shields[to][identifier] = newShield
	end
	
	if args.duration then
		task.delay(args.duration, function()
			if self.Shields[to][identifier] then
				if endTime == self.Shields[to][identifier].endTime then
					self.Shields[to][identifier] = nil
				end
			end 
		end)
	end
end

function ShieldService:TakeDamage(from, to, amount)
	local adjustedAmount = amount
	
	if not self.Shields[to] then
		return adjustedAmount
	end
	
	for _,shield in pairs(self.Shields[to]) do
		if adjustedAmount >= shield.amountLeft then
			adjustedAmount -= shield.amountLeft
			self.Shields[to][shield] = nil
		elseif adjustedAmount < shield.amountLeft then
			shield.amountLeft -= adjustedAmount
			return 0
		end
		
		if adjustedAmount == 0 then
			return 0
		end
	end
	
	return adjustedAmount
end

return ShieldService
