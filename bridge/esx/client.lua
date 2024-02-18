local Player = {}
local Loaded = false

local Bridge = {}

function Bridge.getPlayerGroup()
    return Player and Player.Group or {}
end

RegisterNetEvent('esx:setPlayerData', function(key, value)
	if not Loaded or GetInvokingResource() ~= 'es_extended' then return end

    if key ~= 'job' then return end

    Player.Group = { [value.name] = value.grade }


    TriggerEvent('interact:groupsChanged', Player.Group)
end)

RegisterNetEvent('esx:playerLoaded',function(xPlayer)
    Player = {
        Group = {
            [xPlayer.job.name] = xPlayer.job.grade,
        },
    }

    Loaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Player = table.wipe(Player)
end)

return Bridge