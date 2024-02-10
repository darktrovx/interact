local api = {}

local interactions, filteredInteractions = {}, {}
local table_sort = table.sort

local modelInterations = {}
local enitityInteractions = {}

local getCoordsFromInteract = require 'client.utilities'.getCoordsFromInteract
local nearbyObjectDistance = require 'config.settings'.nearbyObjectDistance

AddEventHandler('interactions:groupsChanged', function(newgroups)
    -- Use this event handler to loop through all current interactions and remove any that are not in the new groups that way we limit the amount of iterations needed

end)

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

local function AddModel(model, offset, options, data)
    local hash = nil
    if type(model) == "number" then
        hash = model
    else
        hash = GetHashKey(model)
    end
    
    if not IsModelValid(hash) then
        return
    end
    if not modelInterations[hash] then
        modelInterations[hash] = {
            model = model,
            offset = offset,
            options = options,
            distance = data.distance,
            interactDst = data.interactDst,
            resource = data.resource,
        }
    else
        for _, option in pairs(options) do
            modelInterations[hash].options[#modelInterations[hash].options + 1] = option
        end

        if data.distance > modelInterations[hash].distance then
            modelInterations[hash].distance = data.distance
        end

        if data.interactDst > modelInterations[hash].interactDst then
            modelInterations[hash].interactDst = data.interactDst
        end
    end
end

---@param coords vec3 : The coords to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst }
-- Add an interaction point at a set of coords
function api.addInteraction(coords, options, data)

    local id = #interactions + 1
    interactions[id] = {
        id = id,
        coords = coords,
        options = options or {},
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        groups =  data.groups or nil,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end exports('AddInteraction', api.addInteraction)

---@param entity number : The entity to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a local (client side) entity
function api.addLocalEntityInteraction(entity, options, data)

    if not DoesEntityExist(entity) then
        print(string.format('Entity %s does not exist', entity))
        enitityInteractions[entity] = nil
        return
    end

    if not enitityInteractions[entity] then

        local id = #interactions + 1
        interactions[id] = {
            id = id,
            entity = entity,
            options = options or {},
            distance = data.distance or 8.0,
            interactDst = data.interactDst or 1.0,
            offset = data.offset or vec(0.0, 0.0, 0.0),
            groups =  data.groups or nil,
            resource = GetInvokingResource()
        }

        enitityInteractions[entity] = interactions[id]
    
    else
        for _, option in pairs(options) do
            enitityInteractions[entity].options[#enitityInteractions[entity].options + 1] = option
        end

        if data.distance > enitityInteractions[entity].distance then
            enitityInteractions[entity].distance = data.distance
        end

        if data.interactDst > enitityInteractions[entity].interactDst then
            enitityInteractions[entity].interactDst = data.interactDst
        end

        local id = enitityInteractions[entity].id
        interactions[id] = {
            id = id,
            entity = entity,
            options = enitityInteractions[entity].options,
            distance = enitityInteractions[entity].distance,
            interactDst = enitityInteractions[entity].interactDst,
            offset = enitityInteractions[entity].offset,
            resource = GetInvokingResource()
        }
    end

    filterInteractions()
    
    return id
end exports('AddLocalEntityInteraction', api.addLocalEntityInteraction)

---@param entity number : The entity to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a networked entity
function api.addEntityInteraction(entity, options, data)

    if not DoesEntityExist(entity) then
        return
    end

    if not NetworkGetEntityIsNetworked(entity) then
        return api.addLocalEntityInteraction(entity, options, data)
    end

    local id = #interactions + 1
    interactions[id] = {
        id = id,
        entity = entity,
        options = options or {},
        distance = data.distance or 10.0,
        interactDst = data.interactDst or 1.0,
        offset = data.offset or vec(0.0, 0.0, 0.0),
        groups =  data.groups or nil,
        resource = GetInvokingResource()
    }

    filterInteractions()

    return id
end exports('AddEntityInteraction', api.addEntityInteraction)

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
        groups =  data.groups or nil,
    }

    filterInteractions()

    return id
end exports('AddEntityBoneInteraction', api.addEntityBoneInteraction)

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
            AddModel(modelData[i].model, modelData[i].offset or vec(0.0, 0.0, 0.0), options, data)
        end
    end
end exports('AddModelInteraction', api.addModelInteraction)

---@param id number : The id of the interaction to remove
-- Remove an interaction point by id.
function api.removeInteraction(id)
    if interactions[id] then
        interactions[id] = nil
        filterInteractions()
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
---@param name string : The name of the option to remove
-- Remove an option from an interaction point by id.
function api.removeInteractionOption(id, name)
    if interactions[id] then
        local options = interactions[id].options

        for i = #options, 1, -1 do
            local option = options[i]

            if option.name == name then
                options[i] = nil
            end
        end
    end

end exports('RemoveInteractionOption', api.removeInteractionOption)

---@param id number : The id of the interaction to update
---@param options table : The new options to update the interaction with
-- Update an interaction point by id.
function api.updateInteraction(id, options)
    if interactions[id] then
        interactions[id].options = options
        filterInteractions()
    end
end exports('UpdateInteraction', api.updateInteraction)

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

            local coords = interaction.coords or getCoordsFromInteract(interaction)

            local distance = #(coords - playercoords)

            if distance <= interaction.distance then
                amount += 1
                interaction.curDist = distance
                options[amount] = interaction
            end
        end
    end

    for k, v in pairs(options) do
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

AddEventHandler('onClientResourceStop', function(resource)
    for i = #interactions, 1, -1 do
        local interaction = interactions[i]

        if interaction.resource == resource then
            api.removeInteraction(i)
        end
    end
end)

return api