local actor = { name = 'actor', set = {}, actions = {} }

function actor.update(world, dt)
    for entity in world.by('actor') do
        local actor = entity.actor
        local input = entity.input
        local animator = entity.animator
        local physics = entity.physics
        local look_target = entity.look_target
        local move_target = entity.move_target

        if look_target then
            local look_diff = vec2.sub(look_target.pos, entity.pos)
            actor.vars.dir = math.atan2(look_diff[2], look_diff[1])
        end

        -- Update state from desire to be somewhere
        if move_target then
            local move_diff = vec2.sub(move_target.pos, entity.pos)
            if vec2.len2(move_diff) < 0.25 then
                actor.vars.moving = false
            else
                actor.vars.moving = true
                actor.vars.dir = math.atan2(move_diff[2], move_diff[1])
            end
        -- Update state from input
        elseif input then
            if input.x == 0 and input.y == 0 then
                actor.vars.moving = false
            else
                actor.vars.moving = true
                actor.vars.dir = math.atan2(input.y, input.x)
            end
        end
        -- Update animator flags from state
        if animator then
            animator.flags = {
                moving = actor.vars.moving,
                dir = actor.vars.dir and
                    (math.floor(actor.vars.dir / math.pi * 4 + 0.5) / 4) % 2
            }
        end
        -- Apply movement to body
        if physics then
            if actor.vars.moving then
                entity.physics:applyForce(
                    math.cos(actor.vars.dir) * actor.speed * DAMPING,
                    -math.sin(actor.vars.dir) * actor.speed * DAMPING)
            end
        end
    end

    for entity in world.by('timer') do
        entity.timer.remaining = entity.timer.remaining - dt
        if entity.timer.remaining < 0 then
            local type = entity.timer.type
            world.components.unset(entity, 'timer')
            world.events.trigger(type, entity)
        end
    end
end

function actor.set.actor(world, entity)
    local actor = entity.actor
    actor.actions = actor.actions or {}
    actor.vars = actor.vars or { moving = false, dir = -math.pi/2 }
end

function actor.set.input(world, entity)
    local input = entity.input
    input.x = input.x or 0
    input.y = input.y or 0
end

-- format { 'say', entity, text, { prefab = 'string', timeout = number } }
actor.actions.say = {
    start = function(world, entity, action, other)
        local source_str, text, args = unpack(action, 2)
        local source = actor.entity_for(world, entity, other, source_str)
        entity.actor.action_source = source
        world.entities.add(world.prefabs.apply(
            world.prefabs[args and args.prefab or source.actor.speech],
            {
                text = { value = text },
                attach = { target = source }
            }))
        world.components.set(entity, 'timer', {
            remaining = args and args.timeout or #text * MS_PER_LETTER_TIMEOUT,
            type = 'unresponsive'
        })
    end,
    interaction = function(world, entity)
        local source = actor.entity_for(world, entity, other, source_str)
        local text_entity = actor.find_attached_text(world, entity)
        world.components.unset(text_entity, 'text')
        world.components.unset(entity)
        world.events.trigger('completed', entity)
    end
}

-- format { 'move_to', entity, target }
actor.actions.move_to = {
    start = function(world, entity, action)
        local source_str, pos = unpack(action, 2)
        local source = actor.entity_for(world, entity, nil, source_str)
        local current_pos = source.pos or pos
        world.components.set(source, 'move_target', { pos = pos })
        world.components.set(source, 'timer', {
            remaining = vec2.len(vec2.sub(current_pos, pos)) * MS_PER_UNIT_TIMEOUT,
            type = 'failure'
        })
    end,
    arrival = function(world, entity, action)
        local source_str, pos = unpack(action, 2)
        local source = actor.entity_for(world, entity, nil, source_str)
        world.components.unset(source, 'move_target')
        world.components.unset(source, 'timer')
        world.events.trigger('completed', entity)
    end
}

-- format { 'fail' }
actor.actions.fail = {
    start = function(world, entity)
        world.events.trigger('failure', entity)
    end
}

actor.actions.look_at = {
    start = function(world, entity)
        world.components.set(source, 'look_target')
        world.events.trigger('completed', entity)
    end
}

actor.actions.var = {
    start = function(world, entity, action)
        local key, value = action[2], action[3]
        entity.actor.vars[key] = value
        world.events.trigger('completed', entity)
    end
}

function actor.entity_for(world, entity, source, str)
    return str == 'entity' and entity or str == 'source' and source or nil
end

function actor.start_action(world, entity, source, action, ...)
    action = action or entity.actor.actions[entity.actor.action_index]
    if type(action[1]) == 'table' then
        for i = 1, #action do
            actor.start_action(world, entity, action[i], ...)
        end
    else
        actor.actions[action[1]].start(world, entity, action, ...)
    end
end

function actor.complete_action(world, entity, other)
end

function actor.state_match(state, vars)
    for key, value in pairs(state.vars or {}) do
        if value ~= vars[key] then
            return false
        end
    end
    return true
end

function actor.current_state(world, entity)
    for i, state in ipairs(entity.actor) do
        if actor.state_match(state, entity.actor.vars) then
            return state
        end
    end
end

function actor.event(world, type, entity, source, ...)
    if entity.actor then
        local next_action = entity.actor.actions[entity.actor.action_index]
        if next_action then
            if actor[next_action[1]][type] then
                actor[next_action[1]][type](world, entity, source, next_action, ...)
                return
            end
        end

        local state = actor.current_state(world, entity)
        if state and state[type] then
            entity.actor.actions = state[type]
            entity.actor.action_index = 1
            actor.start_action(world, entity, source, nil, ...)
        end
    end
end

return actor
