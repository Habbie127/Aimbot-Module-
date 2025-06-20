local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 50
local AimbotRange = 600
local AimbotSmoothness = 0.2
local TargetLockDuration = 0.3
local useLerp = true
local visibilityCheckEnabled = true
local aimTargetMode = "Auto"

local aimlockEnabled = false
local nearestAimbotEnabled = false
local targetLocked = nil
local lastTargetTime = 0
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

local function isBush(part)
    if not part or not part:IsA("BasePart") then return false end
    local bushNames = {
        ["Bush"] = true,
        ["BushLeave"] = true,
        ["Bushes"] = true
    }
    return bushNames[part.Name] == true or (part.Parent and bushNames[part.Parent.Name] == true)
end

local function isVisible(targetPart)
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local origin = Camera.CFrame.Position  
    local targetPos = targetPart.Position  
    
    local rayParams = RaycastParams.new()  
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist  
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}  
    rayParams.IgnoreWater = true  
    
    local direction = (targetPos - origin).Unit  
    local distance = (targetPos - origin).Magnitude  
    local result = workspace:Raycast(origin, direction * distance, rayParams)  
    
    if not result then  
        return true  
    end  
    
    local hitPart = result.Instance  
    
    if hitPart:IsA("Terrain") or (hitPart.CanCollide and hitPart.Transparency < 0.7) then  
        return false  -- Blocked by terrain or solid object  
    end  
    
    if isBush(hitPart) then  
        return true   
    end  
    
    return false
end

local function isValidTarget(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function getClosestEnemyByDistance()
    local closest, shortestDistance = nil, AimbotRange
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            if not visibilityCheckEnabled or isVisible(hrp) then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = player
                end
            end
        end
    end
    
    if closest == nil and targetLocked and tick() - lastTargetTime < TargetLockDuration then
        if isValidTarget(targetLocked) then
            return targetLocked
        end
    end
    
    return closest
end

local function getClosestEnemyFOV()
    local closest, minDist = nil, FOVRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            if not visibilityCheckEnabled or isVisible(hrp) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    if closest == nil and targetLocked and tick() - lastTargetTime < TargetLockDuration then
        if isValidTarget(targetLocked) then
            return targetLocked
        end
    end
    
    return closest
end

local WeaponBulletSpeeds = {
    ["Lewis Gun"] = 3300, ["Madsen 1905"] = 3400, ["CSRG 1915"] = 3450,
    ["Doppelpistole 1912"] = 2400, ["Gewehr 98"] = 4200, ["Beholla 1915"] = 2200,
    ["Farquhar Hill P08"] = 3500, ["Karabiner 98AZ"] = 3600, ["Mannlicher 1895"] = 4200,
    ["MG 15na"] = 3225, ["MP18,-I"] = 1300, ["Selbstlader 1906"] = 3600,
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
    if distance > 500 then
        return math.min((distance - 500) / 200, 3)
    end
    return 0
end

local targetVelocities = {}

Players.PlayerRemoving:Connect(function(player)
    targetVelocities[player] = nil
end)

local function getEnhancedVelocity(player)
    if not isValidTarget(player) then return Vector3.zero end
    local hrp = player.Character.HumanoidRootPart
    local currentVel = hrp.Velocity
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    
    if not targetVelocities[player] then  
        targetVelocities[player] = {  
            history = {},  
            lastPos = hrp.Position,  
            lastTime = tick(),  
            smoothedVel = currentVel,
            movementState = humanoid:GetState()
        }  
    end  
    
    local data = targetVelocities[player]
    local now = tick()
    local dt = now - data.lastTime
    local newMovementState = humanoid:GetState()
    
    if newMovementState ~= data.movementState or dt > 0.5 then
        data.history = {}
        data.smoothedVel = currentVel
    end
    data.movementState = newMovementState
    
    if dt > 0.01 then  
        local deltaPos = hrp.Position - data.lastPos  
        local calcVel = deltaPos / dt
        
        table.insert(data.history, {vel = currentVel, calculated = calcVel, time = now})  
        
        while #data.history > 0 and (now - data.history[1].time) > 0.3 do
            table.remove(data.history, 1)
        end
        
        local weighted = Vector3.zero  
        local totalWeight = 0  
        for i, sample in ipairs(data.history) do  
            local w = (1 + i) ^ 2 
            weighted += sample.calculated * w  
            totalWeight += w  
        end  
        
        if totalWeight > 0 then
            data.smoothedVel = (weighted / totalWeight)
            data.smoothedVel = Vector3.new(data.smoothedVel.X, 0, data.smoothedVel.Z)
        end
        
        if #data.history > 2 then
            local momentum = data.smoothedVel:Dot(data.history[#data.history].calculated)
            if momentum < 0 then
                data.smoothedVel = data.smoothedVel * 0.5
            end
        end
        
        data.lastPos = hrp.Position  
        data.lastTime = now  
    end  
    
    return data.smoothedVel
end

local function getPredictedPosition(targetPart, targetVelocity, distance, bulletSpeed)
    local origin = Camera.CFrame.Position
    local toTarget = targetPart.Position - origin

    local a = targetVelocity:Dot(targetVelocity) - bulletSpeed^2  
    local b = 2 * toTarget:Dot(targetVelocity)  
    local c = toTarget:Dot(toTarget)  

    local discriminant = b * b - 4 * a * c  

    if discriminant < 0 or math.abs(a) < 1e-6 then  
        local time = toTarget.Magnitude / bulletSpeed  
        local latencyCompensation = math.clamp(time * 0.2, 0.03, 0.15)  
        return targetPart.Position + targetVelocity * (time + latencyCompensation)  
    end  

    local sqrtDisc = math.sqrt(discriminant)  
    local t1 = (-b - sqrtDisc) / (2 * a)  
    local t2 = (-b + sqrtDisc) / (2 * a)  

    local hitTime = math.max(math.min(t1, t2), 0) or 0

    local predicted = targetPart.Position + targetVelocity * hitTime
    local latencyCompensation = math.clamp(hitTime * 0.3, 0.02, 0.2)  
    predicted = predicted + targetVelocity * latencyCompensation  

    local drop = calculateBulletDrop(distance, bulletSpeed)  
    return predicted - Vector3.new(0, drop, 0)
end

local function getOptimalAimPoint(target)
    if not isValidTarget(target) then return nil end

    local hrp = target.Character.HumanoidRootPart  
    local head = target.Character:FindFirstChild("Head")  
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude  
    local bulletSpeed = getCurrentBulletSpeed()  
    
    local velocity = getEnhancedVelocity(target)
    
    local targetPart = hrp
    local aimOffset = Vector3.zero  

    if aimTargetMode == "Head" and head then  
        targetPart = head  
    elseif aimTargetMode == "Body" then  
        targetPart = hrp  
    elseif aimTargetMode == "Auto" then  
        if head and distance < 150 then  
            targetPart = head  
        elseif distance < 350 then  
            local targetCharacter = target.Character
            local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        
            if humanoid and math.abs(targetPart.Position.Y - Camera.CFrame.Position.Y) < 5 then
                local torso = targetCharacter:FindFirstChild("UpperTorso") or targetCharacter:FindFirstChild("Torso")
                if torso then
                    aimOffset = Vector3.new(0, 0.8, 0) 
                else
                    aimOffset = Vector3.new(0, 1.2, 0)  
                end
            end
        else  
            aimOffset = Vector3.new(0, 0.5, 0)  -- Center mass for long range
        end  
    end  

    local predicted = getPredictedPosition(targetPart, velocity, distance, bulletSpeed)  
    return predicted + aimOffset
end

local lastAimPosition = nil
local function smoothLook(targetPos, dt)
    local camPos = Camera.CFrame.Position
    local currentLook = Camera.CFrame.LookVector
    local desiredLook = (targetPos - camPos).Unit
    
    if lastAimPosition then
        local posChange = (targetPos - lastAimPosition)
        local moveSpeed = posChange.Magnitude / math.max(dt, 0.01)
        
        if moveSpeed > 100 then
            desiredLook = (targetPos + posChange.Unit * 0.1 - camPos).Unit
        end
    end
    
    local finalLook
    if useLerp then
        local smoothFactor = AimbotSmoothness
        local distance = (targetPos - camPos).Magnitude
        if distance < 100 then
            smoothFactor = math.min(AimbotSmoothness * 1.5, 1)
        elseif distance > 300 then
            smoothFactor = math.max(AimbotSmoothness * 0.7, 0.05)
        end
        
        finalLook = currentLook:Lerp(desiredLook, smoothFactor)
    else
        finalLook = desiredLook
    end
    
    Camera.CFrame = CFrame.new(camPos, camPos + finalLook)
    lastAimPosition = targetPos
end

function AimbotModule.toggleAimlock(state)
    aimlockEnabled = state
    if state then
        if aimlockConnection then aimlockConnection:Disconnect() end
        aimlockConnection = RunService.RenderStepped:Connect(function(dt)
            local target = getClosestEnemyFOV()
            if target then
                targetLocked = target
                lastTargetTime = tick()
                local aim = getOptimalAimPoint(target)
                if aim then 
                    smoothLook(aim, dt) 
                end
            elseif tick() - lastTargetTime > TargetLockDuration then
                targetLocked = nil
            end
        end)
    else
        if aimlockConnection then aimlockConnection:Disconnect() end
        targetLocked = nil
    end
end

function AimbotModule.toggleNearest(state)
    nearestAimbotEnabled = state
    if state then
        if nearestConnection then nearestConnection:Disconnect() end
        lastTargetTime = tick()
        nearestConnection = RunService.RenderStepped:Connect(function(dt)
            local target = getClosestEnemyByDistance()
            if target then
                targetLocked = target
                lastTargetTime = tick()
                local aim = getOptimalAimPoint(target)
                if aim then 
                    smoothLook(aim, dt) 
                end
            elseif tick() - lastTargetTime > TargetLockDuration then
                targetLocked = nil
            end
        end)
    else
        if nearestConnection then nearestConnection:Disconnect() end
        targetLocked = nil
    end
end

function AimbotModule.setSmooth(state)
    useLerp = state
end

function AimbotModule.setVisibilityCheck(state)
    visibilityCheckEnabled = state
end

function AimbotModule.setAimTargetMode(mode)
    if mode == "Head" or mode == "Body" or mode == "Auto" then
        aimTargetMode = mode
    end
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

function AimbotModule.toggleFOVCircle(state)
    FOVCircle.Visible = state
end

function AimbotModule.getDebugInfo()
    local target = targetLocked or getClosestEnemyFOV() or getClosestEnemyByDistance()
    if target then
        local dist = (Camera.CFrame.Position - target.Character.HumanoidRootPart.Position).Magnitude
        local vel = getEnhancedVelocity(target)
        local bulletSpeed = getCurrentBulletSpeed()
        return {
            targetName = target.Name,
            distance = math.floor(dist),
            velocity = vel,
            bulletSpeed = bulletSpeed,
            locked = target == targetLocked,
            aimPoint = getOptimalAimPoint(target)
        }
    end
    return nil
end

return AimbotModule
