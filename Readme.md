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

# Examples

## Add Coords Interaction
```
exports.interact:AddInteraction(vec3(0.0, 0.0, 0.0), {
    {
        label = 'Hello World',
        action = function()
            print('Hello World')
        end,
    }
}, 
{
    distance = 7.0, 
    interactDst = 1.5,
})
```

## Add Entity Interaction
```
exports.interact:AddLocalEntityInteraction(entity, {
    {
        label = 'Hello World',
        action = function(entity)
            print(string.format('Interacted with entity:%s', entity))
        end,
    }
}, 
{
    distance = 7.0, 
    interactDst = 1.5,
})

```

## Add Model Interaction

```
exports["interact"]:AddModelInteraction({
        { model = 'p_dumpster_t', offset = vec(0.0, 0.0, 1.0) },
        { model = 'prop_dumpster_3a', offset = vec(0.0, 0.0, 1.0) },
        { model = 'prop_dumpster_02a', offset = vec(0.0, 0.0, 1.0) },
    }, {
        {
            label = 'Collect',
            action = function(entity, coords, args)
                CollectTrash(entity)
            end,
        },
    },{
        distance = 10.0,
        interactDst = 1.0,
    })
```
