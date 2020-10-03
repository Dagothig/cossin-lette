local events = require('systems/events')

local physics = { name = 'physics', shapes = {}, set = {}, unset = {} }

function physics.shapes.circle(body, body_physics)
    local shape = love.physics.newCircleShape(body.shape.size)
    local fixture = love.physics.newFixture(body_physics, shape, body.sensor and 0.000000001 or 1)
    body_physics:setFixedRotation(true)
    body_physics:setLinearDamping(DAMPING)
    return fixture
end

function physics.load(world)
    love.physics.setMeter(PIXEL_PER_METER)
    world.physics = love.physics.newWorld(0, 0, true)
    world.physics:setCallbacks(
        function(a, b)
            local entityA = a:getBody():getUserData()
            local entityB = b:getBody():getUserData()
            if entityA and entityB and entityA ~= entityB then
                if entityA.body and entityA.body.enter then
                    entityA.body.enter(world, entityB)
                end
                if entityB.body and entityB.body.enter then
                    entityB.body.enter(world, entityA)
                end
            end
        end,
        function(a, b)
            local entityA = a:getBody():getUserData()
            local entityB = b:getBody():getUserData()
            if entityA and entityB and entityA ~= entityB then
                if entityA.body and entityA.body.exit then
                    entityA.body.exit(world, entityB)
                end
                if entityB.body and entityB.body.exit then
                    entityB.body.exit(world, entityA)
                end
            end
        end)
end

function physics.unload(world)
    world.physics:destroy()
    world.physics = nil
end

function physics.set.body(world, entity)
    local body = entity.body
    local sensor = body.sensor
    local sensor_offset = sensor and (sensor.offset or { 0, 0 })
    local pos = entity.pos or sensor and vec2.add(sensor.target.pos, sensor_offset) or { 0, 0 }

    local body_physics = love.physics.newBody(world.physics, pos[1], pos[2], "dynamic")
    body_physics:setUserData(entity)

    local fixture = physics.shapes[body.shape.type](body, body_physics)

    if body.sensor then
        fixture:setSensor(true)
    end

    if sensor then
        love.physics.newWeldJoint(
            sensor.target.physics,
            body_physics,
            pos[1] + sensor_offset[1], pos[2] + sensor_offset[2],
            pos[1], pos[2],
            false, 0)

        if not sensor.target.sensors then
            world.components.set(sensor.target, 'sensors', {})
        end
        sensor.target.sensors[entity.name] = entity

        body.enter = function(world, other)
            events.trigger_target(world, 'enter', other, sensor.target)
        end

        body.exit = function(world, other)
            events.trigger_target(world, 'exit', other, sensor.target)
        end
    end

    world.components.set(entity, 'physics', body_physics)
end

function physics.unset.body(world, entity)
    if entity.sensor and entity.sensor.target then
        entity.sensor.target.sensors[entity.name] = nil
    end
    entity.physics:destroy()
    world.components.unset(entity, 'physics')
end

function physics.update(world, dt)
    world.physics:update(dt)
    -- Update positions
    for entity in world.by('body') do
        local pos, physics, actor = entity.pos, entity.physics, entity.actor
        if physics then
            if pos and physics:isAwake() then
                entity.pos = { physics:getWorldCenter() }
            end
            if actor then
                physics:setAngle(actor.state.dir and -actor.state.dir or 0)
            end
        end
    end
end

return physics
