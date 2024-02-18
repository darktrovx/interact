# World Interactions
Create interaction points in the world with selectable options.

# Credits
[ChatDisabled](https://github.com/Chatdisabled)

[Devyn](https://github.com/darktrovx)

[Zoo](https://github.com/FjamZoo)

[Snipe](https://github.com/pushkart2)

# Guides & Information

[Video Demo 1](https://youtu.be/dQ7Pdq1pdHQ)
[Video Demo 2](https://youtu.be/9ZLK0kl2k94)

Requires [ox_lib](https://github.com/overextended/ox_lib)

Options can trigger
```
Functions
Client Events
Server Events
```

# Options Format

```
 {
    label = 'Hello World!',
    canInteract = function(entity, coords, args)
        return true
    end,
    action = function(entity, coords, args)
    print(entity, coords, json.encode(args))
    end,
    serverEvent = "server:Event",
    event = "client:Event"
    args = {
        value1 = 'foo',
        [2] = 'bar',
        ['three'] = 0,
    }
 }

```

# Exports
```
-- Add an interaction point at a set of coords
exports.interact:AddInteraction({
    coords = vec3(0.0, 0.0, 0.0),
    distance = 8.0, -- optional
    interactDst = 1.0, -- optional
    id = 'myCoolUniqueId', -- needed for removing interactions
    name = 'interactionName', -- optional
    options = {
         {
            label = 'Hello World!',
            action = function(entity, coords, args)
                print(entity, coords, json.encode(args))
            end,
        },
    }
})

exports.interact:AddLocalEntityInteraction({
    entity = entityIdHere,
    name = 'interactionName', -- optional
    id = 'myCoolUniqueId', -- needed for removing interactions
    distance = 8.0, -- optional
    interactDst = 1.0, -- optional
    offset = vec3(0.0, 0.0, 0.0), -- optional
    options = {
        {
            label = 'Hello World!',
            action = function(entity, coords, args)
                print(entity, coords, json.encode(args))
            end,
        },
    }
})

-- Add an interaction point on a networked entity
exports.interact:AddInteractionEntity({
    netId = entityNetIdHere,
    name = 'interactionName', -- optional
    id = 'myCoolUniqueId', -- needed for removing interactions
    distance = 8.0, -- optional
    interactDst = 1.0, -- optional
    offset = vec3(0.0, 0.0, 0.0), -- optional
    options = {
        {
            label = 'Hello World!',
            action = function(entity, coords, args)
                print(entity, coords, json.encode(args))
            end,
        },
    }
})

-- Add an interaction point on a networked entity's bone
exports.interact:AddInteractionBone({
    entity = entityIdHere,
    bone = 'boneName',
    name = 'interactionName', -- optional
    id = 'myCoolUniqueId', -- needed for removing interactions
    distance = 8.0, -- optional
    interactDst = 1.0, -- optional
    offset = vec3(0.0, 0.0, 0.0), -- optional
    options = {
        {
            label = 'Hello World!',
            action = function(entity, coords, args)
                print(entity, coords, json.encode(args))
            end,
        },
    }
})

-- Add interaction(s) to a list of models
exports.interact:AddModelInteraction({
    modelData = {
        { model = 'modelNameHere1', offset = vec3(0.0, 0.0, 0.0) },
        { model = 'modelNameHere2', offset = vec3(0.0, 0.0, 0.0) },
    },
    name = 'interactionName', -- optional
    id = 'myCoolUniqueId', -- needed for removing interactions
    distance = 8.0, -- optional
    interactDst = 1.0, -- optional
    options = {
        {
            label = 'Hello World!',
            action = function(entity, coords, args)
                print(entity, coords, json.encode(args))
            end,
        },
    }
})

---@param id number : The id of the interaction to remove
-- Remove an interaction point by id.
exports.interact:RemoveInteraction(interactionID)

---@param id number : The id of the interaction to update
---@param options table : The new options to update the interaction with
-- Update an interaction point by id.
exports.interact:UpdateInteraction(interactionID, options)

```


# Using the API
```lua
    -- Imports the API library, must use ox_lib require function.
    local api = require '@interact.client.interactions'


    api.addInteraction({
        coords = vec3(0.0, 0.0, 0.0),
        distance = 8.0, -- optional
        interactDst = 1.0, -- optional
        id = 'myCoolUniqueId', -- needed for removing interactions
        name = 'interactionName', -- optional
        options = {
            {
                label = 'Hello World!',
                action = function(entity, coords, args)
                    print(entity, coords, json.encode(args))
                end,
            },
        }
    })

    api.addLocalEntityInteraction({
        entity = entityIdHere,
        name = 'interactionName', -- optional
        id = 'myCoolUniqueId', -- needed for removing interactions
        distance = 8.0, -- optional
        interactDst = 1.0, -- optional
        offset = vec3(0.0, 0.0, 0.0), -- optional
        options = {
            {
                label = 'Hello World!',
                action = function(entity, coords, args)
                    print(entity, coords, json.encode(args))
                end,
            },
        }
    })

    api.addModelInteraction({
        modelData = {
            { model = 'modelNameHere1', offset = vec3(0.0, 0.0, 0.0) },
            { model = 'modelNameHere2', offset = vec3(0.0, 0.0, 0.0) },
        },
        name = 'interactionName', -- optional
        id = 'myCoolUniqueId', -- needed for removing interactions
        distance = 8.0, -- optional
        interactDst = 1.0, -- optional
        options = {
            {
                label = 'Hello World!',
                action = function(entity, coords, args)
                    print(entity, coords, json.encode(args))
                end,
            },
        }
    })

    api.removeInteraction(interactionID)
    api.updateInteraction(interactionID, options)


    -- You can also import a singular api function such as:
    local addInteraction = require '@interact.client.interactions'.addInteraction

    addInteraction({
        coords = vec3(0.0, 0.0, 0.0),
        distance = 8.0, -- optional
        interactDst = 1.0, -- optional
        id = 'myCoolUniqueId', -- needed for removing interactions
        name = 'interactionName', -- optional
        options = {
            {
                label = 'Hello World!',
                action = function(entity, coords, args)
                    print(entity, coords, json.encode(args))
                end,
            },
        }
    })
```