-- ModuleScript: KeySystemModule

local KeySystem = {} 

local service = 4361
local secret = "b6792e56-46d0-4519-a5a7-1b117076e0a3"
local useNonce = true
local HttpService = game:GetService("HttpService")

local requestSending = false
local cachedLink, cachedTime = "", 0
local fSetClipboard, fRequest, fStringChar, fToString, fStringSub, fOsTime, fMathRandom, fMathFloor, fGetHwid =
    setclipboard or toclipboard,
    request or http_request,
    string.char,
    tostring,
    string.sub,
    os.time,
    math.random,
    math.floor,
    gethwid or function()
        return game:GetService("Players").LocalPlayer.UserId
    end

local host = "https://api.platoboost.com"
local hostResponse = fRequest({ Url = host .. "/public/connectivity", Method = "GET" })
if hostResponse.StatusCode ~= 200 and hostResponse.StatusCode ~= 429 then
    host = "https://api.platoboost.net"
end

local function lEncode(data) return HttpService:JSONEncode(data) end
local function lDecode(data) return HttpService:JSONDecode(data) end

local function lDigest(input)
    local inputStr = tostring(input)
    local hash = {}
    for i = 1, #inputStr do table.insert(hash, string.byte(inputStr, i)) end
    local hashHex = ""
    for _, byte in ipairs(hash) do hashHex = hashHex .. string.format("%02x", byte) end
    return hashHex
end

local function generateNonce()
    local str = ""
    for _ = 1, 16 do
        str = str .. fStringChar(fMathFloor(fMathRandom() * (122 - 97 + 1)) + 97)
    end
    return str
end

function KeySystem.copyLink()
    if cachedTime + (10 * 60) < fOsTime() then
        local response = fRequest({
            Url = host .. "/public/start",
            Method = "POST",
            Body = lEncode({
                service = service,
                identifier = lDigest(fGetHwid())
            }),
            Headers = { ["Content-Type"] = "application/json" }
        })

        if response.StatusCode == 200 then
            local decoded = lDecode(response.Body)
            if decoded.success then
                cachedLink = decoded.data.url
                cachedTime = fOsTime()
                fSetClipboard(cachedLink)
                return true, cachedLink
            end
        end
    else
        fSetClipboard(cachedLink)
        return true, cachedLink
    end
end

function KeySystem.redeemKey(key)
    local nonce = generateNonce()
    local endpoint = host .. "/public/redeem/" .. fToString(service)

    local body = {
        identifier = lDigest(fGetHwid()),
        key = key
    }
    if useNonce then body.nonce = nonce end

    local response = fRequest({
        Url = endpoint,
        Method = "POST",
        Body = lEncode(body),
        Headers = { ["Content-Type"] = "application/json" }
    })

    if response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            if useNonce then
                return decoded.data.hash == lDigest("true" .. "-" .. nonce .. "-" .. secret)
            end
            return true
        end
    end

    return false
end

function KeySystem.verifyKey(key)
    if requestSending then return false end
    requestSending = true

    local nonce = generateNonce()
    local endpoint = host .. "/public/whitelist/" .. fToString(service) ..
        "?identifier=" .. lDigest(fGetHwid()) .. "&key=" .. key
    if useNonce then endpoint = endpoint .. "&nonce=" .. nonce end

    local response = fRequest({ Url = endpoint, Method = "GET" })
    requestSending = false

    if response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            return true
        else
            if fStringSub(key, 1, 5) == "FREE_" then
                return KeySystem.redeemKey(key)
            end
        end
    end
    return false
end

return KeySystem
