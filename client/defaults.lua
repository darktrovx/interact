if GetConvar('interact_disabledefault', 'false') == 'true' then return end

local api = require 'client.interactions'

api.addGlobalVehicleInteraction({
    distance = 5.0,
    interactDst = 1.5,
    offset = vec3(0.0, 1.0, 0.0),
    bone = 'boot',
    id = 'interact:defaultTrunk',
    options = {
        name = 'interact:trunk',
        label = 'Trunk',
        action = function(entity)
            if GetVehicleDoorLockStatus(entity) ~= 1 then
                return lib.notify({ type = 'error', title = 'The trunk is locked.' })
            end

            if GetVehicleDoorAngleRatio(entity, 5) <= 0.0  then
                return lib.notify({ type = 'error', title = 'the trunk is not open' })
            end

            local plate = GetVehicleNumberPlateText(entity)
            local coords = GetEntityCoords(entity)

            TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, 0)

            if not exports.ox_inventory:openInventory('trunk', { id = ('trunk%s'):format(plate), netid = NetworkGetNetworkIdFromEntity(entity), entityid = entity, door = 5 }) then return end
        end,
    }
})