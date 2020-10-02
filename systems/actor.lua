local actor = { name = 'actor', set = {} }

function actor.update(world, dt)
    for entity in world.by('actor') do
        local actor, input, animator, physics =
            entity.actor, entity.input, entity.animator, entity.physics
        -- Update state from input
        if input then
            if input.x == 0 and input.y == 0 then
                actor.state.moving = false
            else
                actor.state.moving = true
                actor.state.dir = math.atan2(input.y, input.x)
            end
        end
        -- Update animator flags from state
        if animator then
            animator.flags = {
                moving = actor.state.moving,
                dir = actor.state.dir and
                    (math.floor(actor.state.dir / math.pi * 4 + 0.5) / 4) % 2
            }
        end
        -- Apply movement to body
        if physics then
            if actor.state.moving then
                entity.physics:applyForce(
                    math.cos(actor.state.dir) * actor.speed * DAMPING,
                    -math.sin(actor.state.dir) * actor.speed * DAMPING)
            end
        end
    end
end

function actor.set.actor(world, entity)
    local actor = entity.actor
    actor.state = actor.state or {}
end

function actor.set.input(world, entity)
    local input = entity.input
    input.x = input.x or 0
    input.y = input.y or 0
end

return actor
