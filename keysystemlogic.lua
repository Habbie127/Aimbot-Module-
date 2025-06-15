local allowedPlaceId = 3678761576 
if game.PlaceId ~= allowedPlaceId then
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeySystemBlockedGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0.2, 0)
    frame.Position = UDim2.new(0.2, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = " •  This game is not supported by this script  • "
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextScaled = true
    text.Font = Enum.Font.Garamond
    text.Parent = frame
    task.delay(8, function()
        if gui then
            gui:Destroy()
        end
    end)
    return {}
end

local KeySystem = {}

local HttpService = game:GetService("HttpService")

local requestSending = false
local cachedLink, cachedTime = "", 0

-- Use environment functions
local fSetClipboard = setclipboard or toclipboard
local fRequest = request or http_request or syn.request
local fChar = string.char
local fToString = tostring
local fSub = string.sub
local fOsTime = os.time
local fRandom = math.random
local fFloor = math.floor
local fGetHwid = gethwid or function() return game:GetService("Players").LocalPlayer.UserId end

local onMessage = function(message)
	pcall(function()
		game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", { Text = message; })
	end)
end

local function encode(data)
	return HttpService:JSONEncode(data)
end

local function decode(data)
	return HttpService:JSONDecode(data)
end

local function digest(input)
	local inputStr = fToString(input)
	local hash = {}
	for i = 1, #inputStr do
		table.insert(hash, string.byte(inputStr, i))
	end
	local hex = ""
	for _, byte in ipairs(hash) do
		hex = hex .. string.format("%02x", byte)
	end
	return hex
end

local function generateNonce()
	local str = ""
	for _ = 1, 16 do
		str = str .. fChar(fFloor(fRandom() * 26) + 97)
	end
	return str
end

function KeySystem.init(service, secret, useNonce)
	local host = "https://api.platoboost.com"
	local response = fRequest({ Url = host .. "/public/connectivity", Method = "GET" })
	if response.StatusCode ~= 200 and response.StatusCode ~= 429 then
		host = "https://api.platoboost.net"
	end

	KeySystem._config = {
		host = host,
		service = service,
		secret = secret,
		useNonce = useNonce
	}
end

local MAX_LINK_LENGTH = 1000

function KeySystem.copyLink()
	local timeNow = fOsTime()
	if cachedTime + 1600 < timeNow then
		local cfg = KeySystem._config
		local res = fRequest({
			Url = cfg.host .. "/public/start",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = encode({
				service = cfg.service,
				identifier = digest(fGetHwid())
			})
		})
		if res.StatusCode == 200 then
			local data = decode(res.Body)
			if data.success then
				cachedLink = data.data.url
				if #cachedLink > MAX_LINK_LENGTH then
                    onMessage("Generated link is too long.")
                    return false
                end
				cachedTime = timeNow
			else
				onMessage(data.message)
			end
		else
			onMessage("Rate limit or failed to fetch link.")
		end
	end
	if fSetClipboard then
		fSetClipboard(cachedLink)
	end
end

function KeySystem.verifyKey(key)
	if requestSending then
		onMessage("Please wait for current request.")
		return false
	end
	requestSending = true

	local cfg = KeySystem._config
	local nonce = generateNonce()
	local endpoint = cfg.host .. "/public/whitelist/" .. fToString(cfg.service) .. "?identifier=" .. digest(fGetHwid()) .. "&key=" .. key
	if cfg.useNonce then
		endpoint = endpoint .. "&nonce=" .. nonce
	end

	local res = fRequest({ Url = endpoint, Method = "GET" })
	requestSending = false

	if res.StatusCode == 200 then
		local data = decode(res.Body)
		if data.success and data.data.valid then
			return true
		else
			if fSub(key, 1, 5) == "FREE_" then
				return KeySystem.redeemKey(key)
			else
				onMessage("Invalid key.")
			end
		end
	elseif res.StatusCode == 429 then
		onMessage("Rate limited.")
	else
		onMessage("Unknown error occurred.")
	end
	return false
end

function KeySystem.redeemKey(key)
	local cfg = KeySystem._config
	local nonce = generateNonce()
	local endpoint = cfg.host .. "/public/redeem/" .. fToString(cfg.service)
	local body = {
		identifier = digest(fGetHwid()),
		key = key
	}
	if cfg.useNonce then
		body.nonce = nonce
	end

	local res = fRequest({
		Url = endpoint,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = encode(body)
	})

	if res.StatusCode == 200 then
		local data = decode(res.Body)
		if data.success and data.data.valid then
			if not cfg.useNonce or data.data.hash == digest("true-" .. nonce .. "-" .. cfg.secret) then
				return true
			end
			onMessage("Integrity check failed.")
		else
			onMessage(data.message)
		end
	elseif res.StatusCode == 429 then
		onMessage("Rate limited.")
	else
		onMessage("Unknown error.")
	end
	return false
end

return KeySystem
