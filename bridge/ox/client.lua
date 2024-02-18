local file = ('imports/%s.lua'):format('client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

local Player = {}

RegisterNetEvent('ox:setGroup', function(name, grade)
    Player.group[name] = grade

    TriggerEvent('interact:groupsChanged', Player.group)
end)

AddEventHandler('ox:playerLoaded', function()
    Player = {
        group = Ox.GetPlayerData().groups
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
        Player = {
            group = Ox.GetPlayerData().groups
        }

        TriggerEvent('interact:groupsChanged', Player.group)
   end
end)