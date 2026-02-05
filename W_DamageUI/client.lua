-- HEALING LOCATIONS, EDIT ME :)
local HealingSpots = {
    vector3(1853.91, 3687.96, 34.27)
}

-- EXAMPLE OF MULTIPLE.

-- local HealingSpots = {
   -- vector3(1853.91, 3687.96, 34.27),
    -- vector3(312.18, -592.77, 43.28),
    -- vector3(-449.67, -340.83, 34.50),
    -- vector3(1839.62, 3672.93, 34.27) 
-- }

local damageUISettings = {
    x = 0.85,
    y = 0.78,
    color = { r = 255, g = 80, b = 80 },
    displayMode = "always" -- "always" | "injured"
}

local settingsLoaded = false
local forceClearEffects = false

local injuries = {}

local function ShowDamageUI()
    SendNUIMessage({ type = "damageShow" })
end

local function HideDamageUI()
    SendNUIMessage({ type = "damageHide" })
end

local function UpdateDamageUIDisplay()
    if damageUISettings.displayMode == "always" then
        ShowDamageUI()
        return
    end

    for _, v in pairs(injuries) do
        if v > 0 then
            ShowDamageUI()
            return
        end
    end

    HideDamageUI()
end

local function RestoreFullHealthIfHealed()
    local ped = PlayerPedId()

    for _, v in pairs(injuries) do
        if v > 0 then
            return
        end
    end

    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    ResetPedMovementClipset(ped, 0.25)
    StopScreenEffect("DrugsTrevorClownsFight")
    DoScreenFadeIn(0)

    headDizzyCount = 0
    isBlackingOut = false
end

CreateThread(function()
    Wait(1200)
    if not settingsLoaded then
        SendNUIMessage({
            type = "damageUpdate",
            x = damageUISettings.x,
            y = damageUISettings.y,
            color = damageUISettings.color,
            displayMode = damageUISettings.displayMode
        })

        UpdateDamageUIDisplay()
    end
end)

AddEventHandler("onClientResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    TriggerServerEvent("damageui:requestSettings")
end)

RegisterNetEvent("damageui:loadSettings", function(settings)
    if type(settings) ~= "table" then
        settingsLoaded = false
        return
    end

    damageUISettings.x = (type(settings.x) == "number") and settings.x or damageUISettings.x
    damageUISettings.y = (type(settings.y) == "number") and settings.y or damageUISettings.y

    if type(settings.color) == "table" then
        damageUISettings.color = {
            r = tonumber(settings.color.r) or damageUISettings.color.r,
            g = tonumber(settings.color.g) or damageUISettings.color.g,
            b = tonumber(settings.color.b) or damageUISettings.color.b
        }
    end

    if settings.displayMode == "always" or settings.displayMode == "injured" then
        damageUISettings.displayMode = settings.displayMode
    end

    settingsLoaded = true

    SendNUIMessage({
        type = "damageUpdate",
        x = damageUISettings.x,
        y = damageUISettings.y,
        color = damageUISettings.color,
        displayMode = damageUISettings.displayMode
    })

    UpdateDamageUIDisplay()
end)

local isConfigOpen = false

RegisterCommand("cdamageui", function()
    isConfigOpen = not isConfigOpen
    SetNuiFocus(isConfigOpen, isConfigOpen)

    SendNUIMessage({
        type = "toggleConfig",
        state = isConfigOpen,
        settings = damageUISettings
    })
end, false)

RegisterNUICallback("updateDamageUI", function(data, cb)
    if data.axis == "x" then
        damageUISettings.x = math.max(0.0, math.min(1.0, damageUISettings.x + (data.value or 0)))
    elseif data.axis == "y" then
        damageUISettings.y = math.max(0.0, math.min(1.0, damageUISettings.y + (data.value or 0)))
    end

    if data.color then
        damageUISettings.color = data.color
    end

    if data.displayMode == "always" or data.displayMode == "injured" then
        damageUISettings.displayMode = data.displayMode
        UpdateDamageUIDisplay()
    end

    SendNUIMessage({
        type = "damageUpdate",
        x = damageUISettings.x,
        y = damageUISettings.y,
        color = damageUISettings.color,
        displayMode = damageUISettings.displayMode
    })

    TriggerServerEvent("damageui:saveSettings", damageUISettings)

    cb("ok")
end)

RegisterNUICallback("closeConfig", function(_, cb)
    isConfigOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        type = "toggleConfig",
        state = false
    })

    cb("ok")
end)

RegisterNUICallback("closeMedicalMenu", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("healBodyPart", function(data, cb)
    if isHealingPart then
        cb("busy")
        return
    end

    local part = data.part
    if not injuries[part] or injuries[part] <= 0 then
        cb("no_injury")
        return
    end

    isHealingPart = true
    forceClearEffects = true

    SendNUIMessage({
        type = "medicalProgress",
        duration = 2000
    })

    CreateThread(function()
        Wait(2000)

        injuries[part] = 0

        local ped = PlayerPedId()
        ResetPedMovementClipset(ped, 0.25)
        StopScreenEffect("DrugsTrevorClownsFight")
        DoScreenFadeIn(0)

        headDizzyCount = 0
        isBlackingOut = false

        SendNUIMessage({
            type = "damage",
            part = part,
            amount = 0
        })

        local fullyHealed = true
        for _, v in pairs(injuries) do
            if v > 0 then
                fullyHealed = false
                break
            end
        end

        if fullyHealed then
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            SetNuiFocus(false, false)
            SendNUIMessage({ type = "closeMedicalMenu" })
        end

        UpdateDamageUIDisplay()

        Wait(100)
        forceClearEffects = false

        isHealingPart = false
    end)

    cb("ok")
end)

local CHECK_INTERVAL = 50
local RAGDOLL_CHANCE = 25
local headDizzyCount = 0
local isBlackingOut = false
local lastHealTime = 0
local HEAL_COOLDOWN = 60000
local HEAL_DURATION = 10000
local isBeingHealed = false
local healStartTime = 0
local healSpot = nil
local isInjured = false

injuries = {
    head = 0,
    torso = 0,
    leftArm = 0,
    rightArm = 0,
    leftLeg = 0,
    rightLeg = 0
}

local nuiHealingVisible = false

local function ShowHealUI()
    if nuiHealingVisible then return end
    nuiHealingVisible = true
    SendNUIMessage({ type = "healShow" })
end

local function HideHealUI()
    if not nuiHealingVisible then return end
    nuiHealingVisible = false
    SendNUIMessage({ type = "healHide" })
end

local function HasAnyInjury()
    for _, v in pairs(injuries) do
        if v > 0 then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local now = GetGameTimer()

        if isBeingHealed and healSpot then
            Wait(0)

            local dist = #(coords - healSpot)

            if dist > 2.0 then
                isBeingHealed = false
                healSpot = nil
                FreezeEntityPosition(ped, false)
                HideHealUI()
            else
                local elapsed = now - healStartTime
                local progress = math.min(elapsed / HEAL_DURATION, 1.0)

                ShowHealUI()
                SendNUIMessage({
                    type = "healProgress",
                    progress = progress
                })

                if elapsed >= HEAL_DURATION then
                    HealPlayer()
                    lastHealTime = now
                    isBeingHealed = false
                    healSpot = nil
                    FreezeEntityPosition(ped, false)
                    HideHealUI()
                    isInjured = false

                    UpdateDamageUIDisplay()
                end
            end
        else
            local sleep = true

            for _, spot in ipairs(HealingSpots) do
                local dist = #(coords - spot)

                if dist < 5.0 then
                    sleep = false

local pulse = 0.3 + (math.sin(GetGameTimer() / 500) * 0.15)

DrawMarker(
    1,
    spot.x, spot.y, spot.z - 1.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    1.2, 1.2, 0.6,
    0, 200, 50, 120,
    false, true, 2, false, nil, nil, false
)

                    if dist < 1.5 then
                        if now - lastHealTime < HEAL_COOLDOWN then
                            DrawText3D(
                                spot.x, spot.y, spot.z + 0.2,
                                "Medical staff are busy, please wait..."
                            )
                        else
                            DrawText3D(
                                spot.x, spot.y, spot.z + 0.2,
                                "[E] Receive Medical Treatment"
                            )

                            if IsControlJustPressed(0, 38) then
                                SetNuiFocus(true, true)
                                SendNUIMessage({ type = "openMedicalMenu" })
                            end
                        end
                    end
                end
            end

            if sleep then
                Wait(500)
            else
                Wait(0)
            end
        end
    end
end)

function HealPlayer()
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)

    SetEntityHealth(ped, maxHealth)

    for k in pairs(injuries) do
        injuries[k] = 0
    end

    UpdateDamageUIDisplay()

    headDizzyCount = 0
    isBlackingOut = false

    SendNUIMessage({ type = "heal" })
    RestoreFullHealthIfHealed()
    ResetPedMovementClipset(ped, 0.25)
    StopScreenEffect("DrugsTrevorClownsFight")
    DoScreenFadeIn(0)

    TriggerEvent("chat:addMessage", {
        args = { "^2Medical", "You have been fully treated." }
    })

    SetNuiFocus(false, false)
    SendNUIMessage({ type = "closeMedicalMenu" })
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)

        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 120)
    end
end

CreateThread(function()
    while true do
        Wait(250)

        local ped = PlayerPedId()
        local hasInjury = false

        for _, v in pairs(injuries) do
            if v > 0 then
                hasInjury = true
                break
            end
        end

        if hasInjury then
            SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        else
            SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
            local maxHealth = GetEntityMaxHealth(ped)
            if GetEntityHealth(ped) < maxHealth then
                SetEntityHealth(ped, maxHealth)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(200)

        local ped = PlayerPedId()

        if injuries.leftLeg == 0 and injuries.rightLeg == 0 then
            ResetPedMovementClipset(ped, 0.25)
        else
            if injuries.leftLeg >= 2 or injuries.rightLeg >= 2 then
                RequestAnimSet("move_m@injured")
                while not HasAnimSetLoaded("move_m@injured") do Wait(10) end
                SetPedMovementClipset(ped, "move_m@injured", 1.0)
            else
                ResetPedMovementClipset(ped, 0.25)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        local ped = PlayerPedId()
        local headSeverity = injuries.head

        if headSeverity > 0 and not isBlackingOut then
            local chance = 5
            local duration = 1500

            if headSeverity >= 2 then
                chance = 10
                duration = 2500
            end

            if headSeverity >= 3 then
                chance = 18
                duration = 4000
            end

            if math.random(1, 100) <= chance then
                StartScreenEffect("DrugsTrevorClownsFight", 0, true)
                Wait(duration)
                StopScreenEffect("DrugsTrevorClownsFight")

                headDizzyCount = headDizzyCount + 1

                if headDizzyCount >= 10 then
                    isBlackingOut = true

                    DoScreenFadeOut(800)
                    Wait(800)

                    if IsPedOnFoot(ped) then
                        SetPedToRagdoll(ped, 4000, 4000, 0, false, false, false)
                    end

                    Wait(2500)
                    DoScreenFadeIn(1200)

                    headDizzyCount = 0
                    isBlackingOut = false
                end
            end
        end
    end
end)

CreateThread(function()
    local ped = PlayerPedId()
    local lastHealth = GetEntityHealth(ped)
    local wasFalling = false

    while true do
        Wait(CHECK_INTERVAL)

        ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local maxHealth = GetEntityMaxHealth(ped)

        if IsPedFalling(ped) then
            wasFalling = true
        end

        if health < lastHealth then
            local damageAmount = lastHealth - health
            local hit, bone = GetPedLastDamageBone(ped)

            if hit then
                local part = "torso"

                if bone == 31086 then part = "head" end
                if bone == 18905 then part = "leftArm" end
                if bone == 57005 then part = "rightArm" end
                if bone == 45509 then part = "leftLeg" end
                if bone == 51826 then part = "rightLeg" end

                local severity = 1
                if damageAmount > 15 then severity = 2 end
                if damageAmount > 30 then severity = 3 end

                injuries[part] = math.min(3, injuries[part] + severity)

                SendNUIMessage({
                    type = "damage",
                    part = part,
                    amount = severity
                })

                isInjured = true
                UpdateDamageUIDisplay()

                ClearPedLastDamageBone(ped)

            elseif wasFalling then
                if damageAmount <= 10 then
                    injuries.leftLeg = math.min(3, injuries.leftLeg + 1)
                    injuries.rightLeg = math.min(3, injuries.rightLeg + 1)

                    SendNUIMessage({ type = "damage", part = "leftLeg", amount = 1 })
                    SendNUIMessage({ type = "damage", part = "rightLeg", amount = 1 })

                elseif damageAmount <= 25 then
                    injuries.leftLeg = math.min(3, injuries.leftLeg + 2)
                    injuries.rightLeg = math.min(3, injuries.rightLeg + 2)
                    injuries.torso = math.min(3, injuries.torso + 1)

                    SendNUIMessage({ type = "damage", part = "leftLeg", amount = 2 })
                    SendNUIMessage({ type = "damage", part = "rightLeg", amount = 2 })
                    SendNUIMessage({ type = "damage", part = "torso", amount = 1 })

                else
                    injuries.torso = math.min(3, injuries.torso + 3)
                    SendNUIMessage({ type = "damage", part = "torso", amount = 3 })

                    if injuries.leftLeg >= 2 and injuries.rightLeg >= 2 then
                        if math.random(1, 100) <= RAGDOLL_CHANCE then
                            SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
                        end
                    end
                end

                UpdateDamageUIDisplay()
            end
        end

        if health >= maxHealth and lastHealth < maxHealth then
            HideHealUI()

            for k in pairs(injuries) do
                injuries[k] = 0
            end

            SendNUIMessage({ type = "heal" })
            ResetPedMovementClipset(ped, 0.25)
            StopScreenEffect("DrugsTrevorClownsFight")

            UpdateDamageUIDisplay()
        end

        if not IsPedFalling(ped) then
            wasFalling = false
        end

        lastHealth = health
    end
end)

CreateThread(function()
    local lastFall = 0

    while true do
        Wait(1200)

        local ped = PlayerPedId()
        local now = GetGameTimer()

        if not IsPedOnFoot(ped) or IsPedRagdoll(ped) then
            goto continue
        end

        if now - lastFall < 8000 then
            goto continue
        end

        local left = injuries.leftLeg
        local right = injuries.rightLeg

        if left == 0 and right == 0 then
            goto continue
        end

        local moveMult = 1.0
        if IsPedRunning(ped) then moveMult = 1.4 end
        if IsPedSprinting(ped) then moveMult = 1.8 end

        local chance = 0

        if (left > 0 and right == 0) or (right > 0 and left == 0) then
            local sev = math.max(left, right)
            if sev == 1 then
                chance = 0.5
            elseif sev >= 2 then
                chance = 1.5
            end
        end

        if left > 0 and right > 0 then
            if left == 1 and right == 1 then
                chance = 1.2
            elseif left >= 2 and right >= 2 then
                chance = 3.0
            else
                chance = 2.0
            end
        end

        chance = chance * moveMult
        if chance > 6 then chance = 6 end

        if chance > 0 and math.random(1, 100) <= chance then
            lastFall = now
            SetPedToRagdoll(ped, 1600, 1600, 0, false, false, false)
        end

        ::continue::
    end
end)

local DEFAULT_SETTINGS = {
    x = 0.85,
    y = 0.78,
    color = { r = 255, g = 80, b = 80 },
    displayMode = "always"
}

RegisterNUICallback("resetDamageUI", function(_, cb)
    damageUISettings = {
        x = DEFAULT_SETTINGS.x,
        y = DEFAULT_SETTINGS.y,
        color = {
            r = DEFAULT_SETTINGS.color.r,
            g = DEFAULT_SETTINGS.color.g,
            b = DEFAULT_SETTINGS.color.b
        },
        displayMode = DEFAULT_SETTINGS.displayMode
    }

    SendNUIMessage({
        type = "damageUpdate",
        x = damageUISettings.x,
        y = damageUISettings.y,
        color = damageUISettings.color,
        displayMode = damageUISettings.displayMode
    })

    UpdateDamageUIDisplay()

    TriggerServerEvent("damageui:saveSettings", damageUISettings)

    cb("ok")
end)
