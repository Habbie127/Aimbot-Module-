local GraphicsModule = {}

local originalProperties = {}
local destroyedObjects = {}
local isOptimized = false

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local runService = game:GetService("RunService")

local objectsDestroyed = 0
local objectsSimplified = 0

local function isValidObject(obj)
    return obj and obj.Parent and not obj.Parent:IsA("Player")
end

local function isPlayerObject(obj)
    local player = players.LocalPlayer
    if player and player.Character then
        return obj:IsDescendantOf(player.Character)
    end
    return false
end

local function isImportantGameplay(obj)
    if not obj or not obj.Name then return false end
    
    local name = obj.Name:lower()
    local importantPatterns = {
        "spawn", "checkpoint", "flag", "weapon", "gun", 
        "health", "ladder", "stairs", "floor", "barrier"
    }
    
    for _, pattern in pairs(importantPatterns) do
        if name:find(pattern) then
            return true
        end
    end
    
    return false
end

local function storeOriginalProperties(obj)
    if not isValidObject(obj) or originalProperties[obj] then 
        return 
    end
    
    originalProperties[obj] = {}
    
    pcall(function()
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
    end)
end

local function processObjectsBatch(objects, processFunc, batchSize)
    batchSize = batchSize or 50
    local index = 1
    
    local function processBatch()
        local processed = 0
        while index <= #objects and processed < batchSize do
            local obj = objects[index]
            if isValidObject(obj) then
                pcall(processFunc, obj)
            end
            index = index + 1
            processed = processed + 1
        end
        
        if index <= #objects then
            runService.Heartbeat:Wait()
            processBatch()
        end
    end
    
    processBatch()
end

local function destroyGrassAndVegetation()
    local toDestroy = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if #toDestroy >= 1000 then break end -- Limit to prevent lag
        
        if obj:IsA("BasePart") and isValidObject(obj) and 
           not isPlayerObject(obj) and not isImportantGameplay(obj) then
            
            local name = obj.Name:lower()
            local size = obj.Size
            local shouldDestroy = false
            
            local grassPatterns = {"grass", "weed", "plant", "flower", "bush", "leaf"}
            for _, pattern in pairs(grassPatterns) do
                if name:find(pattern) then
                    shouldDestroy = true
                    break
                end
            end
            
            if not shouldDestroy and size.Y < 2 and size.X < 3 and size.Z < 3 then
                shouldDestroy = true
            end
            
            if not shouldDestroy and size.Y < 4 then
                pcall(function()
                    local color = obj.Color
                    if color.G > 0.4 and color.G > color.R then
                        shouldDestroy = true
                    end
                end)
            end
            
            if shouldDestroy then
                table.insert(toDestroy, obj)
            end
        end
    end
    
    processObjectsBatch(toDestroy, function(obj)
        if isValidObject(obj) then
            obj:Destroy()
            objectsDestroyed = objectsDestroyed + 1
        end
    end, 25)
    
    print("Destroyed " .. #toDestroy .. " grass/vegetation objects")
end

local function destroySmallProps()
    local toDestroy = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if #toDestroy >= 500 then break end
        
        if obj:IsA("BasePart") and isValidObject(obj) and 
           not isPlayerObject(obj) and not isImportantGameplay(obj) then
            
            local name = obj.Name:lower()
            local size = obj.Size
            local shouldDestroy = false
            
            local propPatterns = {"debris", "trash", "scrap", "detail", "decoration"}
            for _, pattern in pairs(propPatterns) do
                if name:find(pattern) then
                    shouldDestroy = true
                    break
                end
            end
            
            if not shouldDestroy and size.Y < 1.5 and size.X < 1.5 and size.Z < 1.5 then
                shouldDestroy = true
            end
            
            if shouldDestroy then
                table.insert(toDestroy, obj)
            end
        end
    end
    
    processObjectsBatch(toDestroy, function(obj)
        if isValidObject(obj) then
            obj:Destroy()
            objectsDestroyed = objectsDestroyed + 1
        end
    end, 25)
    
    print("Destroyed " .. #toDestroy .. " small props/debris")
end

local function simplifyTrees()
    local treesToSimplify = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if #treesToSimplify >= 200 then break end
        
        if obj:IsA("BasePart") and isValidObject(obj) and not isPlayerObject(obj) then
            local name = obj.Name:lower()
            local isTree = false
            
            local treePatterns = {"tree", "trunk", "branch", "bark", "wood"}
            for _, pattern in pairs(treePatterns) do
                if name:find(pattern) then
                    isTree = true
                    break
                end
            end
            
            if not isTree and obj.Size.Y > 6 then
                pcall(function()
                    local color = obj.Color
                    if color.R > 0.2 and color.R < 0.7 and color.G > 0.1 and color.G < 0.5 then
                        isTree = true
                    end
                end)
            end
            
            if isTree then
                table.insert(treesToSimplify, obj)
            end
        end
    end
    
    processObjectsBatch(treesToSimplify, function(obj)
        if not isValidObject(obj) then return end
        
        storeOriginalProperties(obj)
        
        pcall(function()
            if obj:IsA("MeshPart") then
                obj.MeshId = ""
                obj.TextureID = ""
                obj.Shape = Enum.PartType.Block
                obj.Material = Enum.Material.Wood
                obj.Color = Color3.new(0.35, 0.18, 0.05)
            end
            
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                    child:Destroy()
                end
            end
            
            objectsSimplified = objectsSimplified + 1
        end)
    end, 20)
end

local function simplifyBuildings()
    local buildingsToSimplify = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if #buildingsToSimplify >= 200 then break end
        
        if obj:IsA("BasePart") and isValidObject(obj) and not isPlayerObject(obj) then
            local name = obj.Name:lower()
            local isBuilding = false
            
            local buildingPatterns = {"house", "building", "wall", "roof", "concrete", "brick"}
            for _, pattern in pairs(buildingPatterns) do
                if name:find(pattern) then
                    isBuilding = true
                    break
                end
            end
            
            if isBuilding then
                table.insert(buildingsToSimplify, obj)
            end
        end
    end
    
    processObjectsBatch(buildingsToSimplify, function(obj)
        if not isValidObject(obj) then return end
        
        storeOriginalProperties(obj)
        
        pcall(function()
            if obj:IsA("MeshPart") then
                obj.MeshId = ""
                obj.TextureID = ""
                obj.Shape = Enum.PartType.Block
                obj.Material = Enum.Material.Concrete
                obj.Color = Color3.new(0.5, 0.5, 0.5)
            end
            
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                    child:Destroy()
                end
            end
            
            objectsSimplified = objectsSimplified + 1
        end)
    end, 20)
end

local function removeEffects()
    local effectsToRemove = {}
    local effectsRemoved = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isPlayerObject(obj) then
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or 
               obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Explosion") or
               obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                table.insert(effectsToRemove, obj)
            end
        end
    end
    
    for _, obj in pairs(effectsToRemove) do
        pcall(function()
            if obj and obj.Parent then
                obj:Destroy()
                effectsRemoved = effectsRemoved + 1
            end
        end)
    end
    
    print("Removed " .. effectsRemoved .. " particle/lighting effects")
end

function GraphicsModule.enableFastMode()
    if isOptimized then return end
    
    print("🚀 MOBILE ULTRA MODE - Maximum Performance Optimization...")
    
    objectsDestroyed = 0
    objectsSimplified = 0
    
    pcall(function()
        storeOriginalProperties(lighting)
        lighting.GlobalShadows = false
        lighting.FogEnd = 200
        lighting.FogStart = 20
        lighting.Brightness = 0.8
        lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        lighting.Ambient = Color3.new(0.4, 0.4, 0.4)
    end)
    
    spawn(function()
        destroyGrassAndVegetation()
        wait(0.5)
        destroySmallProps()
        wait(0.5)
        removeEffects()
        wait(0.5)
        simplifyTrees()
        wait(0.5)
        simplifyBuildings()
        
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            
            if game:GetService("UserInputService").TouchEnabled then
                workspace.StreamingEnabled = true
                workspace.StreamingMinRadius = 64
                workspace.StreamingTargetRadius = 128
            end
        end)
        
        isOptimized = true
        
        print("✅ ULTRA MODE ENABLED!")
        print("📊 Performance Stats:")
        print("   🗑️ Objects Destroyed: " .. objectsDestroyed)
        print("   🔧 Objects Simplified: " .. objectsSimplified)
        print("   📱 Mobile optimizations applied")
        print("   🚀 Performance boost applied!")
    end)
end

function GraphicsModule.restoreOriginalGraphics()
    if not isOptimized then return end
    
    print("Restoring original graphics...")
    
    if originalProperties[lighting] then
        for prop, value in pairs(originalProperties[lighting]) do
            pcall(function()
                if lighting[prop] ~= nil then
                    lighting[prop] = value
                end
            end)
        end
    end
    
    for obj, props in pairs(originalProperties) do
        if obj and obj.Parent then
            for prop, value in pairs(props) do
                pcall(function()
                    if obj[prop] ~= nil then
                        obj[prop] = value
                    end
                end)
            end
        end
    end
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        workspace.StreamingEnabled = false
    end)
    
    originalProperties = {}
    isOptimized = false
    
    print("Graphics restoration complete!")
    if #destroyedObjects > 0 then
        print("💡 Some objects were destroyed - rejoin to fully restore")
    end
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
