local FastModeModule = {}

FastModeModule.enabled = false
FastModeModule.originalSettings = {}
FastModeModule.processedParts = {}
FastModeModule.connections = {}

local function storeOriginalSettings()
    pcall(function()
        local renderSettings = settings():GetService("RenderSettings")
        local lighting = game:GetService("Lighting")
        
        FastModeModule.originalSettings = {
            QualityLevel = renderSettings.QualityLevel,
            GlobalShadows = lighting.GlobalShadows,
            FogEnd = lighting.FogEnd,
            FogStart = lighting.FogStart,
            Brightness = lighting.Brightness,
            EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
            ShadowSoftness = lighting.ShadowSoftness,
            Technology = lighting.Technology
        }
    end)
end

local function optimizePart(part)
    pcall(function()
        if not part or not part.Parent or FastModeModule.processedParts[part] then 
            return 
        end
        
        FastModeModule.processedParts[part] = {
            originalMaterial = part.Material,
            originalReflectance = part.Reflectance,
            originalTransparency = part.Transparency,
            originalCastShadow = part.CastShadow
        }
        
        if part.Material ~= Enum.Material.Air then
            part.Material = Enum.Material.Plastic
            part.Reflectance = 0
            part.CastShadow = false
        end
        
        for _, child in pairs(part:GetChildren()) do
            pcall(function()
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0.95
                    child.StudsPerTileU = math.max(child.StudsPerTileU * 2, 4)
                    child.StudsPerTileV = math.max(child.StudsPerTileV * 2, 4)
                elseif child:IsA("SurfaceGui") then
                    child.Enabled = false
                elseif child:IsA("ParticleEmitter") then
                    child.Enabled = false
                elseif child:IsA("Fire") or child:IsA("Smoke") then
                    child.Enabled = false
                elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                    child.Enabled = false
                elseif child:IsA("Beam") or child:IsA("Trail") then
                    child.Enabled = false
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
        part.Transparency = original.originalTransparency
        part.CastShadow = original.originalCastShadow
        
        for _, child in pairs(part:GetChildren()) do
            pcall(function()
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0
                    child.StudsPerTileU = child.StudsPerTileU / 2
                    child.StudsPerTileV = child.StudsPerTileV / 2
                elseif child:IsA("SurfaceGui") then
                    child.Enabled = true
                elseif child:IsA("ParticleEmitter") then
                    child.Enabled = true
                elseif child:IsA("Fire") or child:IsA("Smoke") then
                    child.Enabled = true
                elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                    child.Enabled = true
                elseif child:IsA("Beam") or child:IsA("Trail") then
                    child.Enabled = true
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
            elseif obj:IsA("Explosion") then
                obj.Visible = false
            elseif obj:IsA("Sound") then
                obj.Volume = math.max(obj.Volume * 0.3, 0.1)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
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
        
        local renderSettings = settings():GetService("RenderSettings")
        local lighting = game:GetService("Lighting")
        
        renderSettings.QualityLevel = Enum.QualityLevel.Level01
        
        lighting.GlobalShadows = false
        lighting.FogEnd = 50
        lighting.FogStart = 0
        lighting.Brightness = 0.8
        lighting.EnvironmentDiffuseScale = 0.1
        lighting.EnvironmentSpecularScale = 0.1
        lighting.ShadowSoftness = 0
        
        if lighting.Technology ~= Enum.Technology.Compatibility then
            lighting.Technology = Enum.Technology.Compatibility
        end
        
        optimizeWorkspace(workspace)
        
        FastModeModule.connections.descendantAdded = workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") then
                wait(0.05) -- Small delay for object initialization
                optimizePart(obj)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            elseif obj:IsA("Sound") then
                obj.Volume = math.max(obj.Volume * 0.3, 0.1)
            end
        end)
        
        FastModeModule.connections.childAdded = workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") or child:IsA("Folder") then
                wait(0.1)
                optimizeWorkspace(child)
            end
        end)
        
        FastModeModule.enabled = true
        warn("[Fast Mode] ENABLED - Performance optimized for mobile")
    end)
end

function FastModeModule.disable()
    pcall(function()
        if not FastModeModule.enabled then 
            return 
        end
        
        for _, connection in pairs(FastModeModule.connections) do
            if connection then
                connection:Disconnect()
            end
        end
        FastModeModule.connections = {}
        
        if FastModeModule.originalSettings and next(FastModeModule.originalSettings) then
            local renderSettings = settings():GetService("RenderSettings")
            local lighting = game:GetService("Lighting")
            
            renderSettings.QualityLevel = FastModeModule.originalSettings.QualityLevel
            lighting.GlobalShadows = FastModeModule.originalSettings.GlobalShadows
            lighting.FogEnd = FastModeModule.originalSettings.FogEnd
            lighting.FogStart = FastModeModule.originalSettings.FogStart
            lighting.Brightness = FastModeModule.originalSettings.Brightness
            lighting.EnvironmentDiffuseScale = FastModeModule.originalSettings.EnvironmentDiffuseScale
            lighting.EnvironmentSpecularScale = FastModeModule.originalSettings.EnvironmentSpecularScale
            lighting.ShadowSoftness = FastModeModule.originalSettings.ShadowSoftness
            lighting.Technology = FastModeModule.originalSettings.Technology
        end
        
        for part, _ in pairs(FastModeModule.processedParts) do
            restorePart(part)
        end
        
        FastModeModule.processedParts = {}
        
        FastModeModule.enabled = false
        warn("[Fast Mode] DISABLED - Graphics restored to original")
    end)
end

function FastModeModule.toggle(state)
    if state then
        FastModeModule.enable()
    else
        FastModeModule.disable()
    end
end

function FastModeModule.isEnabled()
    return FastModeModule.enabled
end

function FastModeModule.cleanup()
    pcall(function()
        FastModeModule.disable()
    end)
end

game:BindToClose(function()
    FastModeModule.cleanup()
end)

return FastModeModule
