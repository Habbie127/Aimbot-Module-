local GraphicsModule = {}

local originalProperties = {}
local originalObjects = {}
local isOptimized = false

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

local function isPlayerObject(obj)
    for _, player in pairs(players:GetPlayers()) do
        if player.Character and obj:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

local function storeOriginalProperties(obj)
    if not originalProperties[obj] then
        originalProperties[obj] = {}
        
        if obj:IsA("MeshPart") then
            originalProperties[obj].MeshId = obj.MeshId
            originalProperties[obj].TextureID = obj.TextureID
        elseif obj:IsA("SpecialMesh") then
            originalProperties[obj].MeshId = obj.MeshId
            originalProperties[obj].TextureId = obj.TextureId
            originalProperties[obj].Scale = obj.Scale
        elseif obj:IsA("Part") then
            originalProperties[obj].Material = obj.Material
            originalProperties[obj].Color = obj.Color
        end
        
        if obj:IsA("BasePart") then
            originalProperties[obj].Transparency = obj.Transparency
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            originalProperties[obj].Texture = obj.Texture
            originalProperties[obj].Transparency = obj.Transparency
        end
    end
end

local function optimizeGrass()
    local grassObjects = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            local name = obj.Name:lower()
            if name:find("grass") or name:find("weed") or name:find("plant") or 
               (obj:IsA("MeshPart") and obj.Size.Y < 2 and obj.Color == Color3.new(0, 1, 0)) then
                table.insert(grassObjects, obj)
                storeOriginalProperties(obj)
            end
        end
    end
    
    for _, grass in pairs(grassObjects) do
        if grass.Parent then
            originalObjects[grass] = {
                parent = grass.Parent,
                object = grass:Clone()
            }
            grass:Destroy()
        end
    end
end

local function optimizeTrees()
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            local name = obj.Name:lower()
            
            if name:find("tree") or name:find("branch") or name:find("leaf") or name:find("trunk") then
                storeOriginalProperties(obj)
                
                if obj:IsA("MeshPart") then
                    if name:find("trunk") or name:find("tree") then
                        obj.MeshId = ""
                        obj.Shape = Enum.PartType.Cylinder
                        obj.Material = Enum.Material.Wood
                        obj.Color = Color3.new(0.4, 0.2, 0.1)
                    else
                        obj.MeshId = ""
                        obj.Shape = Enum.PartType.Ball
                        obj.Material = Enum.Material.Plastic
                        obj.Color = Color3.new(0, 0.5, 0)
                    end
                    obj.TextureID = ""
                    
                elseif obj:IsA("SpecialMesh") then
                    obj.MeshId = ""
                    obj.TextureId = ""
                    obj.Scale = Vector3.new(0.5, 0.5, 0.5)
                    
                elseif obj:IsA("Part") then
                    obj.Material = Enum.Material.Plastic
                    if name:find("trunk") then
                        obj.Color = Color3.new(0.4, 0.2, 0.1)
                    else
                        obj.Color = Color3.new(0, 0.5, 0)
                    end
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        storeOriginalProperties(child)
                        child.Transparency = 1
                    end
                end
            end
        end
    end
end

local function optimizeBuildings()
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            local name = obj.Name:lower()
            
            if name:find("house") or name:find("building") or name:find("wall") or 
               name:find("roof") or name:find("door") or name:find("window") then
                storeOriginalProperties(obj)
                
                if obj:IsA("MeshPart") then
                    obj.MeshId = ""
                    obj.TextureID = ""
                    
                    if name:find("roof") then
                        obj.Shape = Enum.PartType.Wedge
                        obj.Material = Enum.Material.Concrete
                        obj.Color = Color3.new(0.3, 0.3, 0.3)
                    else
                        obj.Shape = Enum.PartType.Block
                        obj.Material = Enum.Material.Concrete
                        obj.Color = Color3.new(0.7, 0.7, 0.7)
                    end
                    
                elseif obj:IsA("SpecialMesh") then
                    obj.MeshId = ""
                    obj.TextureId = ""
                    obj.Scale = Vector3.new(1, 1, 1)
                    
                elseif obj:IsA("Part") then
                    obj.Material = Enum.Material.Concrete
                    obj.Color = Color3.new(0.7, 0.7, 0.7)
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        storeOriginalProperties(child)
                        child.Transparency = 0.8
                    end
                end
            end
        end
    end
end

local function optimizeEnvironment()
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            local name = obj.Name:lower()
            
            if name:find("rock") or name:find("stone") or name:find("debris") or 
               name:find("detail") or name:find("prop") then
                storeOriginalProperties(obj)
                
                if obj:IsA("MeshPart") then
                    obj.MeshId = ""
                    obj.TextureID = ""
                    obj.Shape = Enum.PartType.Block
                    obj.Material = Enum.Material.Rock
                    obj.Color = Color3.new(0.5, 0.5, 0.5)
                    
                elseif obj:IsA("SpecialMesh") then  
                    obj.MeshId = ""
                    obj.TextureId = ""
                    obj.Scale = obj.Scale * 0.7
                end
            end
            
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                storeOriginalProperties(obj)
                obj.Enabled = false
            end
        end
    end
end

function GraphicsModule.enableFastMode()
    if isOptimized then return end
    
    print("Enabling Fast Mode - Optimizing graphics for FPS boost...")
    
    local lighting = game:GetService("Lighting")
    storeOriginalProperties(lighting)
    lighting.GlobalShadows = false
    lighting.FogEnd = 500
    lighting.FogStart = 100
    
    optimizeGrass()
    optimizeTrees()  
    optimizeBuildings()
    optimizeEnvironment()
    
    settings().Rendering.QualityLevel = 1
    
    isOptimized = true
    print("Fast Mode enabled - Graphics optimized for maximum FPS!")
end

function GraphicsModule.restoreOriginalGraphics()
    if not isOptimized then return end
    
    print("Restoring original graphics...")
    
    local lighting = game:GetService("Lighting")
    if originalProperties[lighting] then
        lighting.GlobalShadows = originalProperties[lighting].GlobalShadows or true
        lighting.FogEnd = originalProperties[lighting].FogEnd or 100000
        lighting.FogStart = originalProperties[lighting].FogStart or 0
    end
    
    for obj, props in pairs(originalProperties) do
        if obj and obj.Parent then
            -- Restore mesh properties
            if obj:IsA("MeshPart") then
                if props.MeshId then obj.MeshId = props.MeshId end
                if props.TextureID then obj.TextureID = props.TextureID end
            elseif obj:IsA("SpecialMesh") then
                if props.MeshId then obj.MeshId = props.MeshId end
                if props.TextureId then obj.TextureId = props.TextureId end
                if props.Scale then obj.Scale = props.Scale end
            elseif obj:IsA("Part") then
                if props.Material then obj.Material = props.Material end
                if props.Color then obj.Color = props.Color end
            end
            
            if props.Transparency and obj:IsA("BasePart") then
                obj.Transparency = props.Transparency
            end
            
            if obj:IsA("Decal") or obj:IsA("Texture") then
                if props.Texture then obj.Texture = props.Texture end
                if props.Transparency then obj.Transparency = props.Transparency end
            end
            
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = props.Enabled or true
            end
        end
    end
    
    for obj, data in pairs(originalObjects) do
        if data.parent and data.object then
            local restored = data.object:Clone()
            restored.Parent = data.parent
        end
    end
    
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
    
    originalProperties = {}
    originalObjects = {}
    isOptimized = false
    
    print("Original graphics restored!")
end

function GraphicsModule.toggleOptimization()
    if isOptimized then
        GraphicsModule.restoreOriginalGraphics()
    else
        GraphicsModule.enableFastMode()
    end
end

function GraphicsModule.isOptimized()
    return isOptimized
end

return GraphicsModule
