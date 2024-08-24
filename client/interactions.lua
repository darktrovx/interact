local log = require 'shared.log'
local utils = require 'client.utils'
local entities = require 'client.entities'

local interactions, filteredInteractions = {}, {}
local table_sort = table.sort
local table_type = table.type

-- CACHE.
local api = {}
local entityInteractions = {}
local modelInteractions = {}
local netInteractions = {}
local globalVehicleInteractions = {}
local globalPlayerInteraction = {}
local myGroups = {}

-- Used for backwards compatibility, to ensure we return the ID of the interaction
local function generateUUID()
    return ('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)

        return ('%x'):format(v)
    end)
end

local function verifyInteraction(interaction)
    if not interaction then
        return log:error('Interaction does not exist')
    end

    if not interaction.options then
        return log:error('Error, interactions must have options!')
    end

    -- makes it so you can send a singular object instead of an array
    if table.type(interaction.options) ~= 'array' then
        interaction.options = { interaction.options }
    end

    -- Translates types of groups into a key value pair for easier checking
    if interaction.groups then
        if type(interaction.groups) == 'string' then
            interaction.groups = { [interaction.groups] = 0 }
        elseif table_type(interaction.groups) == 'array' then
            for i = 1, #interaction.groups do
                interaction.groups[interaction.groups[i]] = 0
            end
        end
    end

    return true
end

local function hasGroup(groups)
    if groups then
        for group, grade in pairs(groups) do
            if myGroups[group] and myGroups[group] >= grade then
                return true
            end
        end
    end

    return false
end

local function filterEntityInteractions(newInteractions, data)
    local amount = #newInteractions

    for _, allInteraction in pairs(data) do
        for i = 1, #allInteraction do
            local interaction = allInteraction[i]

            if not interaction.groups or hasGroup(interaction.groups) then
                amount += 1
                newInteractions[amount] = interaction
            end
        end
    end
end

local function filterOtherInteractions(newInteractions, data)
    local indexAmount = #data
    local interactionAmount = #newInteractions

    if indexAmount > 0 then
        for i = 1, indexAmount do
            local interaction = data[i]

            if not interaction.groups or hasGroup(interaction.groups) then
                interactionAmount += 1
                newInteractions[interactionAmount] = interaction
            end
        end
    end
end

local function filterInteractions()
    local newInteractions = {}

    -- All of these are essentially the same, data structure so we can use the same function
    filterEntityInteractions(newInteractions, netInteractions)
    filterEntityInteractions(newInteractions, entityInteractions)
    filterEntityInteractions(newInteractions, modelInteractions)

    -- Filter out the other interactions that are not local/net entitiy interactions
    filterOtherInteractions(newInteractions, interactions)
    filterOtherInteractions(newInteractions, globalVehicleInteractions)
    filterOtherInteractions(newInteractions, globalPlayerInteraction)

    filteredInteractions = newInteractions
end

AddEventHandler('interact:groupsChanged', function(groups)
    myGroups = groups or {}

    filterInteractions()
end)

---@param data table : { name, coords, options, distance, interactDst, groups }
---@return string | nil : The id of the interaction
-- Add an interaction point at a set of coords
function api.addInteraction(data)
    if not verifyInteraction(data) then return end

    local id = data.id or generateUUID()

    local dataTable = {
        id = id,
        name = data.name or ('interaction:%s'):format(id),
        coords = data.coords,
        width = utils.getOptionsWidth(data.options),
        options = data.options,
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        groups = data.groups,
        resource = GetInvokingResource()
    }

    interactions[#interactions + 1] = dataTable

    -- Only add the interaction if it does not have groups

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = dataTable
    end

    return id
end
exports('AddInteraction', api.addInteraction)

---@param data table : { name, entity, options, distance, interactDst, groups }
---@return string | nil : The id of the interaction
-- Add an interaction point on a local (client side) entity
function api.addLocalEntityInteraction(data)
    local entity = data and data.entity

    if not entity then
        return log:error('Entity is required to add an interaction')
    elseif type(data.entity) ~= 'number' or not DoesEntityExist(data.entity) then
        return log:error('Invalid entity')
    end

    if not verifyInteraction(data) then return end

    if not entityInteractions[entity] then
        entityInteractions[entity] = {}
    end

    local id = data.id or generateUUID()
    local tableData = {
        id = id,
        name = data.name or ('interaction:%s'):format(id),
        entity = entity,
        width = utils.getOptionsWidth(data.options),
        options = data.options,
        ignoreLos = data.ignoreLos,
        distance = data.distance or 8.0,
        interactDst = data.interactDst or 1.0,
        offset = data.offset,
        groups = data.groups,
        resource = GetInvokingResource()
    }

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = tableData
    end

    entityInteractions[entity][#entityInteractions[entity] + 1] = tableData

    return id
end
exports('AddLocalEntityInteraction', api.addLocalEntityInteraction)

---@param data table : { name, netId, options, distance, interactDst, groups }
---@return string | nil : The id of the interaction
-- Add an interaction point on a networked entity
function api.addEntityInteraction(data)
    local netId = data.netId

    -- If the netId does not exist, we assume it is an entity
    if not netId or not NetworkDoesNetworkIdExist(netId) then
        local entity = data.entity or data.netId

        if DoesEntityExist(entity) then
            data.entity = entity

            return api.addLocalEntityInteraction(data)
        end
    end

    if NetworkDoesNetworkIdExist(netId) then
        if not Entity(NetworkGetEntityFromNetworkId(netId)).state.hasInteractOptions then
            TriggerServerEvent('interact:setEntityHasOptions', netId)
        end
    end

    if not verifyInteraction(data) then return end

    local id = data.id or generateUUID()

    if not netInteractions[netId] then
        netInteractions[netId] = {}
    end

    local dataTable = {
        id = id,
        name = data.name or ('interaction:%s'):format(id),
        width = utils.getOptionsWidth(data.options),
        netId = netId,
        bone = data.bone,
        ignoreLos = data.ignoreLos,
        options = data.options,
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        offset = data.offset,
        groups = data.groups,
        resource = GetInvokingResource()
    }

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = dataTable
    end

    netInteractions[netId][#netInteractions[netId]+1] = dataTable

    return id
end
exports('AddEntityInteraction', api.addEntityInteraction)

function api.addGlobalVehicleInteraction(data)
    if not verifyInteraction(data) then return end

    local id = data.id or generateUUID()

    local dataTable = {
        id = id,
        name = data.name or ('interaction:%s'):format(id),
        options = data.options,
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        offset = data.offset,
        bone = data.bone,
        ignoreLos = data.ignoreLos,
        width = utils.getOptionsWidth(data.options),
        global = true,
        groups = data.groups,
        resource = GetInvokingResource()
    }

    globalVehicleInteractions[#globalVehicleInteractions + 1] = dataTable

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = dataTable
    end

    return id
end
exports('AddGlobalVehicleInteraction', api.addGlobalVehicleInteraction)

function api.addGlobalPlayerInteraction(data)
    if not verifyInteraction(data) then return end

    local id = data.id or generateUUID()

    local dataTable = {
        id = id,
        name = data.name or ('interaction:%s'):format(id),
        options = data.options,
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        offset = data.offset,
        bone = data.bone,
        ignoreLos = data.ignoreLos,
        width = utils.getOptionsWidth(data.options),
        global = false,
        globalPlayer = true,
        groups = data.groups,
        resource = GetInvokingResource()
    }

    globalPlayerInteraction[#globalPlayerInteraction + 1] = dataTable

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = dataTable
    end

    return id
end
exports('addGlobalPlayerInteraction', api.addGlobalPlayerInteraction)


---@param data table : { name, entity[number|string], bone[string], options, distance, interactDst, groups }
---@return number | nil : The id of the interaction
-- Add an interaction point on a networked entity's bone
function api.addEntityBoneInteraction()
    lib.print.warn('addEntityBoneInteraction is deprecated, use AddEntityInteraction or AddLocalEntityInteraction instead')
end
exports('AddEntityBoneInteraction', api.addEntityBoneInteraction)

---@param data table : { name, modelData table : { model[string], offset[vec3] }, options, distance, interactDst, groups }
-- Add interaction(s) to a list of models
function api.addModelInteraction(data)
    local model = data.model
    model = type(model) == 'number' and model or joaat(model)

    if not IsModelValid(model) then
        return log:error('Model %s is not valid', model)
    elseif not verifyInteraction(data) then
        return
    end

    if not modelInteractions[model] then
        modelInteractions[model] = {}
    end

    local id = data.id or generateUUID()

    local tableData = {
        offset = data.offset,
        model = model,
        id = id,
        options = data.options,
        ignoreLos = data.ignoreLos,
        bone = data.bone,
        width = data.width or utils.getOptionsWidth(data.options),
        distance = data.distance or 10,
        interactDst = data.interactDst or 1,
        groups = data.groups,
        resource = GetInvokingResource(),
    }

    if not data.groups or hasGroup(data.groups) then
        filteredInteractions[#filteredInteractions + 1] = tableData
    end

    modelInteractions[model][#modelInteractions[model] + 1] = tableData

    return id
end
exports('AddModelInteraction', api.addModelInteraction)

local function removeFilteredInteraction(interaction)
    if not interaction.groups or hasGroup(interaction.groups) then
        local id = interaction.id

        for i = #filteredInteractions, 1, -1 do
            if filteredInteractions[i].id == id then
                table.remove(filteredInteractions, i)
                return
            end
        end
    end
end

---@param id number : The id of the interaction to remove
-- Remove an interaction point by id.
function api.removeInteraction(id)
    if id then
        for i = 1, #interactions do
            local interaction = interactions[i]

            if interaction?.id == id then
                removeFilteredInteraction(interaction)
                table.remove(interactions, i)
            end
        end
    end
end
exports('RemoveInteraction', api.removeInteraction)

---@param entity number : The entity to remove the interaction from
-- Remove an interaction point by entity.
function api.removeInteractionByEntity()
    lib.print.warn('removeInteractionByEntity is deprecated, use RemoveLocalEntityInteraction instead')
end
exports('RemoveInteractionByEntity', api.removeInteractionByEntity)

function api.removeLocalEntityInteraction(entity, id)
    if entity and id and entityInteractions[entity] then
        for i = 1, #entityInteractions[entity] do
            local interaction = entityInteractions[entity][i]

            if interaction.id == id then
                removeFilteredInteraction(interaction)
                table.remove(entityInteractions[entity], i)
                return
            end
        end
    end
end
exports('RemoveLocalEntityInteraction', api.removeLocalEntityInteraction)

function api.removeModelInteraction(model, id)
    if model and id and modelInteractions[model] then
        for i = 1, #modelInteractions[model] do
            local interaction = modelInteractions[model][i]

            if interaction.id == id then
                removeFilteredInteraction(interaction)
                table.remove(modelInteractions[model], i)
                return
            end
        end
    end
end
exports('RemoveModelInteraction', api.removeModelInteraction)

function api.removeEntityInteraction(netId, id)
    if netId and id and netInteractions[netId] then
        for i = 1, #netInteractions[netId] do
            local interaction = netInteractions[netId][i]

            if interaction.id == id then
                removeFilteredInteraction(interaction)
                table.remove(netInteractions[netId], i)
                return
            end
        end
    end
end
exports('RemoveEntityInteraction', api.removeEntityInteraction)

RegisterNetEvent('interact:removeEntity', function(data)
    for i = 1, #data do
        local netId = data[i]

        if netInteractions[netId] then
            netInteractions[netId] = nil
        end
    end

    filterInteractions()
end)

function api.removeGlobalVehicleInteraction(id)
    if id then
        for i = 1, #globalVehicleInteractions do
            local interaction = globalVehicleInteractions[i]

            if interaction.id == id then
                removeFilteredInteraction(interaction)
                table.remove(globalVehicleInteractions, i)
                return
            end
        end
    end
end
exports('RemoveGlobalVehicleInteraction', api.removeGlobalVehicleInteraction)

function api.removeGlobalPlayerInteraction(id)
    if id then
        for i = 1, #globalPlayerInteraction do
            local interaction = globalPlayerInteraction[i]

            if interaction.id == id then
                removeFilteredInteraction(interaction)
                table.remove(globalPlayerInteraction, i)
                return
            end
        end
    end
end
exports('RemoveGlobalPlayerInteraction', api.removeGlobalPlayerInteraction)

---@param id number : The id of the interaction to remove the option from
---@param name? string : The name of the option to remove
-- Remove an option from an interaction point by id.
function api.removeInteractionOption(id, name)
    if not name then
        return api.removeInteraction(id)
    end

    local options = interactions?[id]?.options

    if not options then
        log:error('Interaction with id: ( %s ) does not have any options', id)
        return api.removeInteraction(id)
    end

    for i = #options, 1, -1 do
        local option = options[i]

        if option.name == name then
            table.remove(options, i)
            log:debug('Removed option %s from interaction %s', name, id)
        end
    end
end
exports('RemoveInteractionOption', api.removeInteractionOption)

---@param id number : The id of the interaction to update
---@param options table : The new options to update the interaction with
-- Update an interaction point by id.
function api.updateInteraction(id, options)
    if not options then
        return log:error('Options are required to update an interaction')
    end

    if not interactions[id] then
        return log:error('Interaction with id: ( %s ) does not exist', id)
    end

    if interactions[id] then
        options = table_type(options) == 'array' and options or { options }
        interactions[id].options = options
        filterInteractions()
    end
end
exports('UpdateInteraction', api.updateInteraction)

local function canInteract(option, interaction)
    return not option.canInteract or option.canInteract(interaction.entity, interaction.coords, interaction.args)
end

local function getInteractionOptions(interaction)
    local currentOptions = {}
    local added = 0
    local amount = #interaction.options

    if amount > 0 then
        for j = 1, amount do
            local option = interaction.options[j]

            local success, result = pcall(canInteract, option, interaction)

            if success and result then
                if not option.job or hasGroup(option.job) then
                    added += 1
                    currentOptions[added] = option
                end
            end
        end
    end

    return currentOptions, added
end

local function getReturnData(options, distance, interaction)
    return {
        id = interaction.id,
        entity = interaction.entity,
        bone = interaction.bone,
        coords = interaction.coords,
        options = options,
        curDist = distance,
        ignoreLos = interaction.ignoreLos,
        interactDst = interaction.interactDst,
        width = interaction.width,
        offset = interaction.offset,
        serverId = interaction.serverId,
    }
end

local function addGlobalVehicleData(interaction, options, playercoords)
    local vehicleAmount, vehicles = entities.getEntitiesByType('vehicle')

    if vehicleAmount > 0 then
        local amount = #options


        for j = 1, vehicleAmount do
            interaction.entity = vehicles[j]

            local distance = #(utils.getCoordsFromInteract(interaction) - playercoords)

            if distance <= interaction.distance then
                local interactOptions, interactionAmount = getInteractionOptions(interaction)

                if interactionAmount > 0 then
                    amount += 1
                    options[amount] = getReturnData(interactOptions, distance, interaction)
                end
            end
        end
    end
end

local function addGlobalPlayerData(interaction, options, playercoords)
    local playerAmount, players, serverIds = entities.getEntitiesByType('players')

    if playerAmount > 0 then
        local amount = #options


        for j = 1, playerAmount do
            interaction.entity = players[j]
            interaction.serverId = serverIds[j]
            local distance = #(utils.getCoordsFromInteract(interaction) - playercoords)

            if distance <= interaction.distance then
                local interactOptions, interactionAmount = getInteractionOptions(interaction)

                if interactionAmount > 0 then
                    amount += 1
                    options[amount] = getReturnData(interactOptions, distance, interaction)
                end
            end
        end
    end
end

local function addModelInteraction(interaction, options, playercoords)
    local modelEntities = entities.getModelEntities(interaction.model)
    local entityNumbers = modelEntities and #modelEntities

    if entityNumbers and entityNumbers > 0 then
        local amount = #options

        for j = 1, entityNumbers do
            interaction.entity = modelEntities[j].entity
            local distance = #(utils.getCoordsFromInteract(interaction) - playercoords)

            if distance <= interaction.distance then
                local interactOptions, interactionAmount = getInteractionOptions(interaction)

                if interactionAmount > 0 then
                    amount += 1
                    options[amount] = getReturnData(interactOptions, distance, interaction)
                end
            end
        end
    end
end

function api.getNearbyInteractions()
    local options = {}
    local amount = 0

    local playercoords = GetEntityCoords(cache.ped)

    local amountOfInteractions = #filteredInteractions

    if amountOfInteractions > 0 then
        for i = 1, amountOfInteractions do
            local interaction = filteredInteractions[i]

            if interaction.global then
                addGlobalVehicleData(interaction, options, playercoords)
                amount = #options
                goto skip
            end

            if interaction.globalPlayer then
                addGlobalPlayerData(interaction, options, playercoords)
                amount = #options
                goto skip
            end

            if interaction.model then
                addModelInteraction(interaction, options, playercoords)
                amount = #options
                goto skip
            end

            -- Check if the interaction is a networked entity
            if interaction.netId then
                local entity = entities.isNetIdNearby(interaction.netId)

                if not entity then
                    goto skip
                end

                interaction.entity = entity
            elseif interaction.entity and not entities.isEntityNearby(interaction.entity) then
                goto skip
            end

            local coords = interaction.coords or utils.getCoordsFromInteract(interaction)
            local distance = #(coords - playercoords)

            if distance <= interaction.distance then
                local interactOptions, interactionAmount = getInteractionOptions(interaction)
                if interactionAmount > 0 then
                    amount += 1
                    options[amount] = getReturnData(interactOptions, distance, interaction)
                end
            end

            :: skip ::
        end
    end

    if amount > 1 then
        table.sort(options, function(a, b)
            return a.curDist < b.curDist
        end)
    end

    return options, amount
end

function api.disable(state)
    LocalPlayer.state:set('interactionsDisabled', state, false)
end
exports('Disable', api.disable)

AddEventHandler('onClientResourceStop', function(resource)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.resource == resource then
            table.remove(interactions, i)
        end
    end

    for i = 1, #globalVehicleInteractions do
        local interaction = globalVehicleInteractions[i]

        if interaction.resource == resource then
            table.remove(globalVehicleInteractions, i)
        end
    end

    for i = 1, #globalPlayerInteraction do
        local interaction = globalPlayerInteraction[i]

        if interaction.resource == resource then
            table.remove(globalPlayerInteraction, i)
        end
    end

    for entity, data in pairs(entityInteractions) do
        for i = #data, 1, -1 do
            local interaction = data[i]

            if interaction.resource == resource then
                table.remove(entityInteractions[entity], i)
            end
        end
    end

    for model, data in pairs(modelInteractions) do
        for i = #data, 1, -1 do
            local interaction = data[i]
            if interaction.resource == resource then
                table.remove(modelInteractions[model], i)
            end
        end
    end

    for netId, data in pairs(netInteractions) do
        for i = #data, 1, -1 do
            local interaction = data[i]

            if interaction.resource == resource then
                table.remove(netInteractions[netId], i)
            end
        end
    end

    filterInteractions()
end)

return api