local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

local espHighlights = {}
local ESPColor = Color3.fromRGB(0, 255, 0)
local espEnabled = false
local espConnection = nil
local highlightDistance = 400

local espDistanceEnabled = false
local espDistanceConnection = nil
local distanceThreshold = 10

local espHealthEnabled = false
local espHealthConnection = nil

local espNameEnabled = false
local espNameConnection = nil

local espLabels = {} -- Combined storage for all text labels per player

local function createHighlight(player)
    if player.Character then
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
end

local function removeHighlight(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance <= highlightDistance then
                    if not espHighlights[player] then
                        createHighlight(player)
                    end
                else
                    removeHighlight(player)
                end
            else
                -- Humanoid is nil or dead, remove highlight
                removeHighlight(player)
            end
        else
            removeHighlight(player)
        end
    end
end

local function createTextLabels(player)
    if not espLabels[player] then
        espLabels[player] = {}
    end
    
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
    
    if not espLabels[player].health then
        local healthText = Drawing.new("Text")
        healthText.Size = 12
        healthText.Color = Color3.new(0, 255, 0)
        healthText.Font = 2
        healthText.Outline = true
        healthText.OutlineColor = Color3.new(0, 0, 0)
        healthText.Center = true
        healthText.Visible = false
        espLabels[player].health = healthText
    end
    
    if not espLabels[player].name then
        local nameText = Drawing.new("Text")
        nameText.Size = 12
        nameText.Color = Color3.new(0, 1, 0)
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
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
            local head = player.Character.Head
            if humanoid and humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude

                createTextLabels(player)
                
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                
                if onScreen then
                    local baseSize = 12
                    
                    if espNameEnabled then
                        espLabels[player].name.Text = player.Name
                        espLabels[player].name.Position = Vector2.new(headPos.X, headPos.Y)
                        espLabels[player].name.Size = baseSize 
                        espLabels[player].name.Visible = true
                    else
                        espLabels[player].name.Visible = false
                    end
                    
                    if espHealthEnabled then
                        local health = math.floor(humanoid.Health)
                        local maxHealth = math.floor(humanoid.MaxHealth)
                        espLabels[player].health.Text = health .. "/" .. maxHealth
                        espLabels[player].health.Position = Vector2.new(headPos.X, headPos.Y - 13)
                        espLabels[player].health.Size = baseSize 
                        espLabels[player].health.Visible = true
                        
                        local healthPercent = health / maxHealth
                        if healthPercent > 0.6 then
                            espLabels[player].health.Color = Color3.new(0, 1, 0)
                        elseif healthPercent > 0.3 then
                            espLabels[player].health.Color = Color3.new(1, 1, 0)
                        else
                            espLabels[player].health.Color = Color3.new(1, 0, 0)
                        end
                    else
                        espLabels[player].health.Visible = false
                    end
                    
                    if espDistanceEnabled and distance > distanceThreshold then
                        local distanceRounded = math.floor(distance)
                        espLabels[player].distance.Text = distanceRounded .. "m"
                        espLabels[player].distance.Position = Vector2.new(headPos.X, headPos.Y - 26)
                        espLabels[player].distance.Size = baseSize 
                        espLabels[player].distance.Visible = true
                        
                        if distance > 200 then
                            espLabels[player].distance.Color = Color3.new(1, 0, 0)
                        elseif distance > 100 then
                            espLabels[player].distance.Color = Color3.new(1, 1, 0)
                        else
                            espLabels[player].distance.Color = Color3.new(0, 1, 0)
                        end
                    else
                        espLabels[player].distance.Visible = false
                    end
                else
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

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
    removeTextLabels(player)
end)

function ESPModule.toggleESP(state)
    espEnabled = state
    if state then
        if espConnection then espConnection:Disconnect() end
        espConnection = RunService.RenderStepped:Connect(updateESP)
    else
        if espConnection then espConnection:Disconnect() end
        for player, _ in pairs(espHighlights) do
            removeHighlight(player)
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
        if not espDistanceEnabled and not espHealthEnabled then
            for player, _ in pairs(espLabels) do
                removeTextLabels(player)
            end
        end
    end
end

return ESPModule
