# World Interactions
Create interaction points in the world with selectable options.

# Credits
[ChatDisabled](https://github.com/Chatdisabled)

[Devyn](https://github.com/darktrovx)

[Zoo](https://github.com/FjamZoo)

[Snipe](https://github.com/pushkart2)

# Guides & Information

Requires [ox_lib](https://github.com/overextended/ox_lib)

Options can trigger
```
Functions
Client Events
Server Events
```

# Options

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

# Data
```
{
    distance = 10.0, -- Min distance to display pin on screen.
    interactDst = 1.0, -- Min distance player has to be to interact.
    offset = vec3(0.0, 0.0, 0.0) -- Offset for the pin/interact to display at.
}
```

# Exports
```
---@param coords vec3 : The coords to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst }
-- Add an interaction point at a set of coords
exports.interact:AddInteraction(coords, options, data)

---@param entity number : The entity to add the interaction to
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a networked entity
exports.interact:AddInteractionEntity(entity, options, data)

---@param entityData table : { entity[number|string], bone[string] }
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, offset }
-- Add an interaction point on a networked entity's bone
exports.interact:AddInteractionBone(entity, bone, options, data)

---@param modelData table : { model[string], offset[vec3] }
---@param options table : { label, action, event, serverEvent, args }
---@param data table : { distance, interactDst, resource }
-- Add interaction(s) to a list of models
exports.interact:AddModelInteraction(modelData, bone, options, data)

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
