local entities = {}
local netIds = {}
local models = {}
local localEnties = {}
local playersTable = {}

-- Sub caches are used for caching shit that is run every 250ms in the main loop
local subCache = {}

function entities.isNetIdNearby(netID)
    local entity = netIds[netID]

    return entity and entity.entity
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
    local serverIds = {}

    if subCache[type] then
        return #subCache[type], subCache[type]
    end

    for k, v in pairs(localEnties) do
        if v.type == type then
            amount += 1
            entityTable[amount] = k
        end
    end

    for _, v in pairs(netIds) do
        if v.type == type then
            amount += 1
            entityTable[amount] = v.entity
        end
    end

    if type == 'players' then
        for _, v in pairs(playersTable) do
            amount += 1
            entityTable[amount] = v.entity
            serverIds[amount] = v.serverId
        end

        return amount, entityTable, serverIds
    end

    subCache[type] = entityTable

    return amount, entityTable
end

local function clearTables()
    table.wipe(netIds)
    table.wipe(models)
    table.wipe(localEnties)
    table.wipe(subCache)
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

RegisterNetEvent('onPlayerDropped', function(serverId)
    playersTable[serverId] = nil
end)

RegisterNetEvent('onPlayerJoining', function(serverId)
    local playerId = GetPlayerFromServerId(serverId)

    local ent = lib.waitFor(function()
        local ped = GetPlayerPed(playerId)

        if ped > 0 then
            return ped
        end
    end, '', 10000)

    playersTable[serverId] = {
        entity = ent,
        serverId = serverId,
        type = 'players',
    }
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    local players = GetActivePlayers()

    for i = 1, #players do
        local playerId = players[i]
        local serverId = GetPlayerServerId(playerId)

        if serverId ~= cache.serverId then
            local ent = lib.waitFor(function()
                local ped = GetPlayerPed(playerId)

                if ped > 0 then
                    return ped
                end
            end, '', 10000)

            playersTable[serverId] = {
                entity = ent,
                serverId = serverId,
                type = 'players',
            }
        end
    end
end)

return entities