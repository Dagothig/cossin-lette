local weak_table = require('util/weak_table')

local sheets = { name = 'sheets', set = {} }

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
        local sheet = require('img/' .. src .. '/sheet')
        sheet.src = src
        -- Process sheet entries to establish derived info and flags.
        for _, entry in ipairs(sheet) do
            entry.img = world.get.img(src .. '/' .. entry.src)
            local width, height = entry.img:getDimensions()
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
                        (x - 1) * entry.size[1],
                        (y - 1) * entry.size[2],
                        entry.size[1],
                        entry.size[2],
                        width,
                        height)
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

function sheets.set.animator(world, entity)
    entity.animator.flags = entity.animator.flags or {}
    entity.animator.time = entity.animator.time or 0
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
                sprite.entry = entry_idx
                sprite.strip = strip_idx
            else
                local entry = sheet[sprite.entry]
                animator.time = animator.time + dt
                while animator.time > entry.frame_time do
                    animator.time = animator.time - entry.frame_time
                    sprite.tile = (sprite.tile % entry.tiles_count) + 1
                end
            end
        end
    end
end

return sheets
