local function getForwardVector(rotation)
    local rot = (math.pi / 180.0) * rotation
    return vector3(-math.sin(rot.z) * math.abs(math.cos(rot.x)), math.cos(rot.z) * math.abs(math.cos(rot.x)), math.sin(rot.x))
end

local function rayCast(origin, target, options, ignoreEntity, radius)
    local handle = StartShapeTestSweptSphere(origin.x, origin.y, origin.z, target.x, target.y, target.z, radius, options, ignoreEntity, 0)
    return GetShapeTestResult(handle)
end

local function entityInFrontOfPlayer(distance, radius, ignoreEntity)
    local originCoords = GetPedBoneCoords(cache.ped, 31086, 0, 0, 0)
    local forwardVectors = getForwardVector(GetGameplayCamRot(2))
    local forwardCoords = originCoords + (forwardVectors * (distance or 3.0))

    if not forwardVectors then return end

    local _, hit, _, _, targetEntity = rayCast(originCoords, forwardCoords, -1, ignoreEntity, radius or 0.2)

    if not hit and targetEntity == 0 then return end

    local entityType = GetEntityType(targetEntity)

    return targetEntity, entityType
end

return function()
    local entity, entityType
    pcall(function() entity, entityType = entityInFrontOfPlayer(3.0, 0.2, cache.ped) end)

    return entity and entityType ~= 0 and entity or nil
end