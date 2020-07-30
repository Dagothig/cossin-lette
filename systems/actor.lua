local actor = {}

function actor.update(components, dt)
    for entity, actor in pairs(components.actors) do
        -- Moving
        if actor.input.x == 0 and actor.input.y == 0 then
            actor.state.moving = false
        else
            actor.state.moving = true
            actor.state.dir = math.atan2(actor.input.y, actor.input.x)
        end
        -- Flags
        local animator = components.animators[entity]
        if animator then
            animator.flags = {
                moving = actor.state.moving,
                dir = actor.state.dir and (math.floor(actor.state.dir / math.pi * 4 + 0.5) / 4) % 2
            }
        end
        -- Applying movement
        local body = components.bodies[entity]
        if body then
            if actor.state.moving then
                body.body:applyLinearImpulse(
                    math.cos(actor.state.dir) * actor.speed * 32, 
                    -math.sin(actor.state.dir) * actor.speed * 32)
            end
        end
    end
end

return actor
