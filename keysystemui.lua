local KeySystemUI = {}

function KeySystemUI.createUI(KeySystem, onSuccess)
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")

	local player = Players.LocalPlayer
	local ScreenGui = Instance.new("ScreenGui")
	local Frame = Instance.new("ImageLabel")
	local title = Instance.new("TextLabel")
	local Getkey = Instance.new("TextButton")
	local Checkkey = Instance.new("TextButton")
	local TextBox = Instance.new("TextBox")
	local TextLabel = Instance.new("TextLabel")

	-- Blur Effect
	local blur = Instance.new("BlurEffect")
	blur.Size = 25
	blur.Name = "KeySystemBlur"
	blur.Parent = Lighting

	ScreenGui.Parent = player:WaitForChild("PlayerGui")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	Frame.Parent = ScreenGui
	Frame.BackgroundColor3 = Color3.fromRGB(76, 76, 76)
	Frame.BackgroundTransparency = 1
	Frame.ImageTransparency = 0
	Frame.Image = "rbxassetid://76926193047725"
	Frame.Position = UDim2.new(0.5, -140, 0.5, -90)
	Frame.Size = UDim2.new(0, 280, 0, 180)
	Frame.ScaleType = Enum.ScaleType.Crop
	Frame.SliceCenter = Rect.new(30, 30, 300, 300)

	title.Parent = Frame
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.Text = "Enter Key"
	title.TextColor3 = Color3.fromRGB(60, 40, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Garamond
	title.TextSize = 20

	Getkey.Name = "Getkey"
	Getkey.Parent = Frame
	Getkey.BackgroundColor3 = Color3.fromRGB(80, 50, 30)
	Getkey.Position = UDim2.new(0.525, 10, 0, 85)
	Getkey.Size = UDim2.new(0.4, -5, 0, 28)
	Getkey.Font = Enum.Font.Garamond
	Getkey.Text = "Get Link"
	Getkey.TextColor3 = Color3.fromRGB(255, 255, 255)
	Getkey.TextSize = 16

	Checkkey.Name = "Checkkey"
	Checkkey.Parent = Frame
	Checkkey.BackgroundColor3 = Color3.fromRGB(80, 50, 30)
	Checkkey.Position = UDim2.new(0.075, 0, 0, 85)
	Checkkey.Size = UDim2.new(0.4, -5, 0, 28)
	Checkkey.Font = Enum.Font.Garamond
	Checkkey.Text = "Submit"
	Checkkey.TextColor3 = Color3.fromRGB(255, 255, 255)
	Checkkey.TextSize = 16

	TextBox.Parent = Frame
	TextBox.Size = UDim2.new(0.85, 0, 0, 30)
	TextBox.Position = UDim2.new(0.075, 0, 0, 45)
	TextBox.PlaceholderText = "Paste your key..."
	TextBox.Text = ""
	TextBox.Font = Enum.Font.Garamond
	TextBox.TextSize = 16
	TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	TextBox.BackgroundTransparency = 0.3
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.BorderSizePixel = 1

	TextLabel.Parent = Frame
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0.075, 0, 0, 125)
	TextLabel.Size = UDim2.new(0.85, 0, 0, 25)
	TextLabel.Font = Enum.Font.Garamond
	TextLabel.Text = ""
	TextLabel.TextColor3 = Color3.fromRGB(128, 64, 0)
	TextLabel.TextSize = 14
	TextLabel.TextWrapped = true

	local function addUICorner(obj)
		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0, 12)
		uic.Parent = obj
	end

	addUICorner(Frame)
	addUICorner(Getkey)
	addUICorner(Checkkey)
	addUICorner(TextBox)

	local function removeUI()
		ScreenGui:Destroy()
		local existingBlur = Lighting:FindFirstChild("KeySystemBlur")
		if existingBlur then existingBlur:Destroy() end
	end

	TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		TextLabel.Text = TextBox.Text
	end)

	Checkkey.MouseButton1Down:Connect(function()
		if TextBox and TextBox.Text then
			local success = KeySystem.verifyKey(TextBox.Text)
			if success then
				removeUI()
				onSuccess()
			else
				TextLabel.Text = "Key is invalid"
			end
		end
	end)

	Getkey.MouseButton1Down:Connect(function()
		KeySystem.copyLink()
	end)
end

return KeySystemUI