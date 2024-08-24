--[[
    Thanks to ox_target for the base of removing entity netIds
]]

local entityStates = {}

RegisterNetEvent('interact:setEntityHasOptions', function(netId)
    local entity = Entity(NetworkGetEntityFromNetworkId(netId))

    entity.state.hasInteractOptions = true
    entityStates[netId] = entity
end)

CreateThread(function()
    local arr = {}
    local num = 0

    while true do
        Wait(10000)

        for netId, entity in pairs(entityStates) do
            if not DoesEntityExist(entity.__data) or not entity.state.hasInteractOptions then
                entityStates[netId] = nil
                num += 1
                arr[num] = netId
            end
        end

        if num > 0 then
            TriggerClientEvent('interact:removeEntity', -1, arr)
            table.wipe(arr)

            num = 0
        end
    end
end)