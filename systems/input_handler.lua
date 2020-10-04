local input_handler = {
    name = 'input_handler',
    events = {}
}

function input_handler.keypressed(world, key)
    for entity in world.by('keys') do
        local entry, sensors = entity.keys[key], entity.sensors
        if entry then
            local input = entity.input
            if entry.value and input then
                input[entry.type] = (input[entry.type] or 0) + entry.value
            end

            world.events.trigger('input_start', entity, entry.type)
        end
    end
end

function input_handler.update(world, dt)
    for entity in world.by('input') do
        local input, keys = entity.input, entity.keys
        -- Reset input
        for type, value in pairs(input) do
            input[type] = 0
        end
        -- Check active key states
        if keys then
            for key, entry in pairs(keys) do
                if entry.value and love.keyboard.isDown(key) then
                    input[entry.type] = input[entry.type] + entry.value
                end
            end
        end
    end
end

return input_handler
