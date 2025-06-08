local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AimbotRange = 600
local AimbotSmoothness = 0.1
local useLerp = false
local aimlockEnabled = false
local nearestEnabled = false

local FOVRadius = 50
local FOVGui = Instance.new("ScreenGui", game.CoreGui)
FOVGui.Name = "FOVCircleGui"
FOVGui.ResetOnSpawn = false

local FOVCircle = Instance.new("Frame", FOVGui)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.4)
FOVCircle.Size = UDim2.fromOffset(FOVRadius * 2, FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false

Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local FOVOutline = Instance.new("UIStroke", FOVCircle)
FOVOutline.Thickness = 1
FOVOutline.Color = Color3.fromRGB(0, 255, 0)

-- Bullet speeds per weapon
local WeaponBulletSpeeds = {
    ["Lewis Gun"] = 3300, ["Madsen 1905"] = 3400, ["CSRG 1915"] = 3450,
    ["Doppelpistole 1912"] = 1200, ["Gewehr 98"] = 4200, ["Beholla 1915"] = 2200,
    ["Farquhar Hill P08"] = 3500, ["Karabiner 98AZ"] = 3600, ["Mannlicher 1895"] = 3900,
    ["MG 15na"] = 3225, ["MP18,-I"] = 2600, ["Selbstlader 1906"] = 3600,
    ["RSC 1917"] = 3600, ["Ribeyrolles 1918"] = 2600, ["Mosin 1891"] = 4200, 
    ["Enfield P1914"] = 4200, ["Lebel 1886/93"] = 3900, ["Luger P08"] = 2500, 
    ["Steyr Hahn 1912"] = 2250, ["St. Etienne 1892"] = 2400, ["Webley Mk VI"] = 2300, 
    ["Mannlicher 1895 Stutzen"] = 3600, ["Berthier 1892/16"] = 3600, ["SMLE Mk III"] = 3500, 
    ["Huot Automatic Rifle"] = 2700, ["Repetierpistole 1912/16"] = 2250, 
    ["Hellriegel 1915"] = 2500, ["Fedorov Avtomat"] = 2600, ["Mauser 1914"] = 2200, 
    ["Ruby 1915"] = 2200, ["Webley & Scott 1913"] = 2200, ["Frommer Stop 1912"] = 2200, 
}

-- Get current bullet speed
local function getCurrentBulletSpeed()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return 2300 end
    return WeaponBulletSpeeds[tool.Name] or 2300
end

-- Check if player is valid target
local function isValidTarget(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end
    return true
end

-- Visibility check
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(origin, (part.Position - origin), RaycastParams.new {
        FilterType = Enum.RaycastFilterType.Blacklist,
        FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    })
    return not result
end

-- Velocity Smoothing
local targetVelocities = {}

local function getEnhancedVelocity(player)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.zero end

    local data = targetVelocities[player]
    if not data then
        targetVelocities[player] = {
            lastPos = hrp.Position,
            lastTime = tick(),
            smoothedVel = hrp.Velocity,
            history = {},
        }
        return hrp.Velocity
    end

    local now = tick()
    local dt = now - data.lastTime
    if dt > 0.01 then
        local delta = hrp.Position - data.lastPos
        local vel = delta / dt
        table.insert(data.history, vel)
        if #data.history > 5 then table.remove(data.history, 1) end

        local sum = Vector3.zero
        for _, v in ipairs(data.history) do sum += v end
        data.smoothedVel = sum / #data.history

        data.lastPos = hrp.Position
        data.lastTime = now
    end

    return data.smoothedVel
end

Players.PlayerRemoving:Connect(function(p)
    targetVelocities[p] = nil
end)

-- No gravity drop: Intercept only
local function calculateIntercept(shooter, targetPos, velocity, speed)
    local displacement = targetPos - shooter
    local a = velocity:Dot(velocity) - speed * speed
    local b = 2 * velocity:Dot(displacement)
    local c = displacement:Dot(displacement)
    local disc = b*b - 4*a*c

    if disc < 0 or math.abs(a) < 0.001 then
        local t = displacement.Magnitude / speed
        return targetPos + velocity * t
    end

    local t1 = (-b + math.sqrt(disc)) / (2*a)
    local t2 = (-b - math.sqrt(disc)) / (2*a)
    local t = math.min(t1, t2)
    if t < 0 then t = math.max(t1, t2) end
    return targetPos + velocity * t
end

local function getOptimalAimPoint(target)
    if not isValidTarget(target) then return end
    local hrp = target.Character.HumanoidRootPart
    local velocity = getEnhancedVelocity(target)
    local shooter = Camera.CFrame.Position
    local speed = getCurrentBulletSpeed()
    return calculateIntercept(shooter, hrp.Position, velocity, speed)
end

-- Get closest target in FOV
local function getClosestFOVTarget()
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, minDist = nil, FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            if isVisible(hrp) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < minDist then
                        closest = player
                        minDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- Get nearest by distance
local function getClosestByDistance()
    local closest, shortest = nil, AimbotRange
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            if isVisible(hrp) then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist < shortest then
                    closest = player
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- Aim camera smoothly
local function smoothLook(pos)
    local origin = Camera.CFrame.Position
    local dir = (pos - origin).Unit
    if useLerp then
        local current = Camera.CFrame.LookVector
        local newDir = current:Lerp(dir, AimbotSmoothness)
        Camera.CFrame = CFrame.new(origin, origin + newDir)
    else
        Camera.CFrame = CFrame.new(origin, origin + dir)
    end
end

-- Main toggle logic
local aimlockConnection = nil
function AimbotModule.toggleAimlock(state)
    aimlockEnabled = state
    if aimlockConnection then aimlockConnection:Disconnect() end
    if state then
        aimlockConnection = RunService.RenderStepped:Connect(function()
            local target = getClosestFOVTarget()
            if target then
                local aim = getOptimalAimPoint(target)
                if aim then smoothLook(aim) end
            end
        end)
    end
end

local nearestConnection = nil
function AimbotModule.toggleNearest(state)
    nearestEnabled = state
    if nearestConnection then nearestConnection:Disconnect() end
    if state then
        nearestConnection = RunService.RenderStepped:Connect(function()
            local target = getClosestByDistance()
            if target then
                local aim = getOptimalAimPoint(target)
                if aim then smoothLook(aim) end
            end
        end)
    end
end

function AimbotModule.setFOVRadius(radius)
    FOVRadius = radius
    FOVCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
end

function AimbotModule.toggleFOVCircle(state)
    FOVCircle.Visible = state
end

function AimbotModule.setSmooth(state)
    useLerp = state
end

function AimbotModule.setSmoothness(val)
    AimbotSmoothness = math.clamp(val, 0.01, 1)
end

function AimbotModule.setRange(val)
    AimbotRange = val
end

return AimbotModule
