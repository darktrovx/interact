local interactions = require 'client.interactions'
local utils = require 'client.utils'
local settings = require 'shared.settings'
local playerState = LocalPlayer.state
local disableInteraction = false

-- CACHE
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local Wait = Wait
local IsControlJustPressed = IsControlJustPressed
local SetScriptGfxAlignParams = SetScriptGfxAlignParams
local ResetScriptGfxAlign = ResetScriptGfxAlign
local IsNuiFocused = IsNuiFocused
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedCuffed = IsPedCuffed
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord

local selected, unselected, interact, pin = settings.Textures.selected, settings.Textures.unselected, settings.Textures.interact, settings.Textures.pin

local currentSelection = 0
local currentInteraction = 0
local CurrentTarget = 0
local currentAlpha = 255

local function createOption(coords, option, id, width, showDot, alpha)
    utils.drawOption(coords, option.label, 'interactions_txd', currentSelection == id and selected or unselected, id - 1, width, showDot, alpha)
end

local nearby, nearbyAmount = {}, 0
local function CreateInteractions()
    for i = 1, nearbyAmount do
        local interaction = nearby[i]
        if not interaction then return end
        local coords = interaction.coords or utils.getCoordsFromInteract(interaction)

        local isPrimary = i == 1

        if isPrimary and currentInteraction ~= interaction.id then
            currentInteraction = interaction.id
            currentAlpha = 255
            currentSelection = 1
        end

        if GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z) then
            local isClose = isPrimary and (interaction.curDist <= interaction.interactDst) and (not interaction.entity or interaction.ignoreLos or interaction.entity == CurrentTarget)
            if isClose and currentAlpha < 0 then
                local options = interaction.options

                local alpha = currentAlpha * -1

                SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
                SetDrawOrigin(coords.x, coords.y, coords.z)
                DrawSprite('interactions_txd', interact, 0, 0, 0.0185, 0.03333333333333333, 0, 255, 255, 255, alpha)
                ResetScriptGfxAlign()

                local optionAmount = #options
                for j = 1, optionAmount do
                    createOption(coords, options[j], j, interaction.width, optionAmount > 1, alpha)
                end

                if currentSelection ~= 1 and (IsControlJustPressed(0, 172) or IsControlJustPressed(0, 15)) then
                    currentSelection -= 1
                elseif currentSelection ~= optionAmount and (IsControlJustPressed(0, 173) or IsControlJustPressed(0, 14)) then
                    currentSelection += 1
                end

                if IsControlJustPressed(0, 38) then
                    local option = options[currentSelection]

                    if option then
                        if option.action then
                            pcall(function() option.action(interaction.entity, interaction.coords, option.args) end)
                        elseif option.serverEvent then
                            TriggerServerEvent(option.serverEvent, option.args)
                        elseif option.event then
                            TriggerEvent(option.event, option)
                        end
                    end
                end

            else
                SetDrawOrigin(coords.x, coords.y, coords.z + 0.05)
                DrawSprite('interactions_txd', pin, 0, 0, 0.010, 0.025, 0, 255, 255, 255, currentAlpha)
            end

            ClearDrawOrigin()

            if isPrimary then
                if isClose then
                    currentAlpha = math.max(-255, currentAlpha - 10)
                else
                    currentAlpha = math.min(255, currentAlpha + 10)
                end
            end
        end
    end
end

local function isDisabled()
    if playerState.interactionsDisabled then
        return true
    end

    if settings.Disable.onDeath and (IsPedDeadOrDying(cache.ped) or playerState.isDead) then
        return true
    end

    if settings.Disable.onNuiFocus and IsNuiFocused() then
        return true
    end

    if settings.Disable.onVehicle and cache.vehicle then
        return true
    end

    if settings.Disable.onHandCuff and IsPedCuffed(cache.ped) then
        return true
    end

    return false
end

-- Fast thread
CreateThread(function ()
    lib.requestStreamedTextureDict('interactions_txd')
    while true do
        local wait = 500
        if nearbyAmount > 0 and not disableInteraction then
            wait = 0
            CreateInteractions()
        end
        Wait(wait)
    end
end)

-- Slow checker thread
local getCurrentTarget = require 'client.raycast'
local threadTimer = GetConvarInt('interact_thread', 250)
CreateThread(function()
    while true do
        disableInteraction = isDisabled()
        if disableInteraction then
            nearby, nearbyAmount = table.wipe(nearby), 0
            CurrentTarget = 0
        else
            CurrentTarget = getCurrentTarget() or 0
            nearby, nearbyAmount = interactions.getNearbyInteractions()
        end

        Wait(threadTimer)
    end
end)
