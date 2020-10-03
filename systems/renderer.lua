local renderer = { name = 'renderer' }

function renderer.load(world)
    world.fn('draw_camera')
end

function renderer.unload(world)
    world.unfn('draw_camera')
end

function renderer.draw(world)
    local width, height = love.window.getMode()
    local with_cameras = iter.table(world.by('camera'))
    local cols = math.ceil(math.sqrt(#with_cameras))
    local batches = table.batch(with_cameras, cols)
    local split_height = height / #batches
    local split_height_low = math.floor(split_height)
    local split_height_high = math.ceil(split_height)

    for j, batch in ipairs(batches) do
        local camera_height = j == #batches and split_height_high or split_height_low
        local split_width = width / #batch
        local split_width_low = math.floor(split_width)
        local split_width_high = math.ceil(split_width)
        for i, entity in ipairs(batch) do
            local camera_width = i == #batch and split_width_high or split_width_low
            local x, y = (i - 1) * camera_width, (j - 1) * camera_height
            local pos = entity.pos or { 0, 0 }

            love.graphics.push()

            love.graphics.setScissor(x, y, camera_width, camera_height)
            love.graphics.translate(
                camera_width / 2 - pos[1] + x,
                camera_height / 2 - pos[2] + y)

            world.draw_camera(entity, x, y, camera_width, camera_height)

            love.graphics.pop()
        end
    end

    love.graphics.setScissor()
end

function renderer.draw_camera(world, entity, x, y, w, h)
    local camera = entity.camera
    local to_render = iter.table(world.by_aabb{
        { love.graphics.inverseTransformPoint(x, y) },
        { love.graphics.inverseTransformPoint(x + w, y + h) }
    })
    table.sort(to_render, function(lhs, rhs)
        return lhs.pos[2] < rhs.pos[2]
    end)

    love.graphics.setColor(1, 1, 1)

    for _, entity in ipairs(to_render) do
        local pos, sprite, tile = entity.pos, entity.sprite, entity.tile
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

        if tile then
            local parent, tlist, decal = tile[1], tile[2], tile[3]
            local tileset = parent.tiles.tileset
            for _, t in ipairs(tlist) do
                local te, tx, ty = t[1], t[2], t[3]
                local entry = tileset[te]
                if entry.frame_ty then
                    ty = entry.frame_ty[ty]
                end
                love.graphics.draw(
                    entry.img,
                    entry.tiles[tx][ty].quad,
                    pos[1], pos[2],
                    0,
                    1, 1,
                    decal[1], decal[2])
            end
        end

        if camera.draw_aabb then
            local aabb = entity.aabb
            love.graphics.setColor(1, 0, 0)
            love.graphics.line(
                aabb[1][1], aabb[1][2],
                aabb[1][1], aabb[2][2],
                aabb[2][1], aabb[2][2],
                aabb[2][1], aabb[1][2],
                aabb[1][1], aabb[1][2])
        end
    end
end

return renderer
