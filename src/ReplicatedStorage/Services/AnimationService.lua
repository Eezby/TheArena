local AnimationService = {}

function AnimationService.addAnimation(humanoid, id, animationType)
    if animationType == "idle" then
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..id

        local track = humanoid:LoadAnimation(animation)

        local idleConnection = humanoid.Running:Connect(function(speed)
            if speed >= 1 then
                track:Stop()
            else
                track:Play()
            end
        end)

        track:Play()

        return track, idleConnection

    elseif animationType == "move" then
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..id

        local track = humanoid:LoadAnimation(animation)

        local movementConnection = humanoid.Running:Connect(function(speed)
            if speed >= 1 then
                track:Play()
            else
                track:Stop()
            end
        end)

        return track, movementConnection
    end
end

return AnimationService