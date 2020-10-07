local physics = {
    name = 'physics',
    shapes = {},
    set = {},
    unset = {},
    events = {}
}

function physics.shapes.circle(body, body_physics)
    local shape = love.physics.newCircleShape(body.shape.radius)
    local fixture = love.physics.newFixture(body_physics, shape, body.sensor and 0.000000001 or 1)
    body_physics:setFixedRotation(true)
    body_physics:setLinearDamping(DAMPING)
    return fixture
end

function physics.entities_in_contact(entity)
    local physics = entity.physics
    local contacts = physics:getContacts()
    local i = 1
    return function()
        while i <= #contacts do
            local contact = contacts[i]
            i = i + 1
            if contact:isTouching() then
                local fa, fb = contact:getFixtures()
                local ba, bb = fa:getBody(), fb:getBody()
                local ea, eb = ba:getUserData(), bb:getUserData()
                local other = ea == entity and eb or ea
                return other
            end
        end
    end
end

function physics.load(world)
    love.physics.setMeter(PIXEL_PER_METER)
    world.physics = love.physics.newWorld(0, 0, true)
    world.physics:setCallbacks(
        function(a, b)
            local entityA = a:getBody():getUserData()
            local entityB = b:getBody():getUserData()
            if entityA and entityB and entityA ~= entityB then
                world.events.trigger('collision_start', entityA, entityB)
                world.events.trigger('collision_start', entityB, entityA)
            end
        end,
        function(a, b)
            local entityA = a:getBody():getUserData()
            local entityB = b:getBody():getUserData()
            if entityA and entityB and entityA ~= entityB then
                world.events.trigger('collision_end', entityA, entityB)
                world.events.trigger('collision_end', entityB, entityA)
            end
        end)
end

function physics.unload(world)
    world.physics:destroy()
    world.physics = nil
end

function physics.events.collision_start(world, entityA, entityB)
    if entityA.body and entityA.body.sensor and entityA.attach then
        -- entity, source, sensor
        world.events.trigger('sensor_enter', entityA.attach.target, entityB, entityA)
    end
end

function physics.events.collision_end(world, entityA, entityB)
    if entityA.body and entityA.body.sensor and entityA.attach then
        -- entity, source, sensor
        world.events.trigger('sensor_exit', entityA.attach.target, entityB, entityA)
    end
end

function physics.events.input_start(world, entity, source, type)
    for _, attached in pairs(entity.attached or {}) do
        if attached.body and attached.body.sensor == type then
            for other in physics.entities_in_contact(attached) do
                if other ~= entity then
                    world.events.trigger(type, other, entity)
                end
            end
        end
    end
end

function physics.set.body(world, entity)
    local body = entity.body
    local pos = entity.pos or { 0, 0 }

    local body_physics = love.physics.newBody(world.physics, pos[1], pos[2], "dynamic")
    body_physics:setUserData(entity)

    local fixture = physics.shapes[body.shape.type](body, body_physics)
    if body.sensor then
        fixture:setSensor(true)
        fixture:setCategory(2)
        fixture:setMask(2)
    else
        fixture:setCategory(1)
    end

    world.components.set(entity, 'physics', body_physics)
end

function physics.unset.body(world, entity)
    entity.physics:destroy()
    world.components.unset(entity, 'physics')
end

systems.set.all(physics, { 'attach', 'physics' }, function(world, entity)
    local attach, physics = entity.attach, entity.physics
    local offset = attach.offset or { 0, 0 }
    local attach_pos = entity.attach.target and entity.attach.target.pos or { 0, 0 }
    local pos = vec2.add(entity.pos or attach_pos, offset)

    physics:setPosition(pos[1], pos[2])

    attach.physics = love.physics.newWeldJoint(
        attach.target.physics,
        entity.physics,
        pos[1], pos[2],
        pos[1], pos[2],
        false, 0)
end)

function physics.unset.attach(world, entity)
    local attach = entity.attach
    if attach.physics then
        attach.physics:destroy()
        attach.physics = nil
    end
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
                physics:setAngle(actor.vars.dir and -actor.vars.dir or 0)
            end
        end
    end
end

return physics
