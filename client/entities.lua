local entities = {}
local netIds = {}
local models = {}
local localEnties = {}

function entities.isNetIdNearby(netID)
    return netIds[netID]
end

function entities.getModelEntities(model)
    return models[model]
end

function entities.isEntityNearby(entity)
    return localEnties[entity]
end

function entities.getEntitiesByType(type)
    local amount = 0
    local entityTable = {}


    for k, v in pairs(localEnties) do
        if v.type == type then
            amount = amount + 1
            entityTable[amount] = k
        end
    end

    for _, v in pairs(netIds) do
        if v.type == type then
            amount = amount + 1
            entityTable[amount] = v.entity
        end
    end

    return amount, entityTable
end

local function clearTables()
    table.wipe(netIds)
    table.wipe(models)
    table.wipe(localEnties)
end

local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local GetEntityModel = GetEntityModel

local function buildEntities(eType, playerCoords)
    local entityPool = GetGamePool(eType)

    local type = eType:sub(2):lower()

    for i = 1, #entityPool do
        local entity = entityPool[i]

        if #(playerCoords - GetEntityCoords(entity)) < 100.0 then
            local isNetworked = NetworkGetEntityIsNetworked(entity)
            local model = GetEntityModel(entity)

            if isNetworked then
                local netId = NetworkGetNetworkIdFromEntity(entity)

                if not netIds[netId] then
                    netIds[netId] = {
                        entity = entity,
                        type = type,
                    }
                end
            else
                localEnties[entity] = {
                    entity = entity,
                    type = type,
                }
            end


            if not models[model] then
                models[model] = {}
            end

            models[model][#models[model] + 1] = {
                entity = entity,
                type = type,
            }
        end
    end
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        clearTables()

        buildEntities('CVehicle', playerCoords)
        buildEntities('CPed', playerCoords)
        buildEntities('CObject', playerCoords)

        Wait(2500)
    end
end)

return entities