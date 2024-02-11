local log = require 'shared.log'
local utils = require 'client.utils'
local api = {}

local interactions, filteredInteractions = {}, {}
local table_sort = table.sort

local modelInterations = {}
local enitityInteractions = {}
local networkedInteractions = {}

local nearbyObjectDistance = require 'shared.settings'.nearbyObjectDistance

AddEventHandler('interactions:groupsChanged', function(newgroups)
    -- Use this event handler to loop through all current interactions and remove any that are not in the new groups that way we limit the amount of iterations needed
end)

local function checkParams(entity, options, data)
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

    if not data then
        log:error('Data is required to add an interaction')
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
---@param offset vector3 : The offset to add the interaction to
---@param options table : { label, canInteract, action, event, serverEvent, args }
---@param data table : { distance, interactDst, resource }
local function addModel(model, offset, options, data)
    if type(model) ~= "number" then
        model = joaat(model)
    end

    if not IsModelValid(model) then
        log:error('Model %s is not valid', model)
        return
    end

    if not modelInterations[model] then
        log:debug('Adding model %s to interactions', model)
        modelInterations[model] = {
            model = model,
            offset = offset,
            options = options,
            distance = data.distance,
            interactDst = data.interactDst,
            resource = data.resource,
        }
    else
        log:debug('Updating model %s in interactions', model)
        for _, option in pairs(options) do
            modelInterations[model].options[#modelInterations[model].options + 1] = option
        end

        -- Update the distance and interactDst if the new data is greater
        if data.distance > modelInterations[model].distance then
            modelInterations[model].distance = data.distance
        end

        if data.interactDst > modelInterations[model].interactDst then
            modelInterations[model].interactDst = data.interactDst
        end

        -- Update the offset if there is new data
        if data.offset then
            modelInterations[model].offset = data.offset
        end
    end
end

---@param coords vector3 : The coords to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst }
-- Add an interaction point at a set of coords
function api.addInteraction(coords, options, data)
    if not coords then
        log:error('Coords are required to add an interaction')
        return
    end

    if not options then
        log:error('Options are required to add an interaction')
        return
    end

    if not data then
        log:error('Data is required to add an interaction')
        return
    end

    local id = #interactions + 1
    interactions[id] = {
        id = id,
        coords = coords,
        options = options or {},
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        groups = data.groups or nil,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end

exports('AddInteraction', api.addInteraction)

---@param entity number : The entity to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a local (client side) entity
function api.addLocalEntityInteraction(entity, options, data)
    if not checkParams(entity, options, data) then
        if enitityInteractions[entity] then
            enitityInteractions[entity] = nil
        end
        return
    end

    -- If then entity not registered yet, add it
    if not enitityInteractions[entity] then
        log:debug('Adding entity %s to interactions', entity)
        local id = #interactions + 1
        interactions[id] = {
            id = id,
            entity = entity,
            options = options or {},
            distance = data.distance or 8.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            groups = data.groups or nil,
            resource = GetInvokingResource()
        }

        enitityInteractions[entity] = interactions[id]

        filterInteractions()
        return id
    end

    local id = enitityInteractions[entity]?.id

    -- This is a fallback in case the entity does not have an id
    if not id then
        log.error('Entity %s does not have an id', entity)
        id = #interactions + 1
        log.debug('Since the entity %s does not have an id, we are generating a new one', entity)
    end

    -- If the entity is already registered, update it
    log:debug('Updating entity %s in interactions', entity)
    for index, option in pairs(options) do
        if option.name and enitityInteractions[entity].options[index]?.name == option.name then
            log:debug('Option whit name: ( %s ) already exists, updating', option.name)
            enitityInteractions[entity].options[index] = option
        else
            enitityInteractions[entity].options[#enitityInteractions[entity].options + 1] = option
        end
    end

    -- Update the distance and interactDst if the new data is greater
    if data.distance > enitityInteractions[entity].distance then
        enitityInteractions[entity].distance = data.distance
    end

    if data.interactDst > enitityInteractions[entity].interactDst then
        enitityInteractions[entity].interactDst = data.interactDst
    end

    -- Update the offset if there is new data
    if data.offset then
        enitityInteractions[entity].offset = data.offset
    end

    interactions[id] = {
        id = id,
        entity = entity,
        options = enitityInteractions[entity].options,
        distance = enitityInteractions[entity].distance,
        interactDst = enitityInteractions[entity].interactDst,
        offset = enitityInteractions[entity].offset,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end

exports('AddLocalEntityInteraction', api.addLocalEntityInteraction)

---@param netID number : The entity to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a networked entity
function api.addEntityInteraction(netID, options, data)
    -- If the netID does not exist, we assume it is an entity
    local entity
    if type(netID) == 'number' and not NetworkDoesNetworkIdExist(netID) then
        entity = netID
        netID = utils.getEntity(netID)
    end

    if not checkParams(entity, options, data) then
        if networkedInteractions[netID] then
            networkedInteractions[netID] = nil
        end
        return
    end

    -- If the entity is not networked, add it as a local entity
    if not NetworkGetEntityIsNetworked(entity) then
        log:debug('Entity %s is not networked, adding as a local entity', entity)
        return api.addLocalEntityInteraction(entity, options, data)
    end

    -- If then netID not registered yet, add it
    if not networkedInteractions[netID] then
        log:debug('Adding networkID %s to interactions', netID)

        local id = #interactions + 1
        interactions[id] = {
            id = id,
            entity = entity,
            options = options or {},
            distance = data.distance or 10.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            groups = data.groups or nil,
            resource = GetInvokingResource()
        }

        networkedInteractions[netID] = interactions[id]

        filterInteractions()
        return id
    end

    local id = networkedInteractions[netID]?.id

    -- This is a fallback in case the networkID does not have an id
    if not id then
        log.error('NetworkID %s does not have an identifier', netID)
        id = #interactions + 1
        log.debug('Since the networkID %s does not have an identifier, we are generating a new one', netID)
    end

    -- If the networkID is already registered, update it
    log:debug('Updating networkID %s in interactions', netID)
    for index, option in pairs(options) do
        if option.name and networkedInteractions[netID].options[index]?.name == option.name then
            log:debug('Option whit name: ( %s ) already exists, updating', option.name)
            networkedInteractions[netID].options[index] = option
        else
            networkedInteractions[netID].options[#networkedInteractions[netID].options + 1] = option
        end
    end

    -- Update the distance and interactDst if the new data is greater
    if data.distance > networkedInteractions[netID].distance then
        networkedInteractions[netID].distance = data.distance
    end

    if data.interactDst > networkedInteractions[netID].interactDst then
        networkedInteractions[netID].interactDst = data.interactDst
    end

    -- Update the offset if there is new data
    if data.offset then
        networkedInteractions[netID].offset = data.offset
    end

    interactions[id] = {
        id = id,
        entity = entity,
        options = networkedInteractions[netID].options,
        distance = networkedInteractions[netID].distance,
        interactDst = networkedInteractions[netID].interactDst,
        offset = networkedInteractions[netID].offset,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end

exports('AddEntityInteraction', api.addEntityInteraction)

---@param entityData table : { entity[number|string], bone[string] }
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a networked entity's bone
function api.addEntityBoneInteraction(entityData, options, data)
    local id = #interactions + 1
    interactions[id] = {
        id = id,
        entity = entityData.entity,
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        bone = entityData.bone,
        options = options or {},
        groups = data.groups or nil,
    }

    filterInteractions()

    return id
end

exports('AddEntityBoneInteraction', api.addEntityBoneInteraction)

---@param modelData table : { model[string], offset[vec3] }
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, resource }
-- Add interaction(s) to a list of models
function api.addModelInteraction(modelData, options, data)
    data.distance = data.distance or 8.0
    data.interactDst = data.interactDst or 1.0
    for i = 1, #modelData do
        if IsModelValid(modelData[i].model) then
            local min, max = GetModelDimensions(modelData[i].model)
            local size = (max - min)
            data.interactDst += (size.x / 8)
            data.distance += (size.x / 4)
            data.resource = GetInvokingResource()
            addModel(modelData[i].model, modelData[i].offset or vec(0.0, 0.0, 0.0), options, data)
        end
    end
end

exports('AddModelInteraction', api.addModelInteraction)

---@param id number : The id of the interaction to remove
-- Remove an interaction point by id.
function api.removeInteraction(id)
    if interactions[id] then
        interactions[id] = nil
        log:debug('Removed interaction %s', id)
        filterInteractions()
    end
end

exports('RemoveInteraction', api.removeInteraction)

---@param entity number : The entity to remove the interaction from
-- Remove an interaction point by entity.
function api.removeInteractionByEntity(entity)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.entity == entity then
            api.removeInteraction(i)
        end
    end
end

exports('RemoveInteractionByEntity', api.removeInteractionByEntity)

---@param id number : The id of the interaction to remove the option from
---@param name? string : The name of the option to remove
-- Remove an option from an interaction point by id.
function api.removeInteractionOption(id, name)
    if not interactions[id] then
        log:error('Interaction whit id: ( %s ) does not exist', id)
        return
    end

    if not name then
        api.removeInteraction(id)
        return
    end

    local options = interactions[id].options

    if not options then
        log:error('Interaction whit id: ( %s ) does not have any options', id)
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
end

exports('RemoveInteractionOption', api.removeInteractionOption)

---@param id number : The id of the interaction to update
---@param options table : The new options to update the interaction with
-- Update an interaction point by id.
function api.updateInteraction(id, options)
    if not options then
        log:error('Options are required to update an interaction')
        return
    end

    if not interactions[id] then
        log:error('Interaction whit id: ( %s ) does not exist', id)
        return
    end

    if interactions[id] then
        interactions[id].options = options
        filterInteractions()
    end
end

exports('UpdateInteraction', api.updateInteraction)

function api.getNearbyInteractions()
    local options = {}
    local amount = 0

    local playercoords = GetEntityCoords(cache.ped)

    local nearbyObjects = lib.getNearbyObjects(playercoords, nearbyObjectDistance)
    for i = 1, #nearbyObjects do
        local nearby = nearbyObjects[i]
        local hash = GetEntityModel(nearby.object)

        if modelInterations[hash] then
            local interaction = lib.table.deepclone(modelInterations[hash])
            -- put the functions to original references
            for k, v in pairs(interaction) do
                if type(v) == "table" then
                    for id, item in pairs(v) do
                        if item.action then
                            item.action = modelInterations[hash].options[id].action
                        end
                        if modelInterations[hash].options[id].canInteract then
                            item.canInteract = modelInterations[hash].options[id].canInteract
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
end

exports('Disable', api.disable)

AddEventHandler('onClientResourceStop', function(resource)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.resource == resource then
            api.removeInteraction(i)
        end
    end
end)

return api
