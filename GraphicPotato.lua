local FastModeModule = {}

FastModeModule.enabled = false
FastModeModule.originalSettings = {}
FastModeModule.processedParts = {}
FastModeModule.connections = {}

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local isClient = RunService:IsClient()

local function storeOriginalSettings()
    pcall(function()
        local lighting = Lighting
        
        FastModeModule.originalSettings = {
            GlobalShadows = lighting.GlobalShadows,
            FogEnd = lighting.FogEnd,
            FogStart = lighting.FogStart,
            Brightness = lighting.Brightness,
            EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
            ShadowSoftness = lighting.ShadowSoftness,
            Technology = lighting.Technology,
            Ambient = lighting.Ambient,
            OutdoorAmbient = lighting.OutdoorAmbient
        }
        
        if isClient then
            pcall(function()
                local renderSettings = settings():GetService("RenderSettings")
                FastModeModule.originalSettings.QualityLevel = renderSettings.QualityLevel
            end)
        end
    end)
end

local bushKeywords = {"Bush", "BushLeave", "leaves", "leaf", "bushy", "bushes", "Grass"}

local function optimizePart(part)
    pcall(function()
        if not part or not part.Parent or FastModeModule.processedParts[part] then 
            return 
        end
        
        FastModeModule.processedParts[part] = {
            originalMaterial = part.Material,
            originalReflectance = part.Reflectance,
            originalCastShadow = part.CastShadow,
            originalCanCollide = part.CanCollide,
			originalTransparency = part.Transparency -- Store original transparency
        }
        
        local partNameLower = part.Name:lower()
local isBushPart = false
for _, keyword in ipairs(bushKeywords) do
	if partNameLower:find(keyword) then
		isBushPart = true
		break
	end
end

if partNameLower:find("grass") or isBushPart then
	part.Transparency = 1
	part.CanCollide = false
	part.Enabled = false
else
	if part.Material ~= Enum.Material.Air then
		part.Material = Enum.Material.Plastic
		part.Reflectance = 0
		part.CastShadow = false
	end
end
        
        for _, child in pairs(part:GetChildren()) do
            pcall(function()
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0.9
                elseif child:IsA("SurfaceGui") then
                    child.Enabled = false
                elseif child:IsA("ParticleEmitter") then
                    child.Enabled = false
                elseif child:IsA("Fire") or child:IsA("Smoke") then
                    child.Enabled = false
                elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                    child.Brightness = child.Brightness * 0.3
                elseif child:IsA("Beam") or child:IsA("Trail") then
                    child.Enabled = false
                elseif child:IsA("Explosion") then
                    child.Visible = false
                end
            end)
        end
    end)
end

local function restorePart(part)
    pcall(function()
        if not part or not part.Parent or not FastModeModule.processedParts[part] then 
            return 
        end
        
        local original = FastModeModule.processedParts[part]
        part.Material = original.originalMaterial
        part.Reflectance = original.originalReflectance
        part.CastShadow = original.originalCastShadow
		part.Transparency = original.originalTransparency -- Restore original transparency
        part.Enabled = true -- Re-enable the part

        for _, child in pairs(part:GetChildren()) do
            pcall(function()
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0
                elseif child:IsA("SurfaceGui") then
                    child.Enabled = true
                elseif child:IsA("ParticleEmitter") then
                    child.Enabled = true
                elseif child:IsA("Fire") or child:IsA("Smoke") then
                    child.Enabled = true
                elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                    child.Brightness = child.Brightness / 0.3
                elseif child:IsA("Beam") or child:IsA("Trail") then
                    child.Enabled = true
                elseif child:IsA("Explosion") then
                    child.Visible = true
                end
            end)
        end
        
        FastModeModule.processedParts[part] = nil
    end)
end

local function optimizeWorkspace(parent)
    pcall(function()
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("BasePart") then
                optimizePart(obj)
            elseif obj:IsA("Sound") then
                obj.Volume = math.max(obj.Volume * 0.4, 0.05)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            elseif obj:IsA("Explosion") then
                obj.Visible = false
            end
        end
    end)
end

function FastModeModule.enable()
    pcall(function()
        if FastModeModule.enabled then 
            return 
        end
        
        storeOriginalSettings()
        
        local lighting = Lighting
        
        if isClient then
            pcall(function()
                local renderSettings = settings():GetService("RenderSettings")
                renderSettings.QualityLevel = Enum.QualityLevel.Level01
            end)
        end
        
        lighting.GlobalShadows = false
        lighting.FogEnd = 100
        lighting.FogStart = 50
        lighting.Brightness = 1.2
        lighting.EnvironmentDiffuseScale = 0.2
        lighting.EnvironmentSpecularScale = 0.1
        lighting.ShadowSoftness = 0
        lighting.Ambient = Color3.fromRGB(100, 100, 100)
        lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
        
        pcall(function()
            lighting.Technology = Enum.Technology.Compatibility
        end)
        
        optimizeWorkspace(workspace)
        
        FastModeModule.connections.descendantAdded = workspace.DescendantAdded:Connect(function(obj)
            pcall(function()
                if obj:IsA("BasePart") then
                    task.wait(0.1) -- Use task.wait instead of wait
                    optimizePart(obj)
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                    obj.Enabled = false
                elseif obj:IsA("Sound") then
                    obj.Volume = math.max(obj.Volume * 0.4, 0.05)
                elseif obj:IsA("Explosion") then
                    obj.Visible = false
                end
            end)
        end)
        
        FastModeModule.enabled = true
        print("[Fast Mode] ENABLED - Performance optimized for mobile")
    end)
end

function FastModeModule.disable()
    pcall(function()
        if not FastModeModule.enabled then 
            return 
        end
        
        for _, connection in pairs(FastModeModule.connections) do
            pcall(function()
                if connection then
                    connection:Disconnect()
                end
            end)
        end
        FastModeModule.connections = {}
        
        if FastModeModule.originalSettings and next(FastModeModule.originalSettings) then
            local lighting = Lighting
            
            if isClient and FastModeModule.originalSettings.QualityLevel then
                pcall(function()
                    local renderSettings = settings():GetService("RenderSettings")
                    renderSettings.QualityLevel = FastModeModule.originalSettings.QualityLevel
                end)
            end
            
            lighting.GlobalShadows = FastModeModule.originalSettings.GlobalShadows
            lighting.FogEnd = FastModeModule.originalSettings.FogEnd
            lighting.FogStart = FastModeModule.originalSettings.FogStart
            lighting.Brightness = FastModeModule.originalSettings.Brightness
            lighting.EnvironmentDiffuseScale = FastModeModule.originalSettings.EnvironmentDiffuseScale
            lighting.EnvironmentSpecularScale = FastModeModule.originalSettings.EnvironmentSpecularScale
            lighting.ShadowSoftness = FastModeModule.originalSettings.ShadowSoftness
            lighting.Technology = FastModeModule.originalSettings.Technology
            lighting.Ambient = FastModeModule.originalSettings.Ambient
            lighting.OutdoorAmbient = FastModeModule.originalSettings.OutdoorAmbient
        end
        
        for part, _ in pairs(FastModeModule.processedParts) do
            restorePart(part)
        end
        
        FastModeModule.processedParts = {}
        
        FastModeModule.enabled = false
        print("[Fast Mode] DISABLED - Graphics restored to original")
    end)
end

function FastModeModule.toggle(state)
    pcall(function()
        if state then
            FastModeModule.enable()
        else
            FastModeModule.disable()
        end
    end)
end

function FastModeModule.isEnabled()
    return FastModeModule.enabled
end

function FastModeModule.cleanup()
    pcall(function()
        FastModeModule.disable()
    end)
end

if not isClient then
    game:BindToClose(function()
        FastModeModule.cleanup()
    end)
end

return FastModeModule
