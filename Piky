local ESPModule = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local espFolder = Workspace:FindFirstChild("NPC_ESP") or Instance.new("Folder", Workspace)
espFolder.Name = "NPC_ESP"

-- Create ESP on NPC
function ESPModule.createESP(npc)
    if espFolder:FindFirstChild(npc.Name .. "_" .. npc:GetDebugId()) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = npc.Name .. "_" .. npc:GetDebugId()
    highlight.Adornee = npc
    highlight.FillColor = Color3.new(1, 1, 0) -- Yellow
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(0, 0, 0)
    highlight.OutlineTransparency = 0.1
    highlight.Parent = espFolder

    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if hrp then
        local billboard = Instance.new("BillboardGui", highlight)
        billboard.Name = "DistanceLabel"
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = hrp

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Text = npc.Name

        -- Update label every frame
        RunService.RenderStepped:Connect(function()
            if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and hrp then
                local dist = math.floor((hrp.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                label.Text = npc.Name .. " [" .. dist .. "m]"
            end
        end)
    end
end

return ESPModule
