
-- Code taken from Tabby: https://github.com/tabarra/txAdmin/blob/7d718ba50d38c5cfe9221288c4fec7e4beefafb8/resource/menu/client/cl_vehicle.lua#L77
VehClassNamesEnum = {
    [8] = "bike",
    [11] = "trailer",
    [13] = "bike",
    [14] = "boat",
    [15] = "heli",
    [16] = "plane",
    [21] = "train",
}

MismatchedTypes = {
    ["airtug"] = "automobile",       -- trailer
    ["avisa"] = "submarine",         -- boat
    ["blimp"] = "heli",              -- plane
    ["blimp2"] = "heli",             -- plane
    ["blimp3"] = "heli",             -- plane
    ["caddy"] = "automobile",        -- trailer
    ["caddy2"] = "automobile",       -- trailer
    ["caddy3"] = "automobile",       -- trailer
    ["chimera"] = "automobile",      -- bike
    ["docktug"] = "automobile",      -- trailer
    ["forklift"] = "automobile",     -- trailer
    ["kosatka"] = "submarine",       -- boat
    ["mower"] = "automobile",        -- trailer
    ["policeb"] = "bike",            -- automobile
    ["ripley"] = "automobile",       -- trailer
    ["rrocket"] = "automobile",      -- bike
    ["sadler"] = "automobile",       -- trailer
    ["sadler2"] = "automobile",      -- trailer
    ["scrap"] = "automobile",        -- trailer
    ["slamtruck"] = "automobile",    -- trailer
    ["Stryder"] = "automobile",      -- bike
    ["submersible"] = "submarine",   -- boat
    ["submersible2"] = "submarine",  -- boat
    ["thruster"] = "heli",           -- automobile
    ["towtruck"] = "automobile",     -- trailer
    ["towtruck2"] = "automobile",    -- trailer
    ["tractor"] = "automobile",      -- trailer
    ["tractor2"] = "automobile",     -- trailer
    ["tractor3"] = "automobile",     -- trailer
    ["trailersmall2"] = "trailer",   -- automobile
    ["utillitruck"] = "automobile",  -- trailer
    ["utillitruck2"] = "automobile", -- trailer
    ["utillitruck3"] = "automobile", -- trailer
}

function GetTrunkOffset(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    return GetOffsetFromEntityInWorldCoords(entity, 0.0, min.y - 0.5, 0.0)
end