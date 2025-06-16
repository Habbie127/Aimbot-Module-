-- KeySystemUIModule
local module = {}

function module.CreateUI(LocalPlayer, Lighting)
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "KeySystemUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    local blur = Instance.new("BlurEffect", Lighting)
    blur.Size = 12

    local frame = Instance.new("ImageLabel", gui)
    frame.Size = UDim2.new(0, 280, 0, 180)
    frame.Position = UDim2.new(0.5, -140, 0.6, -90)
    frame.BackgroundTransparency = 1
    frame.Image = "rbxassetid://76926193047725"

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.Text = "Enter Key"
    title.TextColor3 = Color3.fromRGB(60, 40, 20)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Garamond
    title.TextSize = 20

    local textbox = Instance.new("TextBox", frame)
    textbox.Size = UDim2.new(0.85, 0, 0, 30)
    textbox.Position = UDim2.new(0.075, 0, 0, 45)
    textbox.PlaceholderText = "Paste your key..."
    textbox.Font = Enum.Font.Garamond
    textbox.TextSize = 16
    textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    textbox.BackgroundTransparency = 0.7
    textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textbox.BorderSizePixel = 1

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(0.4, -5, 0, 28)
    submit.Position = UDim2.new(0.075, 0, 0, 85)
    submit.Text = "Submit"
    submit.Font = Enum.Font.Garamond
    submit.TextSize = 16
    submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    submit.BackgroundColor3 = Color3.fromRGB(80, 50, 30)

    local copy = Instance.new("TextButton", frame)
    copy.Size = UDim2.new(0.4, -5, 0, 28)
    copy.Position = UDim2.new(0.525, 10, 0, 85)
    copy.Text = "Copy Key"
    copy.Font = Enum.Font.Garamond
    copy.TextSize = 16
    copy.TextColor3 = Color3.fromRGB(255, 255, 255)
    copy.BackgroundColor3 = Color3.fromRGB(80, 50, 30)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(0.85, 0, 0, 25)
    status.Position = UDim2.new(0.075, 0, 0, 125)
    status.Text = ""
    status.Font = Enum.Font.Garamond
    status.TextSize = 14
    status.TextColor3 = Color3.fromRGB(128, 64, 0)
    status.BackgroundTransparency = 1
    status.TextWrapped = true

    local timeGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    timeGui.Name = "TimeDisplayUI"
    timeGui.ResetOnSpawn = false
    timeGui.Enabled = false

    local timeLabel = Instance.new("TextLabel", timeGui)
    timeLabel.Size = UDim2.new(0, 100, 0, 30)
    timeLabel.Position = UDim2.new(1, -5, 0, 5)
    timeLabel.AnchorPoint = Vector2.new(1, 1)
    timeLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Font = Enum.Font.Garamond
    timeLabel.TextSize = 16
    timeLabel.Text = ""
    timeLabel.TextXAlignment = Enum.TextXAlignment.Center
    timeLabel.BorderSizePixel = 0
    timeLabel.BackgroundTransparency = 0.8

    for _, v in pairs({frame, textbox, submit, copy, timeLabel}) do
        local corner = Instance.new("UICorner", v)
        corner.CornerRadius = UDim.new(0, 12)
    end

    return {
        GUI = gui,
        Blur = blur,
        TextBox = textbox,
        Submit = submit,
        Copy = copy,
        Status = status,
        TimeGUI = timeGui,
        TimeLabel = timeLabel
    }
end

return module
