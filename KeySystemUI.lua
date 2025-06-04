local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KeySystemUI = {}

function KeySystemUI.createUI(callbacks, config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystemUI"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 300)
    mainFrame.Position = UDim2.new(0.4, -140, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(102, 126, 234)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 18)
    mainCorner.Parent = mainFrame

    local gradientFrame = Instance.new("Frame")
    gradientFrame.Name = "GradientFrame"
    gradientFrame.Size = UDim2.new(1, 0, 1, 0)
    gradientFrame.Position = UDim2.new(0, 0, 0, 0)
    gradientFrame.BackgroundColor3 = Color3.fromRGB(118, 75, 162)
    gradientFrame.BorderSizePixel = 0
    gradientFrame.Parent = mainFrame
    local gradientCorner = Instance.new("UICorner")
    gradientCorner.CornerRadius = UDim.new(0, 18)
    gradientCorner.Parent = gradientFrame

    local function createGradientEffect()
        local colors = {
            Color3.fromRGB(102, 126, 234),
            Color3.fromRGB(118, 75, 162),
            Color3.fromRGB(240, 147, 251),
            Color3.fromRGB(245, 87, 108)
        }

        local function animateGradient()
            local randomColor = colors[math.random(1, #colors)]
            local tween = TweenService:Create(
                gradientFrame,
                TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = randomColor}
            )
            tween:Play()
            tween.Completed:Connect(function()
                task.wait(1)
                animateGradient()
            end)
        end
        animateGradient()
    end

    spawn(createGradientEffect)

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 15, 1, 15)
    shadow.Position = UDim2.new(0, -7.5, 0, -7.5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 22)
    shadowCorner.Parent = shadow

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 55)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BackgroundTransparency = 0.8
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 18)
    headerCorner.Parent = header

    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, 18)
    headerMask.Position = UDim2.new(0, 0, 1, -18)
    headerMask.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    headerMask.BackgroundTransparency = 0.8
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🌈 Dream Portal"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextStrokeTransparency = 0.5
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 28, 0, 28)
    closeButton.Position = UDim2.new(1, -36, 0, 8)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundTransparency = 0.2
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 14)
    closeCorner.Parent = closeButton

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -24, 1, -75)
    contentFrame.Position = UDim2.new(0, 12, 0, 63)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "✨ Welcome to the Dream Realm ✨"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextStrokeTransparency = 0.5
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Parent = contentFrame

    local keyInputFrame = Instance.new("Frame")
    keyInputFrame.Name = "KeyInputFrame"
    keyInputFrame.Size = UDim2.new(1, 0, 0, 70)
    keyInputFrame.Position = UDim2.new(0, 0, 0, 30)
    keyInputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    keyInputFrame.BackgroundTransparency = 0.85
    keyInputFrame.BorderSizePixel = 0
    keyInputFrame.Parent = contentFrame

    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 12)
    keyInputCorner.Parent = keyInputFrame

    local keyInputLabel = Instance.new("TextLabel")
    keyInputLabel.Name = "KeyInputLabel"
    keyInputLabel.Size = UDim2.new(1, -16, 0, 18)
    keyInputLabel.Position = UDim2.new(0, 8, 0, 5)
    keyInputLabel.BackgroundTransparency = 1
    keyInputLabel.Text = "💫 Enter your ethereal key:"
    keyInputLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInputLabel.TextScaled = true
    keyInputLabel.Font = Enum.Font.SourceSans
    keyInputLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyInputLabel.TextStrokeTransparency = 0.5
    keyInputLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    keyInputLabel.Parent = keyInputFrame

    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -16, 0, 28)
    keyInput.Position = UDim2.new(0, 8, 0, 28)
    keyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.BackgroundTransparency = 0.3
    keyInput.Text = ""
    keyInput.PlaceholderText = "XXXX-XXXX-XXXX"
    keyInput.TextColor3 = Color3.fromRGB(118, 75, 162)
    keyInput.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
    keyInput.TextScaled = true
    keyInput.Font = Enum.Font.SourceSansBold
    keyInput.BorderSizePixel = 0
    keyInput.Parent = keyInputFrame

    local keyInputCornerBox = Instance.new("UICorner")
    keyInputCornerBox.CornerRadius = UDim.new(0, 8)
    keyInputCornerBox.Parent = keyInput

    local getKeyButton = Instance.new("TextButton")
    getKeyButton.Name = "GetKeyButton"
    getKeyButton.Size = UDim2.new(1, 0, 0, 35)
    getKeyButton.Position = UDim2.new(0, 0, 0, 110)
    getKeyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    getKeyButton.BackgroundTransparency = 0.1
    getKeyButton.Text = "🦋 Summon Dream Key"
    getKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyButton.TextScaled = true
    getKeyButton.Font = Enum.Font.SourceSansBold
    getKeyButton.BorderSizePixel = 0
    getKeyButton.TextStrokeTransparency = 0.7
    getKeyButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    getKeyButton.Parent = contentFrame

    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 10)
    getKeyCorner.Parent = getKeyButton

    local submitButton = Instance.new("TextButton")
    submitButton.Name = "SubmitButton"
    submitButton.Size = UDim2.new(1, 0, 0, 35)
    submitButton.Position = UDim2.new(0, 0, 0, 155)
    submitButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.BackgroundTransparency = 0.1
    submitButton.Text = "🌟 Ascend to Reality"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextScaled = true
    submitButton.Font = Enum.Font.SourceSansBold
    submitButton.BorderSizePixel = 0
    submitButton.TextStrokeTransparency = 0.7
    submitButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    submitButton.Parent = contentFrame

    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 10)
    submitCorner.Parent = submitButton

    local instructionsFrame = Instance.new("Frame")
    instructionsFrame.Name = "InstructionsFrame"
    instructionsFrame.Size = UDim2.new(1, 0, 0, 50)
    instructionsFrame.Position = UDim2.new(0, 0, 0, 200)
    instructionsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    instructionsFrame.BackgroundTransparency = 0.9
    instructionsFrame.BorderSizePixel = 0
    instructionsFrame.Parent = contentFrame

    local instructionsCorner = Instance.new("UICorner")
    instructionsCorner.CornerRadius = UDim.new(0, 10)
    instructionsCorner.Parent = instructionsFrame

    local instructionsText = Instance.new("TextLabel")
    instructionsText.Name = "InstructionsText"
    instructionsText.Size = UDim2.new(1, -16, 1, -16)
    instructionsText.Position = UDim2.new(0, 8, 0, 8)
    instructionsText.BackgroundTransparency = 1
    instructionsText.Text = "💫 Dream Guide:\n1. Enter key first • 2. Get dream key • 3. Ascend\n✨ Dreams become reality ✨"
    instructionsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructionsText.TextScaled = true
    instructionsText.Font = Enum.Font.SourceSans
    instructionsText.TextWrapped = true
    instructionsText.TextStrokeTransparency = 0.6
    instructionsText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    instructionsText.Parent = instructionsFrame

    local loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingFrame"
    loadingFrame.Size = UDim2.new(1, 0, 1, 0)
    loadingFrame.Position = UDim2.new(0, 0, 0, 0)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    loadingFrame.BackgroundTransparency = 0.4
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Visible = false
    loadingFrame.Parent = mainFrame
    local loadingCorner = Instance.new("UICorner")
    loadingCorner.CornerRadius = UDim.new(0, 18)
    loadingCorner.Parent = loadingFrame

    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(0, 180, 0, 35)
    loadingText.Position = UDim2.new(0.5, -90, 0.5, -17.5)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "🌙 Weaving dreams... 🌙"
    loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.SourceSansBold
    loadingText.TextStrokeTransparency = 0.5
    loadingText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    loadingText.Parent = loadingFrame

    return {
        screenGui = screenGui,
        mainFrame = mainFrame,
        statusLabel = statusLabel,
        keyInput = keyInput,
        getKeyButton = getKeyButton,
        submitButton = submitButton,
        closeButton = closeButton,
        loadingFrame = loadingFrame,
        loadingText = loadingText
    }
end

function KeySystemUI.createFloatingEffect(element)
    spawn(function()
        local originalPos = element.Position
        local floatTween = TweenService:Create(
            element,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Position = originalPos + UDim2.new(0, 0, 0, -2)}
        )
        floatTween:Play()
    end)
end

function KeySystemUI.animateButton(button, scale)
    local originalSize = button.Size
    local tween = TweenService:Create(
        button,
        TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(scale, 0, 0, originalSize.Y.Offset)}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        local returnTween = TweenService:Create(
            button,
            TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = originalSize}
        )
        returnTween:Play()
    end)
end

function KeySystemUI.showNotification(statusLabel, message, color)
    statusLabel.Text = message
    statusLabel.TextColor3 = color
    
    local tween = TweenService:Create(
        statusLabel,
        TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    tween:Play()
end

function KeySystemUI.addDreamHoverEffect(button, hoverTransparency, normalTransparency)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundTransparency = hoverTransparency}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundTransparency = normalTransparency}):Play()
    end)
end

function KeySystemUI.formatKeyInput(keyInput)
    keyInput:GetPropertyChangedSignal("Text"):Connect(function()
        local text = keyInput.Text:upper():gsub("[^%w]", "")
        if #text > 12 then
            text = text:sub(1, 12)
        end
        
        local formatted = ""
        for i = 1, #text do
            if i == 5 or i == 9 then
                formatted = formatted .. "-"
            end
            formatted = formatted .. text:sub(i, i)
        end
        
        if formatted ~= keyInput.Text then
            keyInput.Text = formatted
        end
    end)
end

function KeySystemUI.createEntranceAnimation(mainFrame)
    mainFrame.Position = UDim2.new(0.4, -140, -1, 0)
    local entranceTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.4, -140, 0.5, -150)}
    )
    entranceTween:Play()
end

function KeySystemUI.init(callbacks)
    local ui = KeySystemUI.createUI(callbacks, callbacks.config)
    
    KeySystemUI.createFloatingEffect(ui.getKeyButton)
    KeySystemUI.createFloatingEffect(ui.submitButton)
    KeySystemUI.addDreamHoverEffect(ui.getKeyButton, 0.05, 0.1)
    KeySystemUI.addDreamHoverEffect(ui.submitButton, 0.05, 0.1)
    KeySystemUI.addDreamHoverEffect(ui.closeButton, 0.1, 0.2)
    KeySystemUI.formatKeyInput(ui.keyInput)
    KeySystemUI.createEntranceAnimation(ui.mainFrame)
    
    ui.closeButton.MouseButton1Click:Connect(function()
        local exitTween = TweenService:Create(
            ui.mainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.4, -140, 1.5, 0)}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            ui.screenGui:Destroy()
        end)
    end)

    ui.getKeyButton.MouseButton1Click:Connect(function()
        KeySystemUI.animateButton(ui.getKeyButton, 0.95)
        
        local success, url = callbacks.openKeyLink()
        
        if success then
            KeySystemUI.showNotification(ui.statusLabel, "🦋 Ethereal portal opened! Link copied to dreams.", Color3.fromRGB(240, 147, 251))
        else
            KeySystemUI.showNotification(ui.statusLabel, "🦋 Ethereal portal opened! Manual copy needed.", Color3.fromRGB(240, 147, 251))
            print("Link: " .. url)
        end
    end)

    ui.submitButton.MouseButton1Click:Connect(function()
        KeySystemUI.animateButton(ui.submitButton, 0.95)
        
        local inputKey = ui.keyInput.Text
        
        if inputKey == "" then
            KeySystemUI.showNotification(ui.statusLabel, "💫 The dream key awaits your touch...", Color3.fromRGB(255, 193, 7))
            return
        end
        
        if callbacks.validateKey(inputKey) then
            KeySystemUI.showNotification(ui.statusLabel, "🌟 The key resonates with ethereal energy! 🌟", Color3.fromRGB(255, 255, 255))
            task.wait(1)
            
            ui.loadingFrame.Visible = true
            ui.loadingText.Text = "🌟 Ascending to reality... 🌟"
            
            task.wait(1)
            
            local success, message = callbacks.executeScript()
            
            if success then
                KeySystemUI.showNotification(ui.statusLabel, "✨ Dreams manifested successfully! ✨", Color3.fromRGB(255, 255, 255))
                task.wait(2)
                ui.screenGui:Destroy()
            else
                KeySystemUI.showNotification(ui.statusLabel, "💫 The dream fades... " .. message, Color3.fromRGB(255, 200, 200))
                ui.loadingFrame.Visible = false
            end
        else
            KeySystemUI.showNotification(ui.statusLabel, "✨ The dream key flickers... Check the pattern.", Color3.fromRGB(255, 200, 200))
            
            local originalPos = ui.keyInput.Position
            for i = 1, 6 do
                ui.keyInput.Position = originalPos + UDim2.new(0, math.random(-3, 3), 0, 0)
                task.wait(0.08)
            end
            ui.keyInput.Position = originalPos
        end
    end)

    ui.keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            ui.submitButton.MouseButton1Click:Fire()
        end
    end)
end

return KeySystemUI
