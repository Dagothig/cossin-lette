local input_handler = {}

function input_handler.keypressed(components, key)
    for entity, input in pairs(components.inputs) do
        local actor = components.actors[entity]
        local entry = input.keys[key]
        if actor and entry then
            actor.input[entry.type] = actor.input[entry.type] + entry.value
        end
    end
end

function input_handler.update(components, dt)
    for entity, input in pairs(components.inputs) do
        local actor = components.actors[entity]
        if actor then
            for type, value in pairs(actor.input) do
                if value then
                    actor.input[type] = 0
                end
            end
            for key, entry in pairs(input.keys) do
                if love.keyboard.isDown(key) then
                    if entry.value then 
                        actor.input[entry.type] = actor.input[entry.type] + entry.value
                    end
                end
            end
        end
    end
end

return input_handler
