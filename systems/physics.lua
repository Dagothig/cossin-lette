local physics = { name = 'physics', shapes = {}, set = {}, unset = {} }

function physics.shapes.circle(body, body_physics)
    local shape = love.physics.newCircleShape(body.shape.size)
    local fixture = love.physics.newFixture(body_physics, shape, 1)
    body_physics:setFixedRotation(true)
    body_physics:setLinearDamping(32)
end

function physics.load(world)
    love.physics.setMeter(PIXEL_PER_METER)
    world.physics = love.physics.newWorld(0, 0, true)
end

function physics.unload(world)
    world.physics:destroy()
    world.physics = nil
end

function physics.set.body(world, entity)
    local body = entity.body
    local body_physics = love.physics.newBody(
        world.physics,
        entity.pos[1],
        entity.pos[2],
        "dynamic")
    physics.shapes[body.shape.type](body, body_physics)
    world.components.set(entity, 'physics', body_physics)
end

function physics.unset.body(world, entity)
    entity.physics:destroy()
    world.components.unset(entity, 'physics')
end

function physics.update(world, dt)
    world.physics:update(dt)
    -- Update positions
    for entity in world.by('body') do
        local pos, physics = entity.pos, entity.physics
        if pos and physics then
            entity.pos = { physics:getWorldCenter() }
        end
    end
end

return physics
