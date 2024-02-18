local file = ('imports/%s.lua'):format('client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

local Player = {}
local Bridge = {}

function Bridge.getPlayerGroup()
    return Player and Player.group
end

RegisterNetEvent('ox:setGroup', function(name, grade)
    Player.group[name] = grade

    TriggerEvent('interact:groupsChanged', Player.Group)
end)

AddEventHandler('ox:playerLoaded', function(data)
    Player = {
        group = Ox.GetPlayerData().groups
    }
end)

AddEventHandler('ox:playerLogout', function()
    table.wipe(Player)
end)

AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
        Player = {
            group = Ox.GetPlayerData().groups
        }
   end
end)

return Bridge