local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 60
local AimbotRange = 600 -- Increased range to match your needs
local AimbotSmoothness = 0.3
local useLerp = false
local visibilityCheckEnabled = false

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

local function isVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local targetSize = targetPart.Size
    
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
        
        if not result or
        result.Instance.Transparency > 0.5
        then
		        visiblePoints += 1
		end
    end
    
    return (visiblePoints / totalPoints) >= 0.4
end

local function isValidTarget(player)
    if not player or player == LocalPlayer then
        return false
    end
    
    if not player.Character then
        return false
    end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        return false
    end
    
    local success, health = pcall(function()
        return humanoid.Health
    end)
    
    if not success or health <= 0 then
        return false
    end
    
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
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
            local visible = (not visibilityCheckEnabled) or isVisible(hrp)

            if visible then
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
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
            local visible = (not visibilityCheckEnabled) or isVisible(hrp)

            if visible then
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
    ["MG 15na"] = 3225, ["Selbstlader 1906"] = 3600,
    ["RSC 1917"] = 3600, ["Ribeyrolles 1918"] = 2600, ["Lebel 1886/93"] = 3900, 
    ["Enfield P1914"] = 4200, ["Mosin 1891"] = 4200, ["Mannlicher 1895 Stutzen"] = 3600, 
    ["Berthier 1892/16"] = 3600, ["SMLE Mk III"] = 3500, ["MP18,-I"] = 2600, 
    ["Steyr Hahn 1912"] = 2250, ["Huot Automatic Rifle"] = 2700, ["Fedorov Avtomat"] = 2600, 
    ["Repetierpistole 1912/16"] = 2250, ["Mauser 1914"] = 2200, ["Ruby 1915"] = 2200, 
    ["Webley & Scott 1913"] = 2200, ["Frommer Stop 1912"] = 2200, ["Mannlicher 1895 Scoped"] = 3900, 
    ["Enfield P1914 Scoped"] = 4200, ["Luger P08"] = 2250, ["St. Etienne 1892"] = 2400, 
}

local function getCurrentBulletSpeed()
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            return WeaponBulletSpeeds[tool.Name] or 2400
        end
    end
    return 2400
end

local function calculateBulletDrop(distance, bulletSpeed)
    local timeToTarget = distance / bulletSpeed
    
    if distance > 500 then
        local minimalDrop = (distance - 500) / 200 -- 1 stud drop per 200 studs past 500
        return math.min(minimalDrop, 3) -- Cap at 3 studs maximum
    end
    
    return 0 -- No bullet drop for most ranges
end

local function getPredictedPosition(targetPart, targetVelocity, distance, bulletSpeed)
    local targetPos = targetPart.Position
    
    local timeToHit = distance / bulletSpeed
    
    local currentVel = Vector3.new(0, 0, 0)
    if targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        currentVel = targetPart.Parent.HumanoidRootPart.Velocity
    end
    
    local predictionVel = targetVelocity.Magnitude > 0 and targetVelocity or currentVel
    
    local predictedPos = targetPos + (predictionVel * timeToHit)
    
    local bulletDrop = calculateBulletDrop(distance, bulletSpeed)
    if bulletDrop > 0 then
        predictedPos = predictedPos - Vector3.new(0, bulletDrop, 0) -- SUBTRACT for drop
    end
    
    local newDistance = (Camera.CFrame.Position - predictedPos).Magnitude
    local newTimeToHit = newDistance / bulletSpeed
    predictedPos = targetPos + (predictionVel * newTimeToHit)
    
    local finalDrop = calculateBulletDrop(newDistance, bulletSpeed)
    if finalDrop > 0 then
        predictedPos = predictedPos - Vector3.new(0, finalDrop, 0)
    end
    
    return predictedPos
end

local targetVelocities = {}

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
        
        table.insert(data.history, {
            vel = currentVel,
            calculated = calculatedVel,
            time = currentTime
        })
        
        if #data.history > 5 then
            table.remove(data.history, 1)
        end
        
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

Players.PlayerRemoving:Connect(function(player)
    if targetVelocities[player] then
        targetVelocities[player] = nil
    end
end)

local function solveBallisticArc(shooterPos, targetPos, targetVel, bulletSpeed, gravity)
    local displacement = targetPos - shooterPos
    local targetVelXZ = Vector3.new(targetVel.X, 0, targetVel.Z)
    local displacementXZ = Vector3.new(displacement.X, 0, displacement.Z)
    local horizontalDistance = displacementXZ.Magnitude

    local relativeVelocity = targetVelXZ
    local timeGuess = horizontalDistance / bulletSpeed

    local predictedTargetPos = targetPos + targetVel * timeGuess
    local displacementNew = predictedTargetPos - shooterPos
    local dx = Vector3.new(displacementNew.X, 0, displacementNew.Z).Magnitude
    local dy = displacementNew.Y
    local g = gravity
    local v = bulletSpeed

    local root = v^4 - g * (g * dx^2 + 2 * dy * v^2)

    if root < 0 then
        return predictedTargetPos -- fallback: just aim ahead
    end

    local angle = math.atan((v^2 - math.sqrt(root)) / (g * dx))
    local time = dx / (v * math.cos(angle))

    return targetPos + targetVel * time - Vector3.new(0, 0.5 * g * time * time, 0)
end

local function getOptimalAimPoint(target)
    if not isValidTarget(target) then return nil end

    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local head = target.Character:FindFirstChild("Head")
    if not hrp then return nil end

    local shooterPos = Camera.CFrame.Position
    local bulletSpeed = getCurrentBulletSpeed()
    local gravity = workspace.Gravity
    local velocity = getEnhancedVelocity(target)

    local aimPart = hrp
    local distance = (shooterPos - hrp.Position).Magnitude

    if head and distance < 150 then
        aimPart = head
    end

    return solveBallisticArc(shooterPos, aimPart.Position, velocity, bulletSpeed, gravity)
end

local function smoothLook(targetPos)
    local camPos = Camera.CFrame.Position
    local currentLook = Camera.CFrame.LookVector
    local desiredLook = (targetPos - camPos).Unit
    local angleDiff = math.acos(math.clamp(currentLook:Dot(desiredLook), -1, 1))

    local lerpAlpha = math.clamp(angleDiff / math.rad(45), 0.1, 1) * AimbotSmoothness

    if useLerp then
        local lerpedLook = currentLook:Lerp(desiredLook, lerpAlpha)
        Camera.CFrame = CFrame.new(camPos, camPos + lerpedLook)
    else
        Camera.CFrame = CFrame.new(camPos, targetPos)
    end
end

function AimbotModule.setSmooth(state)
    useLerp = state
end

function AimbotModule.setVisibilityCheck(state)
    visibilityCheckEnabled = state
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
        if aimlockConnection then aimlockConnection:Disconnect(); aimlockConnection = nil end
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
