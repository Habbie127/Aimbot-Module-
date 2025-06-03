local UtilsModule = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function UtilsModule.isEnemy(player)
    return player ~= LocalPlayer and player.Team ~= LocalPlayer.Team
end

function UtilsModule.isAlive(player)
    return player.Character and 
           player.Character:FindFirstChild("HumanoidRootPart") and 
           player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0
end

function UtilsModule.getDistance(player1, player2)
    if not (player1.Character and player2.Character) then return nil end
    local hrp1 = player1.Character:FindFirstChild("HumanoidRootPart")
    local hrp2 = player2.Character:FindFirstChild("HumanoidRootPart")
    if not (hrp1 and hrp2) then return nil end
    return (hrp1.Position - hrp2.Position).Magnitude
end

function UtilsModule.getEnemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if UtilsModule.isEnemy(player) and UtilsModule.isAlive(player) then
            table.insert(enemies, player)
        end
    end
    return enemies
end

return UtilsModule
