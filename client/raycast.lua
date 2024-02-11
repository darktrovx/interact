CurrentTarget = nil

local StartShapeTestSweptSphere = StartShapeTestSweptSphere
local GetShapeTestResult = GetShapeTestResult
local GetPedBoneCoords = GetPedBoneCoords
local GetGameplayCamRot = GetGameplayCamRot
local GetEntityType = GetEntityType

local function getForwardVector(rotation)
    local rot = (math.pi / 180.0) * rotation
    return vector3(-math.sin(rot.z) * math.abs(math.cos(rot.x)), math.cos(rot.z) * math.abs(math.cos(rot.x)), math.sin(rot.x))
end

local function rayCast(origin, target, options, ignoreEntity, radius)
    local handle = StartShapeTestSweptSphere(origin.x, origin.y, origin.z, target.x, target.y, target.z, radius, options, ignoreEntity, 0)
    return GetShapeTestResult(handle)
end

local function entityInFrontOfPlayer(distance, radius, _, ignoreEntity)
    distance = distance or 3.0
    local originCoords = GetPedBoneCoords(cache.ped, 31086, 0, 0, 0)
    local forwardVectors = getForwardVector(GetGameplayCamRot(2))
    local forwardCoords = originCoords + (forwardVectors * distance)

    if not forwardVectors then return end

    local _, hit, _, _, targetEntity = rayCast(originCoords, forwardCoords, -1, ignoreEntity, radius or 0.2)

    if not hit and targetEntity == 0 then return end

    local entityType = GetEntityType(targetEntity)

    return targetEntity, entityType
end

CreateThread(function()
    while true do
        Wait(250)
        local entity, entityType
        pcall(function() entity, entityType, _ = entityInFrontOfPlayer(3.0, 0.2, 286, cache.ped) end)
        if entity and entityType ~= 0 then
            if entity ~= CurrentTarget then
                CurrentTarget = entity
            end
        elseif CurrentTarget then
            CurrentTarget = nil
        end

    end
end)
