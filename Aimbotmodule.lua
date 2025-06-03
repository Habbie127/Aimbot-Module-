local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 50
local AimbotRange = 300
local AimbotSmoothness = 0.1
local useLerp = false

local aimlockEnabled = false
local nearestAimbotEnabled = false
local aimlockConnection = nil
local nearestConnection = nil

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVCircleGui"
FOVGui.ResetOnSpawn = false
FOVGui.Parent = game.CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.4)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Size = UDim2.fromOffset(FOVRadius * 2, FOVRadius * 2)
FOVCircle.ZIndex = 10
FOVCircle.Visible = false
FOVCircle.Parent = FOVGui

local UICorner = Instance.new("UICorner", FOVCircle)
UICorner.CornerRadius = UDim.new(1, 0)

local FOVOutline = Instance.new("UIStroke", FOVCircle)
FOVOutline.Thickness = 1
FOVOutline.Color = Color3.fromRGB(0, 255, 0)
FOVOutline.Transparency = 0

-- Enhanced visibility checker with multiple raycast points
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local targetSize = targetPart.Size
    
    -- Create multiple test points around the target
    local testPoints = {
        targetPos, -- Center
        targetPos + Vector3.new(targetSize.X/3, 0, 0), -- Right
        targetPos - Vector3.new(targetSize.X/3, 0, 0), -- Left
        targetPos + Vector3.new(0, targetSize.Y/3, 0), -- Top
        targetPos - Vector3.new(0, targetSize.Y/3, 0), -- Bottom
    }
    
    local visiblePoints = 0
    local totalPoints = #testPoints
    
    for _, testPoint in ipairs(testPoints) do
        local direction = testPoint - origin
        local distance = direction.Magnitude
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
        
        local result = Workspace:Raycast(origin, direction.Unit * distance, raycastParams)
        
        if not result then
            visiblePoints = visiblePoints + 1
        end
    end
    
    -- Target is considered visible if at least 40% of test points are visible
    return (visiblePoints / totalPoints) >= 0.4
end

-- Safe function to check if player has valid character and humanoid
local function isValidTarget(player)
    if not player or player == LocalPlayer then
        return false
    end
    
    -- Check if player has character
    if not player.Character then
        return false
    end
    
    -- Check if character has required parts
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        return false
    end
    
    -- Safely check humanoid health
    local success, health = pcall(function()
        return humanoid.Health
    end)
    
    if not success or health <= 0 then
        return false
    end
    
    -- Check team (safely handle cases where Team might be nil)
    local playerTeam = player.Team
    local localTeam = LocalPlayer.Team
    
    if playerTeam and localTeam and playerTeam == localTeam then
        return false
    end
    
    return true
end

local function getClosestEnemyByDistance()
    local closest, shortest = nil, AimbotRange
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            
            if isVisible(hrp) then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                if distance <= shortest then
                    shortest = distance
                    closest = player
                end
            end
        end
    end
    
    return closest
end

local function getClosestEnemyFOV()
    local closest, minDist = nil, FOVRadius
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            
            if isVisible(hrp) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist <= minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    return closest
end

local WeaponBulletSpeeds = {
    ["Lewis Gun"] = 3300, ["Madsen 1905"] = 3400, ["CSRG 1915"] = 3450,
    ["Doppelpistole 1912"] = 2400, ["Gewehr 98"] = 4200, ["Beholla 1915"] = 2200,
    ["Farquhar Hill P08"] = 3500, ["Karabiner 98AZ"] = 3600, ["Mannlicher 1895"] = 4200,
    ["MG 15na"] = 3225, ["MP18,-I"] = 2600, ["Selbstlader 1906"] = 3600,
    ["RSC 1917"] = 3600, ["Ribeyrolles 1918"] = 2600,
}

local function getCurrentBulletSpeed()
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            if WeaponBulletSpeeds[tool.Name] then
                return WeaponBulletSpeeds[tool.Name]
            end
            local weaponName = string.lower(tool.Name)
            if string.find(weaponName, "rifle") or string.find(weaponName, "gewehr") or string.find(weaponName, "karabiner") then
                return 4000 -- High velocity rifles
            elseif string.find(weaponName, "pistol") or string.find(weaponName, "beholla") then
                return 2300 -- Pistols
            elseif string.find(weaponName, "mg") or string.find(weaponName, "gun") then
                return 3200 -- Machine guns
            elseif string.find(weaponName, "mp") then
                return 2600 -- Submachine guns
            end
        end
    end
    return 3000
end

local function getPredictedPosition(targetPart, targetVelocity, distance, bulletSpeed)
    local timeToHit = distance / bulletSpeed
    
    local currentPos = targetPart.Position
    
    -- Safely get velocity
    local currentVel = Vector3.new(0, 0, 0)
    if targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        currentVel = targetPart.Parent.HumanoidRootPart.Velocity
    end
    
    local velocityMagnitude = currentVel.Magnitude
    
    local predictionVel = targetVelocity
    if velocityMagnitude > 16 then -- Running speed threshold
        predictionVel = currentVel:Lerp(targetVelocity, 0.3)
    end
    
    local predictedPos = currentPos + (predictionVel * timeToHit)
    
    local gravityDrop = 0.5 * 196.2 * (timeToHit ^ 2) -- Using Roblox gravity
    predictedPos = predictedPos - Vector3.new(0, gravityDrop, 0)
    
    for i = 1, 2 do -- Fewer iterations for better performance
        local newDistance = (Camera.CFrame.Position - predictedPos).Magnitude
        local newTimeToHit = newDistance / bulletSpeed
        
        local finalVel = velocityMagnitude > 16 and currentVel or predictionVel
        predictedPos = currentPos + (finalVel * newTimeToHit)
        predictedPos = predictedPos - Vector3.new(0, 0.5 * 196.2 * (newTimeToHit ^ 2), 0)
    end
    
    return predictedPos
end

local targetVelocities = {} -- Store velocity history

local function getEnhancedVelocity(player)
    if not isValidTarget(player) then
        return Vector3.new(0, 0, 0)
    end
    
    local hrp = player.Character.HumanoidRootPart
    local currentVel = hrp.Velocity
    
    if not targetVelocities[player] then
        targetVelocities[player] = {
            history = {},
            lastPos = hrp.Position,
            lastTime = tick()
        }
    end
    
    local data = targetVelocities[player]
    local currentTime = tick()
    local deltaTime = currentTime - data.lastTime
    
    if deltaTime > 0 then
        local actualVel = (hrp.Position - data.lastPos) / deltaTime
        table.insert(data.history, {vel = currentVel, actual = actualVel, time = currentTime})
        
        data.lastPos = hrp.Position
        data.lastTime = currentTime
    end
    
    if #data.history > 3 then
        table.remove(data.history, 1)
    end
    
    if #data.history > 0 then
        local recent = data.history[#data.history]
        local velocityChange = (currentVel - (data.history[1] and data.history[1].vel or currentVel)).Magnitude
        
        if velocityChange > 8 then -- Threshold for direction change detection
            return currentVel
        end
        
        local weightedVel = Vector3.new(0, 0, 0)
        local totalWeight = 0
        
        for i, sample in ipairs(data.history) do
            local weight = i / #data.history -- More recent = higher weight
            weightedVel = weightedVel + (sample.actual * weight)
            totalWeight = totalWeight + weight
        end
        
        return weightedVel / totalWeight
    end
    
    return currentVel
end

-- Clean up velocity data when players leave
Players.PlayerRemoving:Connect(function(player)
    if targetVelocities[player] then
        targetVelocities[player] = nil
    end
end)

local function getOptimalAimPoint(target)
    if not isValidTarget(target) then
        return nil
    end
    
    local hrp = target.Character.HumanoidRootPart
    local head = target.Character:FindFirstChild("Head")
    
    local velocity = getEnhancedVelocity(target)
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local bulletSpeed = getCurrentBulletSpeed()
    
    local targetPart = head or hrp
    
    local predictedPos = getPredictedPosition(targetPart, velocity, distance, bulletSpeed)
    
    if head and distance < 150 then
        predictedPos = predictedPos + Vector3.new(0, 0.5, 0)
    end
    
    return predictedPos
end

local function smoothLook(targetPos)
    local camPos = Camera.CFrame.Position
    if useLerp then
        local currentLook = Camera.CFrame.LookVector
        local desiredLook = (targetPos - camPos).Unit
        local lerpedLook = currentLook:Lerp(desiredLook, AimbotSmoothness)
        Camera.CFrame = CFrame.new(camPos, camPos + lerpedLook)
    else
        Camera.CFrame = CFrame.new(camPos, targetPos)
    end
end

function AimbotModule.setSmooth(state)
    useLerp = state
end

function AimbotModule.toggleAimlock(state)
    aimlockEnabled = state
    if state then
        if aimlockConnection then aimlockConnection:Disconnect() end
        aimlockConnection = RunService.RenderStepped:Connect(function()
            local target = getClosestEnemyFOV()
            if target then
                local aimPoint = getOptimalAimPoint(target)
                if aimPoint then
                    smoothLook(aimPoint)
                end
            end
        end)
    else
        if aimlockConnection then aimlockConnection:Disconnect() end
    end
end

function AimbotModule.toggleNearest(state)
    nearestAimbotEnabled = state
    if state then
        if nearestConnection then nearestConnection:Disconnect() end
        nearestConnection = RunService.RenderStepped:Connect(function()
            local target = getClosestEnemyByDistance()
            if target then
                local aimPoint = getOptimalAimPoint(target)
                if aimPoint then
                    smoothLook(aimPoint)
                end
            end
        end)
    else
        if nearestConnection then nearestConnection:Disconnect() end
    end
end

function AimbotModule.toggleFOVCircle(state)
    FOVCircle.Visible = state
end

return AimbotModule
