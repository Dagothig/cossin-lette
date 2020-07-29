function dump(o, pre)
    pre = pre or ''
    if type(o) == 'table' then
        local s = '{'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then
                k = k .. ' = '
            else
                k = ''
            end
            s = s .. '\n  ' .. pre .. k .. dump(v, pre .. '  ') .. ','
        end
        return s .. '\n' .. pre .. '}'
    else
        return tostring(o)
    end
 end

function find(fn, arr)
    for k, v in pairs(arr) do
        if fn(v) then
            return k, v
        end
    end
end

function cpy(t)
    local t2 = {}
    for k,v in pairs(t) do t2[k] = v end
    return t2
end

function push(arr, x)
    arr[#arr + 1] = x
end

function is_num(x)
    return type(x) == 'number'
end

components = {
    sheets = {},
    sprites = {},
    animators = {},
    inputs = {},
    actors = {}
}

systems = {
    sprite_renderer = {},
    input_handler = {},
    actor = {}
}

function systems.sprite_renderer.load()
    for _, sheet in pairs(components.sheets) do
        for _, entry in ipairs(sheet) do
            entry.img = entry.img or love.graphics.newImage('img/' .. entry.src)
            local width, height = entry.img:getDimensions()
            entry.frame_time = 1 / entry.fps
            entry.tiles = width / entry.size[1]
            entry.flags = entry.flags or {}
            entry.strips = {}
            for y, flags in ipairs(entry.flags_y) do
                -- Create a strip
                local strip = { flags = flags }
                for x = 1, entry.tiles do
                    local quad = love.graphics.newQuad(
                        (x - 1) * entry.size[1], (y - 1) * entry.size[2],
                        entry.size[1], entry.size[2], 
                        width, height)
                    push(strip, { quad = quad, scale = { 1, 1 } })
                end
                push(entry.strips, strip)
                -- Find the dir in the flags if it exists, and infer the flip dir.
                local i, dir = find(is_num, flags)
                local flip = dir and (2 + 1 - dir) % 2
                if flip and flip ~= dir then
                    local flip_flags = cpy(flags)
                    flip_flags[i] = flip
                    local flip_strip = { flags = flip_flags }
                    for x = 1, entry.tiles do
                        push(flip_strip, { quad = strip[x].quad, scale = { -1, 1 } })
                    end
                    push(entry.strips, flip_strip)
                end
            end
        end
    end

    for _, animator in pairs(components.animators) do
        animator.time = 0
    end
end

function systems.sprite_renderer.draw()
    for entity, sprite in pairs(components.sprites) do
        local sheet = components.sheets[entity]
        local entry = sheet[sprite.entry]
        local strip = entry.strips[sprite.strip]
        local tile = strip[sprite.tile]
        love.graphics.draw(
            entry.img,
            tile.quad,
            sprite.pos[1], sprite.pos[2],
            0, 
            tile.scale[1], tile.scale[2],
            entry.decal[1], entry.decal[2])
    end
end

function find_entry(animator, sheet, sprite)
    local entry, strip = 1, 1

    for i, oentry in ipairs(sheet) do
        local ocount = 0
        for _, oflag in pairs(oentry.flags) do
            for _, flag in pairs(animator.flags) do
                if flag == oflag then
                    goto next
                end
            end
            goto next_entry
            ::next::
        end
        entry = i
        ::next_entry::
    end

    for i, ostrip in ipairs(sheet[entry].strips) do
        for _, oflag in pairs(ostrip.flags) do
            for _, flag in pairs(animator.flags) do
                if flag == oflag then
                    goto next
                end
            end
            goto next_strip
            ::next::
        end
        strip = i
        ::next_strip::
    end
    
    if sprite.entry ~= entry or sprite.strip ~= strip then
        sprite.tile = 1
        animator.time = 0
    end
    sprite.entry = entry
    sprite.strip = strip
end

function systems.sprite_renderer.update(dt)
    for entity, animator in pairs(components.animators) do
        -- Establish entry and strip
        local sprite = components.sprites[entity]
        local sheet = components.sheets[entity]
        find_entry(animator, sheet, sprite)
        local entry = sheet[sprite.entry]
        -- Increment tile animation
        if entry.frame_time then
            animator.time = animator.time + dt
            while animator.time > entry.frame_time do
                animator.time = animator.time - entry.frame_time
                sprite.tile = (sprite.tile % entry.tiles) + 1
            end
        end
    end
end

function systems.input_handler.keypressed(key)
    for entity, input in pairs(components.inputs) do
        local actor = components.actors[entity]
        local entry = input.keys[key]
        if actor and entry then
            actor.input[entry.type] = actor.input[entry.type] + entry.value
        end
    end
end

function systems.input_handler.update(dt)
    for entity, input in pairs(components.inputs) do
        local actor = components.actors[entity]
        if actor then
            for type, value in pairs(actor.input) do
                if value then
                    actor.input[type] = 0
                end
            end
            for key, entry in pairs(input.keys) do
                if love.keyboard.isDown(key) then
                    if entry.value then 
                        actor.input[entry.type] = actor.input[entry.type] + entry.value
                    end
                end
            end
        end
    end
end

function systems.actor.update(dt)
    for entity, actor in pairs(components.actors) do
        if actor.input.x == 0 and actor.input.y == 0 then
            actor.moving = false
        else
            local input_dir = math.atan2(actor.input.y, actor.input.x) / math.pi
            actor.moving = true
            actor.dir = (math.floor(input_dir * 4 + 0.5) / 4) % 2
        end
        local animator = components.animators[entity]
        if animator then
            animator.flags = { actor.dir }
            if actor.moving then
                push(animator.flags, 'moving')
            end
        end
        ::continue::
    end
end

function call_systems(key, ...)
    for k, system in pairs(systems) do
        if system[key] then
            system[key](...)
        end
    end
end

function love.load()
    cossin = 0
    components.sheets[cossin] = require('img/cossin')
    components.sprites[cossin] = { pos = { 160, 160 }, entry = 1, strip = 1, tile = 1 }
    components.animators[cossin] = { flags = {} }
    components.actors[cossin] = { input = { x = 0, y = 0 }, dir = 0, speed = 1 }
    components.inputs[cossin] = {
        keys = {
            up = { type = "y", value = 1 },
            left = { type = "x", value = -1 },
            right = { type = "x", value = 1 },
            down = { type = "y", value = -1 }
        }
    }

    baba = 1
    components.sheets[baba] = require('img/cossin')
    components.sprites[baba] = { pos = { 300, 180 }, entry = 1, strip = 3, tile = 2 }
    components.animators[baba] = { flags = { 0.25 } }
    
    call_systems('load')
end

function love.keypressed(key)
    call_systems('keypressed', key)
end

function love.keyreleased(key)
    call_systems('keyreleased', key)
end

function love.update(dt)
    call_systems('update', dt)
end

function love.draw()
    call_systems('draw')
end
