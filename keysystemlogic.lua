local allowedPlaceId = 3678761576 -- 🔁 Replace with your real game ID
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
    text.Text = "🚫 This game is not supported by this script."
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

local service = 4361 
local secret = "b6792e56-46d0-4519-a5a7-1b117076e0a3" 
local useNonce = true
local cachedLink, cachedTime = "", 0
local requestSending = false

local function lEncode(data)
    return HttpService:JSONEncode(data)
end

local function lDecode(data)
    return HttpService:JSONDecode(data)
end

local function lDigest(input)
    local inputStr = tostring(input)
    local hash = {}
    for i = 1, #inputStr do
        table.insert(hash, string.byte(inputStr, i))
    end
    local hashHex = ""
    for _, byte in ipairs(hash) do
        hashHex = hashHex .. string.format("%02x", byte)
    end
    return hashHex
end

local function generateNonce()
    local str = ""
    for _ = 1, 16 do
        str = str .. string.char(math.random(97, 122))
    end
    return str
end

local function cacheLink()
    if cachedTime + (20 * 60) < os.time() then
        local response = request({
            Url = "https://api.platoboost.com/public/start",
            Method = "POST",
            Body = lEncode({
                service = service,
                identifier = lDigest(game.Players.LocalPlayer.UserId)
            }),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })

        if response.StatusCode == 200 then
            local decoded = lDecode(response.Body)
            if decoded.success then
                cachedLink = decoded.data.url
                cachedTime = os.time()
                return true, cachedLink
            else
                return false, decoded.message
            end
        end
    else
        return true, cachedLink
    end
end

function KeySystem.redeemKey(key)
    local nonce = generateNonce()
    local endpoint = "https://api.platoboost.com/public/redeem/" .. tostring(service)
    local body = {
        identifier = lDigest(game.Players.LocalPlayer.UserId),
        key = key
    }

    if useNonce then
        body.nonce = nonce
    end

    local response = request({
        Url = endpoint,
        Method = "POST",
        Body = lEncode(body),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            return true
        else
            return false, decoded.message
        end
    else
        return false, "Server error"
    end
end

function KeySystem.verifyKey(key)
    if requestSending then
        return false, "A request is already being sent."
    else
        requestSending = true
    end

    local nonce = generateNonce()
    local endpoint = "https://api.platoboost.com/public/whitelist/" .. tostring(service) .. "?identifier=" .. lDigest(game.Players.LocalPlayer.UserId) .. "&key=" .. key

    if useNonce then
        endpoint = endpoint .. "&nonce=" .. nonce
    end

    local response = request({
        Url = endpoint,
        Method = "GET"
    })

    requestSending = false

    if response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            return true
        else
            return false, decoded.message
        end
    else
        return false, "Server error"
    end
end

return KeySystem
