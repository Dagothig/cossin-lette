local sprite_renderer = { name = 'sprite_renderer' }

function sprite_renderer.update(world, dt)
    for entity in world.by('animator') do
        local animator, sprite = entity.animator, entity.sprite
        if sprite and sprite.sheet then
            local entry = sprite.sheet[sprite.entry]
            animator.time = (animator.time or 0) + dt
            while animator.time > entry.frame_time do
                animator.time = animator.time - entry.frame_time
                sprite.tile = (sprite.tile % entry.tiles_count) + 1
            end
        end
    end
end

function sprite_renderer.draw(world)
    local w, h = love.window.getMode()
    local to_render = iter.table(world.by_aabb({ { 0, 0 }, { w, h } }))
    table.sort(to_render, function(lhs, rhs)
        return lhs.pos[2] < rhs.pos[2]
    end)
    for _, entity in ipairs(to_render) do
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

return sprite_renderer
