local CURRENT_SELECTION = 1
local CURRENT_OPTION = 0
local CACHED_OPTIONS = {}


-- CACHE
local GetEntityCoords = GetEntityCoords
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local Wait = Wait
local IsControlJustPressed = IsControlJustPressed
local SetScriptGfxAlignParams = SetScriptGfxAlignParams
local ResetScriptGfxAlign = ResetScriptGfxAlign

local Utils = require 'client.utilities'
local Settings = require 'config.settings'
local Textures = Settings.Textures

local selected, unselected, interact, pin = Textures.selected, Textures.unselected, Textures.interact, Textures.pin

local drawOption, getCoordsFromInteract, getOptionsWidth in Utils

local function createOptions(coords, options)
    local width = getOptionsWidth(options)
    if #options == 1 then
        if options[1].canInteract then
            if options[1].canInteract() then
                drawOption(coords, options[1].label, 'interactions_txd', selected, 0, width, false)
            end
        else
            drawOption(coords, options[1].label, 'interactions_txd', selected, 0, width, false)
        end
    else
        for i = 1, #options do
            if options[i].canInteract then
                if options[i].canInteract() then
                    drawOption(coords, options[i].label, 'interactions_txd', CURRENT_SELECTION == i and selected or unselected, i - 1, width, true)
                end
            else
                drawOption(coords, options[i].label, 'interactions_txd', CURRENT_SELECTION == i and selected or unselected, i - 1, width, true)
            end
        end
    end
end

local function CheckCanInteract(interaction)
    local avail = 0
    for optionIndex, option in ipairs(interaction.options) do
        if option.canInteract then
            if option.canInteract() then
                return true
            end
        else
            return true
        end
    end
    return false
end

local table_type = table.type

local nearby = {}
local function CreateInteractions()
    for i = 1, #nearby do
        local interaction = nearby[i]
        local coords = interaction.coords or getCoordsFromInteract(interaction)

        if CheckCanInteract(interaction) then

            if GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z) then
                if i == 1 and interaction.curDist <= interaction.interactDst and (interaction.entity and interaction.entity == CurrentTarget) then
                    if interaction.id ~= CURRENT_OPTION then
                        CURRENT_OPTION = interaction.id
                        CURRENT_SELECTION = 1
                    end

                    local options = interaction.options

                    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
                    SetDrawOrigin(coords.x, coords.y, coords.z)
                    DrawSprite('interactions_txd', interact, 0, 0, 0.0185, 0.03333333333333333, 0, 255, 255, 255, 255)
                    ResetScriptGfxAlign()

                    if IsControlJustPressed(0, 38) then
                        local option = options[CURRENT_SELECTION]
                        if option.action then
                            option.action(interaction.entity, interaction.coords, option.args)
                        elseif option.serverEvent then
                            TriggerServerEvent(option.serverEvent, option.args)
                        elseif option.event then
                            TriggerEvent(option.event, option)
                        end
                    end

                    if table_type(options) ~= 'empty' then
                        createOptions(coords, options)

                        if CURRENT_SELECTION ~= 1 and (IsControlJustPressed(0, 172) or IsControlJustPressed(0, 15)) then
                            CURRENT_SELECTION -= 1
                        elseif CURRENT_SELECTION ~= #options and (IsControlJustPressed(0, 173) or IsControlJustPressed(0, 14)) then
                            CURRENT_SELECTION += 1
                        end
                    end

                else
                    SetDrawOrigin(coords.x, coords.y, coords.z + 0.05)
                    DrawSprite('interactions_txd', pin, 0, 0, 0.010, 0.02, 0, 255, 255, 255, 255)
                end

                ClearDrawOrigin()
            end
        end
    end
end

local thread = false
local function nearbyThread()
    if thread then
        return
    end

    thread = true
    lib.requestStreamedTextureDict('interactions_txd')

    while thread do
        CreateInteractions()
        Wait(0)
    end

    SetStreamedTextureDictAsNoLongerNeeded('interactions_txd')
end

local Interactions = require 'client.interactions'

CreateThread(function()
    while true do
        nearby = Interactions.getNearbyInteractions()

        if nearby and table.type(nearby) == 'array' then
            CreateThread(nearbyThread)
        elseif thread then
            thread = false
        end

        Wait(250)
    end
end)
