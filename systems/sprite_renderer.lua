local sprite_renderer = {}

function matching_flags(to_match, flags)
    for flag_type, value in pairs(to_match) do
        if flags[flag_type] ~= value then
            return false
        end
    end
    return true
end

function find_entry(animator, sheet, sprite)
    local entry_idx, strip_idx = 1, 1

    for i, entry in ipairs(sheet) do
        if matching_flags(entry.flags, animator.flags) then
            entry_idx = i
        end
    end

    for i, strip in ipairs(sheet[entry_idx].strips) do
        if matching_flags(strip.flags, animator.flags) then
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

function sprite_renderer.load(components)
    for _, sheet in pairs(components.sheets) do
        for _, entry in ipairs(sheet) do
            if entry.img then
                goto continue
            end
            entry.img = love.graphics.newImage('img/' .. entry.src)
            local width, height = entry.img:getDimensions()
            entry.frame_time = 1 / entry.fps
            entry.tiles_count = width / entry.size[1]
            entry.flags = entry.flags or {}
            entry.strips = {}
            -- Create the strips
            for y, flags in ipairs(entry.flags_y) do
                -- Create a strip
                local strip = { flags = flags, tiles = {} }
                push(entry.strips, strip)
                -- Create the entries
                for x = 1, entry.tiles_count do
                    local quad = love.graphics.newQuad(
                        (x - 1) * entry.size[1], (y - 1) * entry.size[2],
                        entry.size[1], entry.size[2], 
                        width, height)
                    push(strip.tiles, {
                        quad = quad,
                        scale = { 1, 1 }
                    })
                end
                -- Find the dir in the flags if it exists, and infer the flip dir.
                local dir = flags.dir
                local flip = dir and (2 + 1 - dir) % 2
                if flip and flip ~= dir then
                    local flip_flags = cpy(flags)
                    flip_flags.dir = flip
                    local flip_strip = { flags = flip_flags, tiles = {} }
                    push(entry.strips, flip_strip)
                    -- Copy the entries from the original strip
                    for x = 1, entry.tiles_count do
                        push(flip_strip.tiles, { 
                            quad = strip.tiles[x].quad,
                            scale = { -1, 1 }
                        })
                    end
                end
            end
            ::continue::
        end
    end
end

function sprite_sort(a, b)
    return a.pos[2] < b.pos[2]
end

function sprite_renderer.draw(components)
    -- TODO this is sad
    for sprite in pairsByKeys(components.sprites, sprite_sort) do
        local sheet = components.sheets[sprite.entity]
        local entry = sheet[sprite.entry]
        local strip = entry.strips[sprite.strip]
        local tile = strip.tiles[sprite.tile]
        love.graphics.draw(
            entry.img,
            tile.quad,
            sprite.pos[1], sprite.pos[2],
            0, 
            tile.scale[1], tile.scale[2],
            entry.decal[1], entry.decal[2])
    end
end

function sprite_renderer.update(components, dt)
    for entity, animator in pairs(components.animators) do
        -- Establish entry and strip
        local sprite = components.sprites[entity]
        local sheet = components.sheets[entity]
        find_entry(animator, sheet, sprite)
        local entry = sheet[sprite.entry]
        -- Increment tile animation
        if entry.frame_time then
            animator.time = (animator.time or 0) + dt
            while animator.time > entry.frame_time do
                animator.time = animator.time - entry.frame_time
                sprite.tile = (sprite.tile % entry.tiles_count) + 1
            end
        end
    end
end

return sprite_renderer
