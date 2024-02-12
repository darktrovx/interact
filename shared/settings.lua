-- How to add a new style:
-- 1. Make a new folder in assets/ with the name of your style.
-- 2. Use the same image names as you see in the default folder style.
-- 3. Change the Style variable below to the name of your folder.
-- 4. Enjoy your new style!

return {
    Debug = GetConvar('debug', 'false') == 'true' and true or false, -- Enable / Disable debug mode
    Style = 'gold_circle', -- gold_circle (default), blue_circle, green_square, glitch 
    Textures = { -- Do not change
        pin = 'pin',
        interact = 'interact',
        selected = 'selected',
        unselected = 'unselected',
        select_opt = 'select_opt',
        unselect_opt = 'unselect_opt',
    },
    Disable = {
        onDeath = true, -- Disable interactions on death
        onNuiFocus = true, -- Disable interactions while NUI is focused
        onVehicle = true, -- Disable interactions while in a vehicle
        onHandCuff = true, -- Disable interactions while handcuffed
    },

    -- Nearby object distance check.
    nearbyObjectDistance = 20.0, -- Keep it at 15.0 at minimum.
    nearbyVehicleDistance = 4.0,

    vehicleBoneDefaults = {
        enabled = true,
        bones = {
            ['boot'] = {
                distance = 3.0,
                interactDst = 1.5,
                offset = vec3(0.0, 1.0, 0.0),
                options = {
                    {
                        name = 'interact:trunk',
                        label = 'Trunk',
                        action = function(entity)
                            print('Trunk')
                        end
                    }
                }

            }
        }

    },
}
