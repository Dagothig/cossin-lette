local actor = { name = 'actor', set = {}, actions = {}, events = {} }

function actor.update(world, dt)
    for entity in world.by('actor') do
        local actor = entity.actor
        local input = entity.input
        local animator = entity.animator
        local physics = entity.physics
        local look_target = entity.look_target
        local move_target = entity.move_target

        if look_target then
            local look_diff = vec2.sub(look_target.target.pos, entity.pos)
            actor.vars.dir = math.atan2(-look_diff[2], look_diff[1])
        end

        -- Update state from desire to be somewhere
        if move_target then
            local move_diff = vec2.sub(move_target.pos, entity.pos)
            if vec2.len2(move_diff) < 4 then
                if actor.vars.moving then
                    -- TODO SLOPPY
                    world.events.trigger('arrival', entity, entity)
                end
                actor.vars.moving = false
            else
                actor.vars.moving = true
                actor.vars.dir = math.atan2(-move_diff[2], move_diff[1])
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

function actor.find_attached_text(world, entity)
    for _, other in pairs(entity.attached) do
        if other.text then
            return other
        end
    end
end

-- format { 'say', entity, text, { prefab = string, timeout = number, timeout_type = string } }
actor.actions.say = {
    start = function(world, entity, source, action)
        local speaker_str, text, args = unpack(action, 2)
        local speaker = actor.entity_for(world, entity, source, speaker_str)
        local timeout = args and args.timeout or (#text * S_PER_LETTER_TIMEOUT + S_TEXT_BASE_TIMEOUT)
        world.entities.add(world.prefabs.apply(
            world.prefabs[args and args.prefab or speaker.actor.speech],
            {
                text = { value = text },
                attach = { target = speaker }
            }))
        world.components.set(entity, 'timer', {
            remaining = timeout,
            type = args and args.timeout_type or 'completion'
        })
    end,
    stop = function(world, entity, source, action)
        local speaker_str, text, args = unpack(action, 2)
        local speaker = actor.entity_for(world, entity, source, speaker_str)
        local text_entity = actor.find_attached_text(world, speaker)
        world.components.unset(text_entity, 'text')
        world.components.unset(entity, 'timer')
    end,
    interaction = function(world, entity, source)
        world.events.trigger('completion', entity, source)
    end
}

-- format { 'move_to', entity, target }
actor.actions.move_to = {
    start = function(world, entity, source, action)
        local mover_str, pos = action[2], action[3]
        local mover = actor.entity_for(world, entity, source, mover_str)
        local current_pos = mover.pos or pos
        world.components.set(mover, 'move_target', { pos = pos })
        print(vec2.len(vec2.sub(current_pos, pos)) * S_PER_UNIT_TIMEOUT)
        world.components.set(mover, 'timer', {
            remaining = vec2.len(vec2.sub(current_pos, pos)) * S_PER_UNIT_TIMEOUT + S_MOVE_BASE_TIMEOUT,
            type = 'failure'
        })
    end,
    stop = function(world, entity, source, action)
        local mover_str, pos = action[2], action[3]
        local mover = actor.entity_for(world, entity, source, mover_str)
        world.components.unset(mover, 'move_target')
        world.components.unset(mover, 'timer')
    end,
    arrival = function(world, entity, source, action)
        world.events.trigger('completion', entity, source)
    end
}

-- format  { 'speak_to', looker, lookee }
actor.actions.look_at = {
    start = function(world, entity, source, action)
        local looker_str, lookee_str = action[2], action[3]
        local looker = actor.entity_for(world, entity, source, looker_str)
        local lookee = actor.entity_for(world, entity, source, lookee_str)
        if lookee then
            world.components.set(looker, 'look_target', { target = lookee })
        else
            world.components.unset(looker, 'look_target')
        end
        world.events.trigger('completion', entity)
    end,
}

actor.actions.var = {
    start = function(world, entity, source, action)
        local key, value = action[2], action[3]
        entity.actor.vars[key] = value
        world.events.trigger('completion', entity)
    end
}

actor.actions.wait = {
    start = function(world, entity, source, action)
        world.components.set(entity, 'timer', {
            remaining = action[2], type = 'completion'
        })
    end,
    stop = function(world, entity)
        world.components.unset(entity, 'timer')
    end
}

function actor.entity_for(world, entity, source, str)
    return str == 'entity' and entity or str == 'source' and source or nil
end

function actor.get_action(world, entity)
    return entity.actor.actions[entity.actor.action_index]
end

function actor.stop_action(world, entity, source)
    local action = actor.get_action(world, entity)
    print('stop', dump(action, nil, nil, { sep = '' }))
    if action and actor.actions[action[1]].stop then
        actor.actions[action[1]].stop(world, entity, source, action)
    end
end

function actor.start_action(world, entity, source, ...)
    local action = actor.get_action(world, entity)
    print('start', dump(action, nil, nil, { sep = '' }))
    if action and actor.actions[action[1]].start then
        actor.actions[action[1]].start(world, entity, source, action, ...)
    end
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
        local action = actor.get_action(world, entity)
        if action then
            if actor.actions[action[1]][type] then
                actor.actions[action[1]][type](world, entity, source, action, ...)
                return
            end
        end

        local state = actor.current_state(world, entity)
        if state and state[type] then
            actor.stop_action(world, entity, source)
            entity.actor.actions = state[type]
            entity.actor.action_index = 1
            actor.start_action(world, entity, source, ...)
        end
    end
end

function actor.events.completion(world, entity, source, ...)
    print('completion', entity.name, source and source.name)
    if entity.actor then
        actor.stop_action(world, entity, source)
        entity.actor.action_index = entity.actor.action_index + 1
        actor.start_action(world, entity, source, ...)
    end
end

function actor.events.failure(world, entity, source)
    print('failure', entity.name, source and source.name)
    if entity.actor then
        actor.stop_action(world, entity, source)
    end
end

return actor
