local events = require('systems/events')

local input_handler = {
    name = 'input_handler',
    set = {}
}

function input_handler.keypressed(world, key)
    for entity in world.by('keys') do
        local entry = entity.keys[key]
        if entry then
            local input = entity.input
            if input then
                input[entry.type] = (input[entry.type] or 0) + entry.value
            end

            local sensor = entity.sensors and entity.sensors[entry.type]
            if sensor and sensor.physics then
                events.trigger_colliding(world, entry.type, entity, sensor)
            end
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
                if love.keyboard.isDown(key) then
                    input[entry.type] = input[entry.type] + entry.value
                end
            end
        end
    end
end

return input_handler
