local log = require 'shared.log'
local utils = require 'client.utils'
local settings = require 'shared.settings'
local interactions, filteredInteractions = {}, {}
local table_sort = table.sort

-- CACHE.
local MODELS = {}
local ENTITIES = {}
local ENTITY_BONES = {}
local NETWORKED_ENTITIES = {}

local api = {}

AddEventHandler('interactions:groupsChanged', function(newgroups)
    -- Use this event handler to loop through all current interactions and remove any that are not in the new groups that way we limit the amount of iterations needed
end)

local function checkParams(entity, options)
    if not entity then
        log:error('Entity is required to add an interaction')
        return
    else
        if type(entity) ~= 'number' then
            log:error('Entity must be a number')
            return
        end

        if not DoesEntityExist(entity) then
            log:error('Entity %s does not exist', entity)
            return
        end
    end

    if not options then
        log:error('Options are required to add an interaction')
        return
    end

    return true
end

--#TODO: Add a way to filter interactions based on the players group
local function filterInteractions()
    local myGroups = 'police'

    local newInteractions = {}
    local amount = 0

    for i = 1, #interactions do
        local interaction = interactions[i]

        if interaction.groups then

        end

        amount += 1
        newInteractions[amount] = interaction
    end

    filteredInteractions = newInteractions
end

---@param model number|string : The model to add the interaction to
---@param options table : { label, canInteract, action, event, serverEvent, args }
---@param data table : { distance, interactDst, resource }
local function addModel(model, options, data)
    if type(model) ~= "number" then
        model = joaat(model)
    end

    if not IsModelValid(model) then
        log:error('Model %s is not valid', model)
        return
    end

    if not MODELS[model] then
        log:debug('Adding model %s to interactions', model)
        MODELS[model] = {
            model = model,
            offset = data.offset,
            options = options,
            distance = data.distance,
            interactDst = data.interactDst,
            resource = data.resource,
        }
    else
        log:debug('Updating model %s in interactions', model)
        for _, option in pairs(options) do
            MODELS[model].options[#MODELS[model].options + 1] = option
        end

        -- Update the distance and interactDst if the new data is greater
        if data.distance > MODELS[model].distance then
            MODELS[model].distance = data.distance
        end

        if data.interactDst > MODELS[model].interactDst then
            MODELS[model].interactDst = data.interactDst
        end

        -- Update the offset if there is new data
        if data.offset then
            MODELS[model].offset = data.offset
        end
    end
end

---@param data table : { name, coords, options, distance, interactDst, groups }
---@return number : The id of the interaction
-- Add an interaction point at a set of coords
function api.addInteraction(data)
    if not data.coords then
        log:error('Coords are required to add an interaction')
        return
    end

    if not data.options then
        log:error('Options are required to add an interaction')
        return
    end

    local id = #interactions + 1
    interactions[id] = {
        id = id,
        name = data.name or 'interaction:'..id,
        coords = data.coords,
        options = data.options or {},
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        groups = data.groups or nil,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end exports('AddInteraction', api.addInteraction)

---@param data table : { name, entity, options, distance, interactDst, groups }
---@return number : The id of the interaction
-- Add an interaction point on a local (client side) entity
function api.addLocalEntityInteraction(data)
    local entity = data.entity
    if not checkParams(entity, data.options) then
        if ENTITIES[entity] then
            ENTITIES[entity] = nil
        end
        return
    end

    -- If then entity not registered yet, add it
    if not ENTITIES[entity] then
        log:debug('Adding entity %s to interactions', entity)
        local id = #interactions + 1
        interactions[id] = {
            id = id,
            name = data.name or 'interaction:'..id,
            entity = entity,
            options = data.options or {},
            distance = data.distance or 8.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            groups = data.groups or nil,
            resource = GetInvokingResource()
        }

        ENTITIES[entity] = interactions[id]

        filterInteractions()
        return id
    end

    -- If the entity is already registered, update it
    log:debug('Updating entity %s in interactions', entity)
    for index, option in pairs(data.options) do
        if option.name and ENTITIES[entity].options[index]?.name == option.name then
            log:debug('Option with name: ( %s ) already exists, updating', option.name)
            ENTITIES[entity].options[index] = option
        else
            ENTITIES[entity].options[#ENTITIES[entity].options + 1] = option
        end
    end

    -- Update the distance and interactDst if the new data is greater
    if data.distance > ENTITIES[entity].distance then
        ENTITIES[entity].distance = data.distance
    end

    if data.interactDst > ENTITIES[entity].interactDst then
        ENTITIES[entity].interactDst = data.interactDst
    end

    -- Update the offset if there is new data
    if data.offset then
        ENTITIES[entity].offset = data.offset
    end

    interactions[id] = {
        id = id,
        entity = entity,
        options = ENTITIES[entity].options,
        distance = ENTITIES[entity].distance,
        interactDst = ENTITIES[entity].interactDst,
        offset = ENTITIES[entity].offset,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end exports('AddLocalEntityInteraction', api.addLocalEntityInteraction)

---@param data table : { name, netId, options, distance, interactDst, groups }
---@return number : The id of the interaction
-- Add an interaction point on a networked entity
function api.addEntityInteraction(data)
    local netId = data.netId
    -- If the netId does not exist, we assume it is an entity
    local entity
    if type(netId) == 'number' and not NetworkDoesNetworkIdExist(netId) then
        entity = netId
        netId = utils.getEntity(netId)
    end

    if not checkParams(entity, data.options) then
        if NETWORKED_ENTITIES[netId] then
            NETWORKED_ENTITIES[netId] = nil
        end
        return
    end

    -- If the entity is not networked, add it as a local entity
    if not NetworkGetEntityIsNetworked(entity) then
        log:debug('Entity %s is not networked, adding as a local entity', entity)
        data.entity = entity
        return api.addLocalEntityInteraction(data)
    end

    -- If then netId not registered yet, add it
    if not NETWORKED_ENTITIES[netId] then
        log:debug('Adding networkID %s to interactions', netId)

        local id = #interactions + 1
        interactions[id] = {
            id = id,
            name = data.name or 'interaction:'..id,
            entity = entity,
            options = data.options or {},
            distance = data.distance or 10.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            groups = data.groups or nil,
            resource = GetInvokingResource()
        }

        NETWORKED_ENTITIES[netId] = interactions[id]

        filterInteractions()
        return id
    end

    -- If the networkID is already registered, update it
    log:debug('Updating networkID %s in interactions', netId)
    for index, option in pairs(data.options) do
        if option.name and NETWORKED_ENTITIES[netId].options[index]?.name == option.name then
            log:debug('Option with name: ( %s ) already exists, updating', option.name)
            NETWORKED_ENTITIES[netId].options[index] = option
        else
            NETWORKED_ENTITIES[netId].options[#NETWORKED_ENTITIES[netId].options + 1] = option
        end
    end

    -- Update the distance and interactDst if the new data is greater
    if data.distance > NETWORKED_ENTITIES[netId].distance then
        NETWORKED_ENTITIES[netId].distance = data.distance
    end

    if data.interactDst > NETWORKED_ENTITIES[netId].interactDst then
        NETWORKED_ENTITIES[netId].interactDst = data.interactDst
    end

    -- Update the offset if there is new data
    if data.offset then
        NETWORKED_ENTITIES[netId].offset = data.offset
    end

    interactions[id] = {
        id = id,
        entity = entity,
        options = NETWORKED_ENTITIES[netId].options,
        distance = NETWORKED_ENTITIES[netId].distance,
        interactDst = NETWORKED_ENTITIES[netId].interactDst,
        offset = NETWORKED_ENTITIES[netId].offset,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end exports('AddEntityInteraction', api.addEntityInteraction)

---@param data table : { name, entity[number|string], bone[string], options, distance, interactDst, groups }
---@return number : The id of the interaction
-- Add an interaction point on a networked entity's bone
function api.addEntityBoneInteraction(data)

    if not data.entity then
        log:error('Entity is required to add an interaction')
        return
    end

    if not data.bone then
        log:error('Bone is required to add an interaction')
        return
    end

    if not data.options then
        log:error('Options are required to add an interaction')
        return
    end

    -- temp workaround until table refactoring.
    local key = string.format('%s:%s', data.entity, data.bone)
    if not ENTITY_BONES[key] then
        log:debug('Added new entity bone interaction: %s', key)
        ENTITY_BONES[key] = {
            entity = data.entity,
            bone = data.bone,
            distance = data.distance or 10.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            options = data.options,
            groups = data.groups or nil,
        }
    else
        log:debug('Updating %s in bone interactions', key)

        for index, option in pairs(data.options) do
            if option.name and NETWORKED_ENTITIES[netId].options[index]?.name == option.name then
                log:debug('Option with name: ( %s ) already exists, updating', option.name)
                ENTITY_BONES[key].options[index] = option
            else
                ENTITY_BONES[key].options[#ENTITY_BONES[key].options + 1] = option
            end
        end

        -- Update the distance and interactDst if the new data is greater
        if data.distance > ENTITY_BONES[key].distance then
            ENTITY_BONES[key].distance = data.distance
        end

        if data.interactDst > ENTITY_BONES[key].interactDst then
            ENTITY_BONES[key].interactDst = data.interactDst
        end

        -- Update the offset if there is new data
        if data.offset then
            ENTITY_BONES[key].offset = data.offset
        end

        log:debug('Updated entity bone interaction: %s', key)
        ENTITY_BONES[key] = {
            entity = data.entity,
            bone = data.bone,
            options = ENTITY_BONES[key].options,
            distance = ENTITY_BONES[key].distance,
            interactDst = ENTITY_BONES[key].interactDst,
            offset = ENTITY_BONES[key].offset,
            resource = GetInvokingResource()
        }
    end

    filterInteractions()

    return id
end exports('AddEntityBoneInteraction', api.addEntityBoneInteraction)

---@param data table : { name, modelData table : { model[string], offset[vec3] }, options, distance, interactDst, groups }
-- Add interaction(s) to a list of models
function api.addModelInteraction(data)
    data.distance = data.distance or 8.0
    data.interactDst = data.interactDst or 1.0
    for i = 1, #data.modelData do
        local modelData = data.modelData[i]
        if IsModelValid(modelData.model) then
            local min, max = GetModelDimensions(modelData.model)
            local size = (max - min)
            data.interactDst += (size.x / 8)
            data.distance += (size.x / 4)
            data.resource = GetInvokingResource()
            addModel(modelData.model, data.options, { offset = modelData.offset, distance = data.distance, interactDst = data.interactDst, resource = data.resource })
        end
    end
end exports('AddModelInteraction', api.addModelInteraction)

---@param id number : The id of the interaction to remove
-- Remove an interaction point by id.
function api.removeInteraction(id)
    for k, v in pairs(interactions) do
        if v.id == id then
            table.remove(interactions, k)
            log:debug('Removed interaction %s', id)
            filterInteractions()
            return
        end
    end
end exports('RemoveInteraction', api.removeInteraction)

---@param entity number : The entity to remove the interaction from
-- Remove an interaction point by entity.
function api.removeInteractionByEntity(entity)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.entity == entity then
            api.removeInteraction(i)
        end
    end
end exports('RemoveInteractionByEntity', api.removeInteractionByEntity)

---@param id number : The id of the interaction to remove the option from
---@param name? string : The name of the option to remove
-- Remove an option from an interaction point by id.
function api.removeInteractionOption(id, name)
    if not interactions[id] then
        log:error('Interaction with id: ( %s ) does not exist', id)
        return
    end

    if not name then
        api.removeInteraction(id)
        return
    end

    local options = interactions[id].options

    if not options then
        log:error('Interaction with id: ( %s ) does not have any options', id)
        api.removeInteraction(id)
        return
    end

    for i = #options, 1, -1 do
        local option = options[i]

        if option.name == name then
            options[i] = nil
            log:debug('Removed option %s from interaction %s', name, id)
        end
    end
end exports('RemoveInteractionOption', api.removeInteractionOption)

---@param id number : The id of the interaction to update
---@param options table : The new options to update the interaction with
-- Update an interaction point by id.
function api.updateInteraction(id, options)
    if not options then
        log:error('Options are required to update an interaction')
        return
    end

    if not interactions[id] then
        log:error('Interaction with id: ( %s ) does not exist', id)
        return
    end

    if interactions[id] then
        interactions[id].options = options
        filterInteractions()
    end
end exports('UpdateInteraction', api.updateInteraction)

function api.getNearbyInteractions()
    local options = {}
    local amount = 0

    local playercoords = GetEntityCoords(cache.ped)

    -- Temp loop : these checks need to be broken out into their own threads.
    local nearbyVehicles = lib.getNearbyVehicles(playercoords, settings.nearbyVehicleDistance, false)
    for i = 1, #nearbyVehicles do
        local vehicle = nearbyVehicles[i].vehicle
        local vehicleCoords = nearbyVehicles[i].coords

        if settings.vehicleBoneDefaults.enabled then
            for bone, data in pairs(settings.vehicleBoneDefaults.bones) do
                local key = string.format('%s:%s', vehicle, bone)
                if not ENTITY_BONES[key] then
                    api.addEntityBoneInteraction({
                        entity = vehicle,
                        bone = bone,
                        options = data.options,
                        distance = data.distance,
                        interactDst = data.interactDst,
                        offset = data.offset,
                    })
                end
            end
        end
    end

    for _, interaction in pairs(ENTITY_BONES) do
        local distance = #(utils.getCoordsFromInteract(interaction) - playercoords)
        if distance <= interaction.distance then
            amount += 1
            interaction.curDist = distance
            options[amount] = interaction
        end
    end

    local nearbyObjects = lib.getNearbyObjects(playercoords, settings.nearbyObjectDistance)
    for i = 1, #nearbyObjects do
        local nearby = nearbyObjects[i]
        local hash = GetEntityModel(nearby.object)

        if MODELS[hash] then
            local interaction = lib.table.deepclone(MODELS[hash])
            -- put the functions to original references
            for k, v in pairs(interaction) do
                if type(v) == "table" then
                    for id, item in pairs(v) do
                        if item.action then
                            item.action = MODELS[hash].options[id].action
                        end
                        if MODELS[hash].options[id].canInteract then
                            item.canInteract = MODELS[hash].options[id].canInteract
                        end
                        if item.canInteract and not item.canInteract() then
                            v[id] = nil
                        end
                    end
                end
            end
            local distance = #(nearby.coords - playercoords)
            interaction.entity = nearby.object

            if distance <= interaction.distance then
                amount += 1
                interaction.curDist = distance
                options[amount] = interaction
            end
        end
    end

    local amountOfInteractions = #filteredInteractions
    if amountOfInteractions > 0 then
        for i = 1, amountOfInteractions do
            local interaction = filteredInteractions[i]

            local coords = interaction.coords or utils.getCoordsFromInteract(interaction)

            local distance = #(coords - playercoords)

            if distance <= interaction.distance then
                amount += 1
                interaction.curDist = distance
                options[amount] = interaction
            end
        end
    end

    for _, v in pairs(options) do
        for i = 1, #v.options, 1 do
            if not v.options[i] then
                table.remove(v.options, i)
            end
        end
    end
    if amount > 1 then
        table_sort(options, function(a, b)
            return a.curDist < b.curDist
        end)
    end

    return options
end

function api.disable(state)
    LocalPlayer.state:set('interactionsDisabled', state, true)
end exports('Disable', api.disable)

AddEventHandler('onClientResourceStop', function(resource)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.resource == resource then
            api.removeInteraction(interaction.id)
        end
    end
end)

return api
