local physics = {}

function physics.load(components)
    love.physics.setMeter(32)
    components.world = love.physics.newWorld(0, 0, true)
end

function physics.cleanup(components)
    components.world:destroy()
end

local shapes = {}

function shapes.circle(entry)
    local shape = love.physics.newCircleShape(entry.shape.size)
    local fixture = love.physics.newFixture(entry.body, shape, 1)
    entry.body:setFixedRotation(true)
    entry.body:setLinearDamping(32)
end

function physics.update(components, dt)
   components.world:update(dt)
   for entity, entry in pairs(components.bodies) do
        -- Check for body cleanup
        if entry.remove then
            if entry.body then
                entry.body:destroy()
                entry.body = nil
            end
            components.bodies[entity] = nil
            goto next
        -- Check for body creation
        elseif not entry.body then
            entry.body = love.physics.newBody(
                components.world,
                entry.pos[1],
                entry.pos[2],
                "dynamic")
            shapes[entry.shape.type](entry)
        end
        -- Check for sprite updates
        local sprite = components.sprites[entity]
        if sprite then
            sprite.pos[1], sprite.pos[2] = entry.body:getWorldCenter()
        end
        ::next::
   end
end

return physics
