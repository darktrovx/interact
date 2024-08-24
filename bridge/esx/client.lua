local Player = {}
local Loaded = false

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

    TriggerEvent('interact:groupsChanged', Player.Group)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Player = table.wipe(Player)

    TriggerEvent('interact:groupsChanged', {})
end)