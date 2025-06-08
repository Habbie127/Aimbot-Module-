local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 50
local AimbotRange = 600 -- Increased range to match your needs
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

-- More realistic bullet speeds for WW1 weapons (reduced from previous values)
local WeaponBulletSpeeds = {
    ["Lewis Gun"] = 2200, ["Madsen 1905"] = 2300, ["CSRG 1915"] = 2350,
    ["Doppelpistole 1912"] = 1200, ["Gewehr 98"] = 2600, ["Beholla 1915"] = 1000,
    ["Farquhar Hill P08"] = 2200, ["Karabiner 98AZ"] = 2500, ["Mannlicher 1895"] = 2600,
    ["MG 15na"] = 2125, ["MP18,-I"] = 1300, ["Selbstlader 1906"] = 2500,
    ["RSC 1917"] = 2500, ["Ribeyrolles 1918"] = 1300,
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
                return 2400 -- High velocity rifles
            elseif string.find(weaponName, "pistol") or string.find(weaponName, "beholla") then
                return 1100 -- Pistols
            elseif string.find(weaponName, "mg") or string.find(weaponName, "gun") then
                return 2100 -- Machine guns
            elseif string.find(weaponName, "mp") then
                return 1300 -- Submachine guns
            end
        end
    end
    return 2000 -- Default fallback (reduced)
end

-- Simplified bullet drop calculation - many games don't simulate realistic bullet drop
local function calculateBulletDrop(distance, bulletSpeed)
    -- Most arcade-style WW1 games have minimal or no bullet drop
    -- Only apply very slight drop for extreme distances
    local timeToTarget = distance / bulletSpeed
    
    if distance > 500 then
        -- Very minimal drop only for extreme range
        local minimalDrop = (distance - 500) / 200 -- 1 stud drop per 200 studs past 500
        return math.min(minimalDrop, 3) -- Cap at 3 studs maximum
    end
    
    return 0 -- No bullet drop for most ranges
end

-- Simplified prediction focused on movement, not bullet drop
local function getPredictedPosition(targetPart, targetVelocity, distance, bulletSpeed)
    local targetPos = targetPart.Position
    
    -- Calculate time to hit target
    local timeToHit = distance / bulletSpeed
    
    -- Get current velocity safely
    local currentVel = Vector3.new(0, 0, 0)
    if targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        currentVel = targetPart.Parent.HumanoidRootPart.Velocity
    end
    
    -- Use the better velocity prediction
    local predictionVel = targetVelocity.Magnitude > 0 and targetVelocity or currentVel
    
    -- Predict future position based on movement only
    local predictedPos = targetPos + (predictionVel * timeToHit)
    
    -- Apply minimal bullet drop only for extreme distances
    local bulletDrop = calculateBulletDrop(distance, bulletSpeed)
    if bulletDrop > 0 then
        predictedPos = predictedPos - Vector3.new(0, bulletDrop, 0) -- SUBTRACT for drop
    end
    
    -- Simple refinement iteration
    local newDistance = (Camera.CFrame.Position - predictedPos).Magnitude
    local newTimeToHit = newDistance / bulletSpeed
    predictedPos = targetPos + (predictionVel * newTimeToHit)
    
    -- Reapply minimal drop
    local finalDrop = calculateBulletDrop(newDistance, bulletSpeed)
    if finalDrop > 0 then
        predictedPos = predictedPos - Vector3.new(0, finalDrop, 0)
    end
    
    return predictedPos
end

local targetVelocities = {} -- Store velocity history

-- Enhanced velocity calculation with better smoothing
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
            lastTime = tick(),
            smoothedVel = currentVel
        }
    end
    
    local data = targetVelocities[player]
    local currentTime = tick()
    local deltaTime = currentTime - data.lastTime
    
    if deltaTime > 0.01 then -- Minimum time threshold
        local positionDelta = hrp.Position - data.lastPos
        local calculatedVel = positionDelta / deltaTime
        
        -- Add to history
        table.insert(data.history, {
            vel = currentVel,
            calculated = calculatedVel,
            time = currentTime
        })
        
        -- Keep only recent history
        if #data.history > 5 then
            table.remove(data.history, 1)
        end
        
        -- Calculate weighted average
        if #data.history >= 2 then
            local totalWeight = 0
            local weightedVel = Vector3.new(0, 0, 0)
            
            for i, sample in ipairs(data.history) do
                local weight = i * i -- Quadratic weighting for more recent samples
                weightedVel = weightedVel + (sample.calculated * weight)
                totalWeight = totalWeight + weight
            end
            
            data.smoothedVel = weightedVel / totalWeight
        else
            data.smoothedVel = currentVel
        end
        
        data.lastPos = hrp.Position
        data.lastTime = currentTime
    end
    
    return data.smoothedVel
end

-- Clean up velocity data when players leave
Players.PlayerRemoving:Connect(function(player)
    if targetVelocities[player] then
        targetVelocities[player] = nil
    end
end)

-- Simplified aim point calculation focused on direct hits
local function getOptimalAimPoint(target)
    if not isValidTarget(target) then
        return nil
    end
    
    local hrp = target.Character.HumanoidRootPart
    local head = target.Character:FindFirstChild("Head")
    
    local velocity = getEnhancedVelocity(target)
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local bulletSpeed = getCurrentBulletSpeed()
    
    -- Choose target point based on distance
    local targetPart = hrp -- Default to body center
    local aimOffset = Vector3.new(0, 0, 0)
    
    if head then
        if distance < 150 then
            -- Close range: aim for head
            targetPart = head
        elseif distance < 350 then
            -- Medium range: aim for upper chest/neck
            targetPart = hrp
            aimOffset = Vector3.new(0, 1.0, 0) -- Chest level
        else
            -- Long range: aim for center mass
            targetPart = hrp
            aimOffset = Vector3.new(0, 0.5, 0) -- Slightly above center
        end
    end
    
    -- Get predicted position (now without excessive bullet drop)
    local predictedPos = getPredictedPosition(targetPart, velocity, distance, bulletSpeed)
    
    -- Apply aim offset
    predictedPos = predictedPos + aimOffset
    
    -- For very long range moving targets, add slight extra lead
    if distance > 450 and velocity.Magnitude > 8 then
        local extraLead = velocity.Unit * (distance / bulletSpeed) * 0.15
        predictedPos = predictedPos + extraLead
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

-- Configuration functions
function AimbotModule.setSmooth(state)
    useLerp = state
end

function AimbotModule.setSmoothness(value)
    AimbotSmoothness = math.clamp(value, 0.01, 1)
end

function AimbotModule.setRange(range)
    AimbotRange = math.max(range, 50)
end

function AimbotModule.setFOVRadius(radius)
    FOVRadius = math.max(radius, 10)
    FOVCircle.Size = UDim2.fromOffset(FOVRadius * 2, FOVRadius * 2)
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

-- Debug function to get current target info
function AimbotModule.getDebugInfo()
    local target = getClosestEnemyFOV() or getClosestEnemyByDistance()
    if target then
        local distance = (Camera.CFrame.Position - target.Character.HumanoidRootPart.Position).Magnitude
        local velocity = getEnhancedVelocity(target)
        local bulletSpeed = getCurrentBulletSpeed()
        
        return {
            targetName = target.Name,
            distance = math.floor(distance),
            velocity = velocity,
            bulletSpeed = bulletSpeed,
            aimPoint = getOptimalAimPoint(target)
        }
    end
    return nil
end

return AimbotModule
