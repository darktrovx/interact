local textures = require 'shared.settings'.Textures
local log = require 'shared.log'

local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextColour = SetTextColour
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local SetTextCentre = SetTextCentre
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local SetTextJustification = SetTextJustification
local EndTextCommandDisplayText = EndTextCommandDisplayText
local SetScriptGfxAlignParams = SetScriptGfxAlignParams
local SetDrawOrigin = SetDrawOrigin
local ResetScriptGfxAlign = ResetScriptGfxAlign
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local DoesEntityExist = DoesEntityExist
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local IsEntityAPed = IsEntityAPed
local GetEntityCoords = GetEntityCoords

local utils = {}

function utils.getNet(entity)
    return NetworkGetNetworkIdFromEntity(entity)
end

function utils.getEntity(netID)
    return NetworkGetEntityFromNetworkId(netID)
end

function utils.getTrunkOffset(entity)
    local min, _ = GetModelDimensions(GetEntityModel(entity))
    return GetOffsetFromEntityInWorldCoords(entity, 0.0, min.y - 0.5, 0.0)
end

function utils.getOptionsWidth(options)
    if IsDuplicityVersion() then
        log:error('This function is not available on server side')
        return
    end

    local width = 0.0

    if options and table.type(options) == 'array' then
        for i = 1, #options do
            local data = options[i]
            local factor = (string.len(data.label)) / 370
            local newWidth = 0.03 + factor

            if newWidth > width then
                width = newWidth
            end
        end
    end

    return width
end

function utils.getCoordsFromInteract(interaction)
    if interaction.entity then
        if DoesEntityExist(interaction.entity) then
            if interaction.bone then
                local pos = GetEntityBonePosition_2(interaction.entity, GetEntityBoneIndexByName(interaction.entity, interaction.bone))
                if interaction.offset then
                    pos = GetEntityBonePosition_2(interaction.entity, GetEntityBoneIndexByName(interaction.entity, interaction.bone)) + interaction.offset
                end
                return pos
            elseif interaction.model then
                local offset = interaction.offset or vec3(0.0, 0.0, 0.0)

                return GetOffsetFromEntityInWorldCoords(interaction.entity, offset.x, offset.y, offset.z)
            else
                if IsEntityAPed(interaction.entity) then
                    if interaction.offset then
                        return GetOffsetFromEntityInWorldCoords(interaction.entity, 0.0 + interaction.offset.x, 0.0 + interaction.offset.y, 0.0 + interaction.offset.z)
                    end
                    return GetEntityBonePosition_2(interaction.entity, 0) -- SKEL_ROOT
                else
                    if interaction.offset then
                        return GetOffsetFromEntityInWorldCoords(interaction.entity, 0.0 + interaction.offset.x, 0.0 + interaction.offset.y, 0.0 + interaction.offset.z)
                    end

                    return GetEntityCoords(interaction.entity)
                end
            end
        end
    end

    return vec3(0.0, 0.0, 0.0)
end

function utils.drawOption(coords, text, spriteDict, spriteName, row, width, showDot, alpha)
    SetScriptGfxAlignParams((showDot == true and 0.03 or 0.018) + (width / 2), row * 0.03 - 0.0125, 0.0, 0.0)
    SetTextScale(0, 0.3)
    SetTextFont(4)
    SetTextColour(255, 255, 255, alpha)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextJustification(0)
    EndTextCommandDisplayText(0.0, 0.0)
    ResetScriptGfxAlign()

    SetScriptGfxAlignParams((showDot == true and 0.03 or 0.018) + (width / 2), row * 0.03 - 0.015, 0.0, 0.0)
    DrawSprite(spriteDict, spriteName, 0.0, 0.014, width, 0.025, 0.0, 255, 255, 255, alpha)
    ResetScriptGfxAlign()

    if showDot then
        local newSpritename = spriteName == textures.selected and textures.select_opt or textures.unselect_opt
        SetScriptGfxAlignParams(0.018, row * 0.03 - 0.015, 0.0, 0.0)
        DrawSprite(spriteDict, newSpritename, 0.0, 0.014, 0.011, 0.02, 0.0, 255, 255, 255, alpha)
        ResetScriptGfxAlign()
    end

    ClearDrawOrigin()
end

return utils