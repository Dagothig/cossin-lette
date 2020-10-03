local events = {}

function events.trigger_colliding(world, event, payload, sensor)
    local contacts = sensor.physics:getContacts()
    local i = 1
    events.trigger(world, event, payload, function()
        while i <= #contacts do
            local contact = contacts[i]
            i = i + 1
            if contact:isTouching() then
                local fa, fb = contact:getFixtures()
                local ba, bb = fa:getBody(), fb:getBody()
                local ea, eb = ba:getUserData(), bb:getUserData()
                local other = ea == sensor and eb or ea
                return other
            end
        end
    end)
end

function events.trigger(world, event, payload, entities)
    for entity in entities do
        events.trigger_target(world, event, payload, entity)
    end
end

function events.trigger_target(world, event, payload, entity)
    local script = entity.script
    if script and script[event] then
        script[event](world, entity, payload)
    end
end

return events
