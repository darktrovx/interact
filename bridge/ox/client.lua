if not lib.checkDependency('ox_core', '0.21.3', true) then return end

local Ox = require '@ox_core.lib.init'

RegisterNetEvent('ox:setGroup', function(name, grade)
    Player.group[name] = grade

    TriggerEvent('interact:groupsChanged', Player.group)
end)

AddEventHandler('ox:playerLoaded', function()
    local currentPlayer = Ox.GetPlayer()

    Player = {
        group = currentPlayer.getGroups()
    }

    TriggerEvent('interact:groupsChanged', Player.group)
end)

AddEventHandler('ox:playerLogout', function()
    table.wipe(Player)

    TriggerEvent('interact:groupsChanged', {})
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(500)
        local currentPlayer = Ox.GetPlayer()

        Player = {
            group = currentPlayer.getGroups()
        }

        TriggerEvent('interact:groupsChanged', Player.group)
    end
end)