local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Utility = ReplicatedStorage.Utility
local TweenService = require(Utility.TweenService)

local Assets = ReplicatedStorage:WaitForChild("Assets")
local MiscAssets = Assets:WaitForChild("Misc")
local DamagePart = MiscAssets:WaitForChild("DamagePart")
local EffectPart = MiscAssets:WaitForChild("EffectPart")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OverheadRemote = Remotes:WaitForChild("Overhead")

local OverheadService = {}

function OverheadService:Damage(fromPlayer, position, damage, args)
	if fromPlayer == LocalPlayer then
		local newPart = DamagePart:Clone()
		newPart.Gui.Frame.DamageText.Text = damage
		newPart.Gui.Frame.DamageTextShadow.Text = damage

		if args.isCrit then
			newPart.Gui.Frame.DamageText.Font = "GothamBold"
			newPart.Gui.Frame.DamageTextShadow.Font = "GothamBold"

			newPart.Gui.Frame.DamageText.TextColor3 = Color3.fromRGB(255, 28, 28)
		end

		newPart:PivotTo(CFrame.new(position) + Vector3.new(0, 5, 0))
		newPart.Parent = workspace.Display

		local goal = {StudsOffset = Vector3.new(0,5,0)}
		local properties = {Time = 1}
		TweenService.tween(newPart.Gui, goal, properties)

		local goal = {TextTransparency = 1, TextStrokeTransparency = 1}
		local properties = {Delay = 0.25, Time = 0.75}
		TweenService.tween(newPart.Gui.Frame.DamageText, goal, properties)
		TweenService.tween(newPart.Gui.Frame.DamageTextShadow, goal, properties)

		task.wait(properties.Time + properties.Delay)

		newPart:Destroy()
	end
end

function OverheadService:Effect(fromPlayer, target, effect, args)
	if fromPlayer == LocalPlayer then
		local newPart = EffectPart:Clone()
		newPart.Gui.Frame.EffectText.Text = effect
		newPart.Gui.Frame.EffectTextShadow.Text = effect

		newPart:PivotTo(target:GetPivot() + Vector3.new(0, 5, 0))
		newPart.Parent = workspace.Display

		local goal = {StudsOffset = Vector3.new(0,5,0)}
		local properties = {Time = 1}
		TweenService.tween(newPart.Gui, goal, properties)

		local goal = {TextTransparency = 1, TextStrokeTransparency = 1}
		local properties = {Delay = 0.25, Time = 0.75}
		TweenService.tween(newPart.Gui.Frame.EffectText, goal, properties)
		TweenService.tween(newPart.Gui.Frame.EffectTextShadow, goal, properties)

		task.wait(properties.Time + properties.Delay)

		newPart:Destroy()
	end
end

OverheadRemote.OnClientEvent:Connect(function(action, ...)
	if action == "damage" then
		OverheadService:Damage(...)
	elseif action == "effect" then
		OverheadService:Effect(...)
	end
end)

return OverheadService