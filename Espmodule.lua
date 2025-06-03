local ESPModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

-- ESP Settings
local espHighlights = {}
local ESPColor = Color3.fromRGB(0, 255, 0)
local espEnabled = false
local espConnection = nil
local highlightDistance = 300

-- Distance ESP Settings
local espDistanceEnabled = false
local espDistanceConnection = nil
local distanceThreshold = 10

-- Health ESP Settings
local espHealthEnabled = false
local espHealthConnection = nil

-- Name ESP Settings  
local espNameEnabled = false
local espNameConnection = nil

-- Storage for text labels
local espLabels = {} -- Combined storage for all text labels per player

-- ESP Highlight Functions (Only under 300m)
local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = player.Character
    highlight.FillColor = ESPColor
    highlight.OutlineColor = ESPColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    espHighlights[player] = highlight
end

local function removeHighlight(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            
            if humanoid.Health > 0 then
                -- Only create highlights if under 300m
                if distance <= highlightDistance then
                    if not espHighlights[player] then
                        createHighlight(player)
                    end
                else
                    -- Remove highlight if over 300m
                    removeHighlight(player)
                end
            else
                removeHighlight(player)
            end
        else
            removeHighlight(player)
        end
    end
end

-- Worldwide Text ESP Functions (No Billboard, Pure Screen Text)
local function createTextLabels(player)
    if not espLabels[player] then
        espLabels[player] = {}
    end
    
    -- Distance Text
    if not espLabels[player].distance then
        local distanceText = Drawing.new("Text")
        distanceText.Size = 12
        distanceText.Color = Color3.new(1, 1, 1)
        distanceText.Font = 2
        distanceText.Outline = true
        distanceText.OutlineColor = Color3.new(0, 0, 0)
        distanceText.Center = true
        distanceText.Visible = false
        espLabels[player].distance = distanceText
    end
    
    -- Health Text
    if not espLabels[player].health then
        local healthText = Drawing.new("Text")
        healthText.Size = 12
        healthText.Color = Color3.new(0, 1, 0)
        healthText.Font = 2
        healthText.Outline = true
        healthText.OutlineColor = Color3.new(0, 0, 0)
        healthText.Center = true
        healthText.Visible = false
        espLabels[player].health = healthText
    end
    
    -- Name Text
    if not espLabels[player].name then
        local nameText = Drawing.new("Text")
        nameText.Size = 12
        nameText.Color = Color3.new(1, 1, 0)
        nameText.Font = 2
        nameText.Outline = true
        nameText.OutlineColor = Color3.new(0, 0, 0)
        nameText.Center = true
        nameText.Visible = false
        espLabels[player].name = nameText
    end
end

local function removeTextLabels(player)
    if espLabels[player] then
        if espLabels[player].distance then
            espLabels[player].distance:Remove()
            espLabels[player].distance = nil
        end
        if espLabels[player].health then
            espLabels[player].health:Remove()
            espLabels[player].health = nil
        end
        if espLabels[player].name then
            espLabels[player].name:Remove()
            espLabels[player].name = nil
        end
        espLabels[player] = nil
    end
end

local function updateTextESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local head = player.Character.Head
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            
            if humanoid.Health > 0 then
                createTextLabels(player)
                
                -- Get screen position of head
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                
                if onScreen then
                    -- Calculate consistent text size (no scaling with distance)
                    local baseSize = 12
                    
                    -- Update Name Text (Directly above head)
                    if espNameEnabled then
                        espLabels[player].name.Text = player.Name
                        espLabels[player].name.Position = Vector2.new(headPos.X, headPos.Y)
                        espLabels[player].name.Size = baseSize -- Fixed size
                        espLabels[player].name.Visible = true
                        espLabels[player].name.Color = Color3.new(1, 1, 0) -- Yellow
                    else
                        espLabels[player].name.Visible = false
                    end
                    
                    -- Update Health Text (Above name)
                    if espHealthEnabled then
                        local health = math.floor(humanoid.Health)
                        local maxHealth = math.floor(humanoid.MaxHealth)
                        espLabels[player].health.Text = health .. "/" .. maxHealth
                        espLabels[player].health.Position = Vector2.new(headPos.X, headPos.Y - 10) -- 20 pixels above name
                        espLabels[player].health.Size = baseSize -- Fixed size
                        espLabels[player].health.Visible = true
                        
                        -- Color based on health percentage
                        local healthPercent = health / maxHealth
                        if healthPercent > 0.6 then
                            espLabels[player].health.Color = Color3.new(0, 1, 0) -- Green
                        elseif healthPercent > 0.3 then
                            espLabels[player].health.Color = Color3.new(1, 1, 0) -- Yellow
                        else
                            espLabels[player].health.Color = Color3.new(1, 0, 0) -- Red
                        end
                    else
                        espLabels[player].health.Visible = false
                    end
                    
                    -- Update Distance Text (Above health)
                    if espDistanceEnabled and distance > distanceThreshold then
                        local distanceRounded = math.floor(distance)
                        espLabels[player].distance.Text = distanceRounded .. "m"
                        espLabels[player].distance.Position = Vector2.new(headPos.X, headPos.Y - 15) -- 40 pixels above name (20 above health)
                        espLabels[player].distance.Size = baseSize -- Fixed size
                        espLabels[player].distance.Visible = true
                        
                        -- Color based on distance
                        if distance > 200 then
                            espLabels[player].distance.Color = Color3.new(1, 0, 0) -- Red
                        elseif distance > 100 then
                            espLabels[player].distance.Color = Color3.new(1, 1, 0) -- Yellow
                        else
                            espLabels[player].distance.Color = Color3.new(0, 1, 0) -- Green
                        end
                    else
                        espLabels[player].distance.Visible = false
                    end
                else
                    -- Hide all text if not on screen
                    espLabels[player].distance.Visible = false
                    espLabels[player].health.Visible = false
                    espLabels[player].name.Visible = false
                end
            else
                removeTextLabels(player)
            end
        else
            removeTextLabels(player)
        end
    end
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
    removeTextLabels(player)
end)

-- Module functions
function ESPModule.toggleESP(state)
    espEnabled = state
    if state then
        if espConnection then espConnection:Disconnect() end
        espConnection = RunService.RenderStepped:Connect(updateESP)
    else
        if espConnection then espConnection:Disconnect() end
        -- Clean up all highlights
        for player, _ in pairs(espHighlights) do
            if espHighlights[player] then
                espHighlights[player]:Destroy()
                espHighlights[player] = nil
            end
        end
    end
end

function ESPModule.toggleDistance(state)
    espDistanceEnabled = state
    if state or espHealthEnabled or espNameEnabled then
        if not espDistanceConnection then
            espDistanceConnection = RunService.RenderStepped:Connect(updateTextESP)
        end
    else
        if espDistanceConnection then
            espDistanceConnection:Disconnect()
            espDistanceConnection = nil
        end
        -- Clean up all text labels if all text ESP disabled
        for player, _ in pairs(espLabels) do
            removeTextLabels(player)
        end
    end
end

function ESPModule.toggleHealth(state)
    espHealthEnabled = state
    if state or espDistanceEnabled or espNameEnabled then
        if not espDistanceConnection then
            espDistanceConnection = RunService.RenderStepped:Connect(updateTextESP)
        end
    else
        if espDistanceConnection and not espDistanceEnabled and not espNameEnabled then
            espDistanceConnection:Disconnect()
            espDistanceConnection = nil
        end
        -- Clean up all text labels if all text ESP disabled
        if not espDistanceEnabled and not espNameEnabled then
            for player, _ in pairs(espLabels) do
                removeTextLabels(player)
            end
        end
    end
end

function ESPModule.toggleName(state)
    espNameEnabled = state
    if state or espDistanceEnabled or espHealthEnabled then
        if not espDistanceConnection then
            espDistanceConnection = RunService.RenderStepped:Connect(updateTextESP)
        end
    else
        if espDistanceConnection and not espDistanceEnabled and not espHealthEnabled then
            espDistanceConnection:Disconnect()
            espDistanceConnection = nil
        end
        -- Clean up all text labels if all text ESP disabled
        if not espDistanceEnabled and not espHealthEnabled then
            for player, _ in pairs(espLabels) do
                removeTextLabels(player)
            end
        end
    end
end

return ESPModule
