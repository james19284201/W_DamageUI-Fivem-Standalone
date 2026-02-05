local SETTINGS_FILE = "ui_settings.json"
local cachedSettings = {}

local function getKey(src)
    if GetPlayerIdentifierByType then
        local lic = GetPlayerIdentifierByType(src, "license")
        if lic and lic ~= "" then return lic end

        local fivem = GetPlayerIdentifierByType(src, "fivem")
        if fivem and fivem ~= "" then return fivem end
    end

    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == "license:" then return id end
    end

    return ("src:%s"):format(src)
end

local function loadSettings()
    local raw = LoadResourceFile(GetCurrentResourceName(), SETTINGS_FILE)
    if raw and raw ~= "" then
        local decoded = json.decode(raw)
        if type(decoded) == "table" then
            cachedSettings = decoded
            print("^2[DamageUI]^7 Loaded UI settings file")
            return
        end
    end

    cachedSettings = {}
    print("^3[DamageUI]^7 No UI settings file found, using defaults")
end

local function saveFile()
    SaveResourceFile(
        GetCurrentResourceName(),
        SETTINGS_FILE,
        json.encode(cachedSettings, { indent = true }),
        -1
    )
end

AddEventHandler("onResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    loadSettings()
end)

RegisterNetEvent("damageui:saveSettings", function(data)
    local src = source
    if type(data) ~= "table" then return end

    if type(data.x) ~= "number" or type(data.y) ~= "number" then return end
    if type(data.color) ~= "table" then return end
    if type(data.color.r) ~= "number" or type(data.color.g) ~= "number" or type(data.color.b) ~= "number" then return end

    data.x = math.max(0.0, math.min(1.0, data.x))
    data.y = math.max(0.0, math.min(1.0, data.y))
    data.color.r = math.max(0, math.min(255, math.floor(data.color.r)))
    data.color.g = math.max(0, math.min(255, math.floor(data.color.g)))
    data.color.b = math.max(0, math.min(255, math.floor(data.color.b)))

    local key = getKey(src)
    cachedSettings[key] = data
    saveFile()
end)

RegisterNetEvent("damageui:requestSettings", function()
    local src = source
    local key = getKey(src)
    TriggerClientEvent("damageui:loadSettings", src, cachedSettings[key])
end)
