local GraphicsModule = {}

local originalProperties = {}
local destroyedObjects = {}
local isOptimized = false

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")

local objectsDestroyed = 0
local objectsSimplified = 0

local function isPlayerObject(obj)
    for _, player in pairs(players:GetPlayers()) do
        if player.Character and obj:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

local function isImportantGameplay(obj)
    local name = obj.Name:lower()
    local importantPatterns = {
        "spawn", "checkpoint", "flag", "capture", "objective",
        "weapon", "gun", "rifle", "ammo", "health", "medkit",
        "ladder", "stairs", "ramp", "platform", "floor",
        "barrier", "cover", "sandbag", "essential", "core"
    }
    
    for _, pattern in pairs(importantPatterns) do
        if name:find(pattern) then
            return true
        end
    end
    
    return false
end

local function storeForDestruction(obj)
    if obj.Parent then
        destroyedObjects[#destroyedObjects + 1] = {
            name = obj.Name,
            className = obj.ClassName,
            parent = obj.Parent,
            cframe = obj:IsA("BasePart") and obj.CFrame or nil,
            size = obj:IsA("BasePart") and obj.Size or nil,
            color = obj:IsA("BasePart") and obj.Color or nil,
            material = obj:IsA("BasePart") and obj.Material or nil
        }
    end
end

local function storeOriginalProperties(obj)
    if not originalProperties[obj] then
        originalProperties[obj] = {}
        
        if obj:IsA("MeshPart") then
            originalProperties[obj].MeshId = obj.MeshId
            originalProperties[obj].TextureID = obj.TextureID
            originalProperties[obj].Shape = obj.Shape
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

local function destroyGrassAndVegetation()
    local toDestroy = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isPlayerObject(obj) and not isImportantGameplay(obj) then
            local name = obj.Name:lower()
            local size = obj.Size
            
            local grassPatterns = {
                "grass", "weed", "plant", "flower", "bush", "shrub", 
                "fern", "moss", "ivy", "vine", "herb", "foliage",
                "vegetation", "leaf", "petal", "stem", "clover"
            }
            
            local shouldDestroy = false
            
            for _, pattern in pairs(grassPatterns) do
                if name:find(pattern) then
                    shouldDestroy = true
                    break
                end
            end
            
            if size.Y < 2 and size.X < 3 and size.Z < 3 then
                shouldDestroy = true
            end
            
            if size.Y < 4 and obj.Color.G > 0.4 and obj.Color.G > obj.Color.R then
                shouldDestroy = true
            end
            
            if shouldDestroy then
                table.insert(toDestroy, obj)
            end
        end
    end
    
    for _, obj in pairs(toDestroy) do
        storeForDestruction(obj)
        obj:Destroy()
        objectsDestroyed = objectsDestroyed + 1
    end
    
    print("Destroyed " .. #toDestroy .. " grass/vegetation objects")
end

local function destroySmallProps()
    local toDestroy = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isPlayerObject(obj) and not isImportantGameplay(obj) then
            local name = obj.Name:lower()
            local size = obj.Size
            
            local propPatterns = {
                "debris", "rubble", "trash", "litter", "scrap",
                "pebble", "twig", "stick", "fragment", "piece",
                "detail", "decoration", "ornament", "clutter"
            }
            
            local shouldDestroy = false
            
            for _, pattern in pairs(propPatterns) do
                if name:find(pattern) then
                    shouldDestroy = true
                    break
                end
            end
            
            if size.Y < 1.5 and size.X < 1.5 and size.Z < 1.5 then
                shouldDestroy = true
            end
            
            if shouldDestroy then
                table.insert(toDestroy, obj)
            end
        end
    end
    
    for _, obj in pairs(toDestroy) do
        storeForDestruction(obj)
        obj:Destroy()
        objectsDestroyed = objectsDestroyed + 1
    end
    
    print("Destroyed " .. #toDestroy .. " small props/debris")
end

local function simplifyTrees()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isPlayerObject(obj) then
            local name = obj.Name:lower()
            local treePatterns = {
                "tree", "trunk", "branch", "bark", "wood", "timber", "log"
            }
            
            local isTree = false
            for _, pattern in pairs(treePatterns) do
                if name:find(pattern) then
                    isTree = true
                    break
                end
            end
            
            if obj.Size.Y > 6 and not isTree then
                local color = obj.Color
                if color.R > 0.2 and color.R < 0.7 and color.G > 0.1 and color.G < 0.5 then
                    isTree = true
                end
            end
            
            if isTree then
                storeOriginalProperties(obj)
                
                if obj:IsA("MeshPart") then
                    obj.MeshId = ""
                    obj.TextureID = ""
                    if obj.Size.Y > obj.Size.X then
                        obj.Shape = Enum.PartType.Cylinder
                        obj.Material = Enum.Material.Wood
                        obj.Color = Color3.new(0.35, 0.18, 0.05)
                    else
                        obj.Shape = Enum.PartType.Ball
                        obj.Material = Enum.Material.Plastic
                        obj.Color = Color3.new(0, 0.4, 0)
                    end
                elseif obj:IsA("SpecialMesh") then
                    obj.MeshId = ""
                    obj.TextureId = ""
                    obj.Scale = obj.Scale * 0.3
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                        child:Destroy()
                    end
                end
                
                objectsSimplified = objectsSimplified + 1
            end
        end
    end
end

local function simplifyBuildings()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isPlayerObject(obj) then
            local name = obj.Name:lower()
            local buildingPatterns = {
                "house", "building", "wall", "roof", "structure",
                "bunker", "trench", "fortification", "barricade",
                "concrete", "brick", "foundation", "pillar"
            }
            
            local isBuilding = false
            for _, pattern in pairs(buildingPatterns) do
                if name:find(pattern) then
                    isBuilding = true
                    break
                end
            end
            
            if isBuilding then
                storeOriginalProperties(obj)
                
                if obj:IsA("MeshPart") then
                    obj.MeshId = ""
                    obj.TextureID = ""
                    obj.Shape = Enum.PartType.Block
                    obj.Material = Enum.Material.Concrete
                    obj.Color = Color3.new(0.5, 0.5, 0.5)
                elseif obj:IsA("SpecialMesh") then
                    obj.MeshId = ""
                    obj.TextureId = ""
                    obj.Scale = Vector3.new(1, 1, 1)
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                        child:Destroy()
                    end
                end
                
                objectsSimplified = objectsSimplified + 1
            end
        end
    end
end

local function removeEffects()
    local effectsRemoved = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or 
               obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Explosion") or
               obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
                effectsRemoved = effectsRemoved + 1
            end
        end
    end
    
    print("Removed " .. effectsRemoved .. " particle/lighting effects")
end

function GraphicsModule.enableFastMode()
    if isOptimized then return end
    
    print("🚀 MOBILE ULTRA MODE - Maximum Performance Optimization...")
    
    objectsDestroyed = 0
    objectsSimplified = 0
    
    storeOriginalProperties(lighting)
    lighting.GlobalShadows = false
    lighting.FogEnd = 200
    lighting.FogStart = 20
    lighting.Brightness = 0.8
    lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    lighting.Ambient = Color3.new(0.4, 0.4, 0.4)
    
    destroyGrassAndVegetation()
    destroySmallProps()
    removeEffects()
    
    simplifyTrees()
    simplifyBuildings()
    
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    if game:GetService("UserInputService").TouchEnabled then
        workspace.StreamingEnabled = true
        workspace.StreamingMinRadius = 64
        workspace.StreamingTargetRadius = 128
    end
    
    isOptimized = true
    
    print("✅ ULTRA MODE ENABLED!")
    print("📊 Performance Stats:")
    print("   🗑️ Objects Destroyed: " .. objectsDestroyed)
    print("   🔧 Objects Simplified: " .. objectsSimplified)
    print("   📱 Mobile optimizations applied")
    print("   🚀 Expect 2-3x FPS boost on low-end devices!")
end

function GraphicsModule.restoreOriginalGraphics()
    if not isOptimized then return end
    
    print("Restoring original graphics...")
    
    if originalProperties[lighting] then
        for prop, value in pairs(originalProperties[lighting]) do
            if lighting[prop] ~= nil then
                pcall(function()
                    lighting[prop] = value
                end)
            end
        end
    end
    
    for obj, props in pairs(originalProperties) do
        if obj and obj.Parent then
            for prop, value in pairs(props) do
                if obj[prop] ~= nil then
                    pcall(function()
                        obj[prop] = value
                    end)
                end
            end
        end
    end
    
    if #destroyedObjects > 0 then
        print("⚠️ " .. #destroyedObjects .. " objects were destroyed and cannot be restored")
        print("💡 Rejoin the server to restore all objects")
    end
    
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    workspace.StreamingEnabled = false
    
    originalProperties = {}
    isOptimized = false
    
    print("Graphics restoration complete!")
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

function GraphicsModule.getStats()
    return {
        isOptimized = isOptimized,
        objectsDestroyed = objectsDestroyed,
        objectsSimplified = objectsSimplified
    }
end

return GraphicsModule
