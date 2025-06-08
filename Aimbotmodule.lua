local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 50
local AimbotRange = 600
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

-- Visibility check unchanged
local function isVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local targetSize = targetPart.Size
    
    local testPoints = {
        targetPos,
        targetPos + Vector3.new(targetSize.X/3, 0, 0),
        targetPos - Vector3.new(targetSize.X/3, 0, 0),
        targetPos + Vector3.new(0, targetSize.Y/3, 0),
        targetPos - Vector3.new(0, targetSize.Y/3, 0),
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
                return 2400
            elseif string.find(weaponName, "pistol") or string.find(weaponName, "beholla") then
                return 1100
            elseif string.find(weaponName, "mg") or string.find(weaponName, "gun") then
                return 2100
            elseif string.find(weaponName, "mp") then
                return 1300
            end
        end
    end
    return 2000
end

local function calculateBulletDrop(distance, bulletSpeed)
    local timeToTarget = distance / bulletSpeed
    
    if distance > 500 then
        local minimalDrop = (distance - 500) / 200
        return math.min(minimalDrop, 3)
    end
    
    return 0
end

local targetVelocities = {}

local function getEnhancedVelocity(player)
    if not isValidTarget(player) then
        return Vector3.new(0,0,0)
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
    
    if deltaTime > 0.01 then
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
            local weightedVel = Vector3.new(0,0,0)
            
            for i, sample in ipairs(data.history) do
                local weight = i * i
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

-- New function to calculate intercept point between moving target and bullet
local function calculateIntercept(shooterPos, targetPos, targetVel, projectileSpeed)
    local displacement = targetPos - shooterPos
    local velocity = targetVel
    
    local a = velocity:Dot(velocity) - projectileSpeed * projectileSpeed
    local b = 2 * velocity:Dot(displacement)
    local c = displacement:Dot(displacement)
    
    local discriminant = b * b - 4 * a * c
    
    if discriminant < 0 or math.abs(a) < 0.001 then
        -- Cannot solve for intercept, fallback to direct shot
        local time = displacement.Magnitude / projectileSpeed
        return targetPos + velocity * time
    else
        local sqrtDisc = math.sqrt(discriminant)
        local t1 = (-b + sqrtDisc) / (2 * a)
        local t2 = (-b - sqrtDisc) / (2 * a)
        
        local t = math.min(t1, t2)
        if t < 0 then
            t = math.max(t1, t2)
        end
        
        if t < 0 then
            -- Both times negative, aim at current position + velocity*time as fallback
            t = 0
        end
        
        return targetPos + velocity * t
    end
end

local function getOptimalAimPoint(target)
    if not isValidTarget(target) then
        return nil
    end
    
    local hrp = target.Character.HumanoidRootPart
    local head = target.Character:FindFirstChild("Head")
    
    local velocity = getEnhancedVelocity(target)
    local shooterPos = Camera.CFrame.Position
    local bulletSpeed = getCurrentBulletSpeed()
    local targetPos = hrp.Position
    
    local distance = (shooterPos - targetPos).Magnitude
    
    local aimOffset = Vector3.new(0,0,0)
    if head then
        if distance < 150 then
            targetPos = head.Position
        elseif distance < 350 then
            aimOffset = Vector3.new(0, 1.0, 0)
        else
            aimOffset = Vector3.new(0, 0.5, 0)
        end
    end
    
    -- Use intercept calculation for precise aiming against moving targets
    local predictedPos = calculateIntercept(shooterPos, targetPos, velocity, bulletSpeed)
    
    -- Add aim offset after prediction
    predictedPos = predictedPos + aimOffset
    
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
