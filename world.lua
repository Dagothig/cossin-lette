local sparse = require('util/sparse')

PIXEL_PER_METER = 32

function weak_table()
    local tbl = {}
    local meta = {}
    meta.__mode = 'k'
    setmetatable(tbl, meta)
    return tbl
end

input_handler = { name = 'input_handler', set = {} }

function input_handler.keypressed(world, key)
    for entity in world.by('keys') do
        local entry, input = entity.keys[key], entity.input
        if entry and input then
            input[entry.type] = input[entry.type] + entry.value
        end
    end
end

function input_handler.update(world, dt)
    for entity in world.by('input') do
        local input, keys = entity.input, entity.keys
        -- Reset input
        for type, value in pairs(input) do
            input[type] = 0
        end
        -- Check active key states
        if keys then
            for key, entry in pairs(keys) do
                if love.keyboard.isDown(key) then
                    input[entry.type] = input[entry.type] + entry.value
                end
            end
        end
    end
end

actor = { name = 'actor', set = {} }

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
                entity.physics:applyLinearImpulse(
                    math.cos(actor.state.dir) * actor.speed * 32,
                    -math.sin(actor.state.dir) * actor.speed * 32)
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

physics = { name = 'physics', shapes = {}, set = {}, unset = {} }

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
            pos[1], pos[2] = physics:getWorldCenter()
        end
    end
end

imgs = { name = 'imgs' }

function imgs.load(world)
    world.imgs = weak_table()
end

function imgs.unload(world)
    world.imgs = nil
end

function imgs.get(world, src)
    return table.get(world.imgs, src, function()
        return love.graphics.newImage('img/' .. src)
    end)
end

sheets = { name = 'sheets', set = {} }

function sheets.load(world)
    world.sheets = weak_table()
end

function sheets.unload(world)
    world.sheets = nil
end

function sheets.set.sprite(world, entity)
    local sprite = entity.sprite
    local src = sprite.src
    sprite.entry = sprite.entry or 1
    sprite.strip = sprite.strip or 1
    sprite.tile = sprite.tile or 1
    sprite.sheet = table.get(world.sheets, src, function()
        local sheet = require('img/' .. src)
        sheet.src = src
        -- Process sheet entries to establish derived info and flags.
        for _, entry in ipairs(sheet) do
            local img = imgs.get(world, entry.src)
            local width, height = img:getDimensions()
            entry.frame_time = 1 / entry.fps
            entry.tiles_count = width / entry.size[1]
            entry.flags = entry.flags or {}
            entry.strips = {}
            -- Create the strips
            for y, flags in ipairs(entry.flags_y) do
                -- Create a strip
                local strip = { flags = flags, tiles = {} }
                table.push(entry.strips, strip)
                -- Create the entries
                for x = 1, entry.tiles_count do
                    local quad = love.graphics.newQuad(
                        (x - 1) * entry.size[1], (y - 1) * entry.size[2],
                        entry.size[1], entry.size[2],
                        width, height)
                    local tile = { quad = quad, scale = { 1, 1 }}
                    table.push(strip.tiles, tile)
                end
                -- Find the dir in the flags if it exists, and infer the flip dir.
                local dir = flags.dir
                local flip = dir and (2 + 1 - dir) % 2
                if flip and flip ~= dir then
                    local flip_flags = cpy(flags)
                    flip_flags.dir = flip
                    local flip_strip = { flags = flip_flags, tiles = {} }
                    table.push(entry.strips, flip_strip)
                    -- Copy the entries from the original strip
                    for x = 1, entry.tiles_count do
                        local tile = { quad = strip.tiles[x].quad, scale = { -1, 1 } }
                        table.push(flip_strip.tiles, tile)
                    end
                end
            end
            ::continue::
        end
        return sheet
    end)
end

function sheets.matching_flags(to_match, flags)
    for flag_type, value in pairs(to_match) do
        if flags[flag_type] ~= value then
            return false
        end
    end
    return true
end

function sheets.update(world, dt)
    for entity in world.by('sprite') do
        local sprite, animator = entity.sprite, entity.animator
        if animator then
            local sheet = sprite.sheet
            local entry_idx, strip_idx = 1, 1

            for i, entry in ipairs(sheet) do
                if sheets.matching_flags(entry.flags, animator.flags) then
                    entry_idx = i
                end
            end

            for i, strip in ipairs(sheet[entry_idx].strips) do
                if sheets.matching_flags(strip.flags, animator.flags) then
                    strip_idx = i
                end
            end

            if sprite.entry ~= entry_idx or sprite.strip ~= strip_idx then
                sprite.tile = 1
                animator.time = 0
            end
            sprite.entry = entry_idx
            sprite.strip = strip_idx
        end
    end
end

aabbs = { name = 'aabbs', set = {}, unset = {} }

function aabbs.load(world)
    world.sparse = sparse(4)
    world.by_aabb = world.sparse.region
end

function aabbs.unload(world)
    world.sparse = nil
    world.by_aabb = nil
end

function aabbs.for_pos_and_sprite(pos, sprite)
    local entry = sprite.sheet[sprite.entry]
    local min = vec2.sub(pos, entry.decal)
    local max = vec2.add(pos, entry.size)
    return min, max
end

function aabbs.set.sprite(world, entity)
    local pos, sprite = entity.pos, entity.sprite
    if pos and sprite and sprite.sheet then
        local min, max = aabbs.for_pos_and_sprite(pos, sprite)
        world.components.set(entity, 'aabb', { min = min, max = max })
    end
end

function aabbs.set.aabb(world, entity)
    world.sparse.insert(entity, entity.aabb)
end

function aabbs.unset.sprite(world, entity)
    world.components.unset(entity, 'aabb')
end

function aabbs.unset.aabb(world, entity)
    world.sparse.remove(entity.aabb)
end

aabbs.set.pos = aabbs.set.sprite
aabbs.unset.pos = aabbs.unset.sprite

function aabbs.update(world, dt)
    for entity in world.by('aabb') do
        local aabb, pos, sprite = entity.aabb, entity.pos, entity.sprite
        local min, max = aabbs.for_pos_and_sprite(pos, sprite)
        if not vec2.eq(min, max) then
            local new = { min = min, max = max }
            world.sparse.update(entity, new)
            entity.aabb = new
        end
    end
end

sprite_renderer = { name = 'sprite_renderer' }

function sprite_renderer.update(world, dt)
    for entity in world.by('animator') do
        local animator, sprite, sheet = entity.animator, entity.sprite, entity.sheet
        if sprite and sheet then
            local entry = sheet[sprite.entry]
            animator.time = (animator.time or 0) + dt
            while animator.time > entry.frame_time do
                animator.time = animator.time - entry.frame_time
                sprite.tile = (sprite.tile % entry.tiles_count) + 1
            end
        end
    end
end

function sprite_renderer.draw(world)
    local width, height = love.window.getMode()
    for entity in world.by_aabb({ min = { 0, 0 }, max = { width, height } }) do
        local pos, sprite = entity.pos, entity.sprite
        if sprite then
            local sheet = sprite.sheet
            local entry = sheet[sprite.entry]
            local strip = entry.strips[sprite.strip]
            local tile = strip.tiles[sprite.tile]
            love.graphics.draw(
                entry.img,
                tile.quad,
                pos[1], pos[2],
                0,
                tile.scale[1], tile.scale[2],
                entry.decal[1], entry.decal[2])
        end
    end
end

function world()
    local world = {
        systems = {
            filtered = {
                set = {},
                unset = {},
                root = {}
            }
        },

        entities = {},
        components = {},
    }

    function world.fn(key)
        world.systems.filtered.root[key] = {}
        world[key] = function(...)
            for _, system in ipairs(world.systems.filtered.root[key]) do
                system[key](world, ...)
            end
        end
    end

    world.fn('load')
    world.fn('unload')
    world.fn('keypressed')
    world.fn('keyreleased')
    world.fn('update')
    world.fn('draw')

    function world.systems.add(system)
        table.push(world.systems, system)
        for top_key, tbl in pairs(world.systems.filtered) do
            local is_root = top_key == 'root'
            local for_system = is_root and system or system[top_key]
            local for_world = world.systems.filtered[top_key]
            if for_system then
                for key, _ in pairs(is_root and for_world or for_system) do
                    if not for_world[key] then
                        for_world[key] = {}
                    end
                    if for_system[key] then
                        table.push(for_world[key], system)
                    end
                end
            end
        end
    end

    function world.entities.add(entity)
        table.push(world.entities, entity)
        for key, component in pairs(entity) do
            for _, system in ipairs(world.systems.filtered.set[key] or {}) do
                system.set[key](world, entity)
            end
        end
    end

    function world.entities.remove(entity)
        entity.to_remove = true
    end

    function world.components.set(entity, key, component)
        if entity[key] then
            world.components.unset(entity, key)
        end
        entity[key] = component
        for _, system in ipairs(world.systems.filtered.set[key] or {}) do
            system.set[key](world, entity)
        end
    end

    function world.components.unset(entity, key)
        for _, system in ipairs(world.systems.filtered.unset[key] or {}) do
            system.unset[key](world, entity)
        end
        entity[key] = nil
    end

    function world.flush()
        local empty = nil
        for i = 1, #world.entities do
            local entity = world.entities[i]
            if entity.to_remove then
                for key, component in pairs(entity) do
                    for system, fn in ipairs(world.systems.filtered.unset[key] or {}) do
                        system.unset[key](world, entity)
                    end
                end
                world.entities[i] = nil
                empty = empty or i
            elseif empty then
                world.entities[empty] = world.entities[i]
                world.entities[i] = nil
                empty = i
            end
        end
    end

    function world.by(key)
        local i, n = 1, #world.entities
        return function()
            while i <= n do
                local entity = world.entities[i]
                i = i + 1
                if entity[key] then
                    return entity
                end
            end
        end
    end

    return world
end
