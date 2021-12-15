local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local GameSignals = require(Utility:WaitForChild("GameSignals"))

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PlayerCooldowns = require(RepServices:WaitForChild("PlayerCooldowns"))

local RepData = ReplicatedStorage:WaitForChild("Data")
local ClassData = require(RepData:WaitForChild("ClassData"))
local AbilityData = require(RepData:WaitForChild("AbilityData"))

local RepAssets = ReplicatedStorage:WaitForChild("Assets")
local Ui = RepAssets:WaitForChild("Ui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Hotbars = PlayerGui:WaitForChild("Hotbars")

local AbilityUsedSignal = GameSignals:Get("AbilityUsed")
local ChargeSignal = GameSignals:Get("Charge")

local SlotMapping = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = 'Q',
	[10] = 'E',
	[11] = 'R',
	[12] = 'T',
	[13] = 'Y',
	[14] = 'Z',
	[15] = 'X',
	[16] = 'C',
}

local function formatTime(s)
	s = math.floor(s + 0.5)
	s = math.clamp(s, 0, 99e99)

	return s.."s"
end

local HotbarUi = {}
HotbarUi.CurrentSlots = {}

function HotbarUi:SetKeybinds(class)
	self.CurrentSlots = {}
	
	local SlotNumber = 1

	for _,bar in ipairs(Hotbars:GetChildren()) do
		SharedFunctions:ClearAllChildrenOfType(bar, "Frame")
	end

	for _,bar in ipairs(Hotbars:GetChildren()) do
		for i = 1,8 do
			local newAbilitySlot = Ui.Hotbar.Ability:Clone()
			newAbilitySlot.AbilityFrame.AbilityImage.Image = ""
			newAbilitySlot.AbilityFrame.Hotkey.Text = SlotMapping[SlotNumber]

			newAbilitySlot.Name = "Ability_"..SlotNumber

			newAbilitySlot.Parent = bar

			self.CurrentSlots[SlotNumber] = {
				ui = newAbilitySlot,
				key = SlotMapping[SlotNumber]
			}
			
			SlotNumber += 1
		end
	end

	for slot,ability in ipairs(ClassData[class].abilities) do
		local abilitySlot = self.CurrentSlots[slot]
		local abilityData = AbilityData[ability]

		if abilitySlot and abilityData then
			abilitySlot.ui.AbilityFrame.AbilityImage.Image = "rbxassetid://"..abilityData.image
			abilitySlot.ability = ability
			
			if abilityData.maxCharge then
				abilitySlot.ui.AbilityFrame.Charge.Visible = true
				abilitySlot.ui.AbilityFrame.Charge.Text = abilityData.maxCharge
			end
		end
	end
end

function HotbarUi:Cooldown(value, valueType, duration)
	local slot
	if valueType == "key" then
		slot = HotbarUi:GetSlotFromKey(value)
	elseif valueType == "ability" then
		slot = HotbarUi:GetSlotFromAbility(value)
	end
	
	if slot then
		slot.onCooldown = true
		slot.cooldownEndTime = SharedFunctions:GetTime() + duration
		slot.cooldownDuration = duration

		slot.ui.Cooldown.Visible = true
		slot.ui.CooldownText.Visible = true

		slot.ui.Cooldown.Size = UDim2.new(1,0,1,0)
		slot.ui.CooldownText.Text = formatTime(duration)

		slot.heartbeatConnection = RunService.Heartbeat:Connect(function()
			local remainingTime = slot.cooldownEndTime - SharedFunctions:GetTime()
			
			slot.ui.Cooldown.Size = UDim2.new(1,0,remainingTime / duration, 0)
			slot.ui.CooldownText.Text = formatTime(remainingTime)
			
			if remainingTime <= 0 then
				slot.ui.Cooldown.Visible = false
				slot.ui.CooldownText.Visible = false
				slot.heartbeatConnection:Disconnect()
			end
		end)
	end
end

function HotbarUi:Charge(value, valueType, duration, args)
	local slot
	if valueType == "key" then
		slot = HotbarUi:GetSlotFromKey(value)
	elseif valueType == "ability" then
		slot = HotbarUi:GetSlotFromAbility(value)
	end
	
	if slot then
		slot.ui.AbilityFrame.Charge.Text = args.charges
	end
end

function HotbarUi:GetSlotFromKey(key)
	for _,slot in pairs(self.CurrentSlots or {}) do
		if tostring(slot.key) == tostring(key) then
			return slot
		end
	end
	
	return false
end

function HotbarUi:GetSlotFromAbility(ability)
	for _,slot in pairs(self.CurrentSlots or {}) do
		if slot.ability == ability then
			return slot
		end
	end

	return false
end

AbilityUsedSignal.Event:Connect(function(action, args)
	if action == "cooldown" then
		local ability = args.ability
		
		HotbarUi:Cooldown(ability, "ability", AbilityData[ability].cooldown, args)
	end
end)

ChargeSignal.Event:Connect(function(args)
	local ability = args.ability
	
	HotbarUi:Charge(ability, "ability", AbilityData[ability].cooldown, args)
end)

return HotbarUi
