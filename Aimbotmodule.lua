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

-- Updated weapon bullet speeds with more accurate values
local WeaponBulletSpeeds = {
    ["Lewis Gun"] = 2800, ["Madsen 1905"] = 2900, ["CSRG 1915"] = 2950,
    ["Doppelpistole 1912"] = 1800, ["Gewehr 98"] = 3200, ["Beholla 1915"] = 1600,
    ["Farquhar Hill P08"] = 2800, ["Karabiner 98AZ"] = 3100, ["Mannlicher 1895"] = 3200,
    ["MG 15na"] = 2725, ["MP18,-I"] = 1900, ["Selbstlader 1906"] = 3100,
    ["RSC 1917"] = 3100, ["Ribeyrolles 1918"] = 1900,
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
                return 3000 -- High velocity rifles
            elseif string.find(weaponName, "pistol") or string.find(weaponName, "beholla") then
                return 1700 -- Pistols
            elseif string.find(weaponName, "mg") or string.find(weaponName, "gun") then
                return 2700 -- Machine guns
            elseif string.find(weaponName, "mp") then
                return 1900 -- Submachine guns
            end
        end
    end
    return 2500 -- Default fallback
end

-- Improved bullet drop calculation with proper physics
local function calculateBulletDrop(distance, bulletSpeed, angle)
    local gravity = 196.2 -- Roblox gravity
    local timeToTarget = distance / bulletSpeed
    
    -- Calculate horizontal and vertical components
    local horizontalDistance = distance * math.cos(angle or 0)
    local verticalDistance = distance * math.sin(angle or 0)
    
    -- Calculate bullet drop using proper ballistic formula
    local drop = (gravity * timeToTarget * timeToTarget) / 2
    
    -- Adjust for air resistance (simplified model)
    local airResistanceFactor = 1 + (distance / 1000) * 0.1
    drop = drop * airResistanceFactor
    
    return drop
end

-- Enhanced prediction with better physics
local function getPredictedPosition(targetPart, targetVelocity, distance, bulletSpeed)
    local camPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    -- Calculate initial time to hit
    local timeToHit = distance / bulletSpeed
    
    -- Get current velocity safely
    local currentVel = Vector3.new(0, 0, 0)
    if targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        currentVel = targetPart.Parent.HumanoidRootPart.Velocity
    end
    
    -- Use enhanced velocity if available, otherwise use current velocity
    local predictionVel = targetVelocity.Magnitude > 0 and targetVelocity or currentVel
    
    -- Predict future position
    local predictedPos = targetPos + (predictionVel * timeToHit)
    
    -- Calculate angle to target for bullet drop calculation
    local direction = (predictedPos - camPos)
    local horizontalDistance = Vector3.new(direction.X, 0, direction.Z).Magnitude
    local angle = math.atan2(-direction.Y, horizontalDistance)
    
    -- Calculate bullet drop
    local bulletDrop = calculateBulletDrop(distance, bulletSpeed, angle)
    
    -- Apply bullet drop compensation
    predictedPos = predictedPos + Vector3.new(0, bulletDrop, 0)
    
    -- Iterative refinement for better accuracy (especially at long range)
    for i = 1, 3 do
        local newDirection = (predictedPos - camPos)
        local newDistance = newDirection.Magnitude
        local newTimeToHit = newDistance / bulletSpeed
        local newAngle = math.atan2(-newDirection.Y, Vector3.new(newDirection.X, 0, newDirection.Z).Magnitude)
        
        -- Recalculate with refined values
        predictedPos = targetPos + (predictionVel * newTimeToHit)
        local refinedDrop = calculateBulletDrop(newDistance, bulletSpeed, newAngle)
        predictedPos = predictedPos + Vector3.new(0, refinedDrop, 0)
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

-- Improved aim point calculation with distance-based targeting
local function getOptimalAimPoint(target)
    if not isValidTarget(target) then
        return nil
    end
    
    local hrp = target.Character.HumanoidRootPart
    local head = target.Character:FindFirstChild("Head")
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    
    local velocity = getEnhancedVelocity(target)
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local bulletSpeed = getCurrentBulletSpeed()
    
    -- Choose target point based on distance and weapon type
    local targetPart = hrp -- Default to body
    local aimOffset = Vector3.new(0, 0, 0)
    
    if head then
        if distance < 100 then
            -- Close range: aim for head
            targetPart = head
            aimOffset = Vector3.new(0, 0.2, 0) -- Slight upward offset
        elseif distance < 300 then
            -- Medium range: aim for upper torso/neck area
            targetPart = hrp
            aimOffset = Vector3.new(0, 1.2, 0) -- Chest/neck level
        else
            -- Long range: aim for center mass with slight upward bias
            targetPart = hrp
            aimOffset = Vector3.new(0, 0.8, 0) -- Upper torso
        end
    end
    
    -- Get predicted position
    local predictedPos = getPredictedPosition(targetPart, velocity, distance, bulletSpeed)
    
    -- Apply aim offset
    predictedPos = predictedPos + aimOffset
    
    -- Additional compensation for moving targets at long range
    if distance > 400 and velocity.Magnitude > 5 then
        local extraLead = velocity.Unit * (distance / bulletSpeed) * 0.3
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
