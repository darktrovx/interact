CurrentTarget = nil

local function GetForwardVector(rotation)
    local rot = (math.pi / 180.0) * rotation
    return vector3(-math.sin(rot.z) * math.abs(math.cos(rot.x)), math.cos(rot.z) * math.abs(math.cos(rot.x)), math.sin(rot.x))
end

local function RayCast(origin, target, options, ignoreEntity, radius)
    local handle = StartShapeTestSweptSphere(origin.x, origin.y, origin.z, target.x, target.y, target.z, radius, options, ignoreEntity, 0)
    return GetShapeTestResult(handle)
end

local function EntityInFrontOfPlayer(distance, radius, flag, ignoreEntity)
    local distance = distance or 3.0
    local originCoords = GetPedBoneCoords(PlayerPedId(), 31086)
    local forwardVectors = GetForwardVector(GetGameplayCamRot(2))
    local forwardCoords = originCoords + (forwardVectors * distance)

    if not forwardVectors then return end

    local _, hit, targetCoords, _, targetEntity = RayCast(originCoords, forwardCoords, -1, ignoreEntity, radius or 0.2)

    if not hit and targetEntity == 0 then return end

    local entityType = GetEntityType(targetEntity)

    return targetEntity, entityType, targetCoords
end

CreateThread(function()
    while true do
        local coord = GetEntityCoords(PlayerPedId())

        Wait(250)
        local entity, entityType, entityCoords
        pcall(function() entity, entityType, entityCoords = EntityInFrontOfPlayer(3.0, 0.2, 286, PlayerPedId()) end)
        if entity and entityType ~= 0 then
            if entity ~= CurrentTarget then
                CurrentTarget = entity
            end
        elseif CurrentTarget then
            CurrentTarget = nil
        end

    end
end)
