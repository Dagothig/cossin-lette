local renderer = { name = 'renderer', set = {}, unset = {} }

function renderer.load(world)
    world.fn('draw_camera')
end

function renderer.unload(world)
    world.unfn('draw_camera')
end

function renderer.set.camera(world, entity)
    if not world.camera_target then
        world.camera_target = entity
    end
end

function renderer.unset.camera(world, entity)
    if world.camera_target == entity then
        for other in world.by('camera') do
            world.camera_target = other
            return
        end
        world.camera_target = nil
    end
end

function renderer.draw(world)
    for entity in world.by('camera') do
        local camera = entity.camera
        local pos = entity.pos or { 0, 0 }
        local scale = entity.scale or { value = 1 }

        love.graphics.push()

        local w, h = love.window.getMode()
        love.graphics.translate(
            math.floor(w / 2 - pos[1]),
            math.floor(h / 2 - pos[2]))
        love.graphics.scale(scale.value)

        local to_render = iter.table(world.by_aabb{
            { love.graphics.inverseTransformPoint(0, 0) },
            { love.graphics.inverseTransformPoint(w, h) }
        })
        table.sort(to_render, function(lhs, rhs)
            return lhs.pos[2] < rhs.pos[2]
        end)

        world.draw_camera(camera, to_render)

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
                love.graphics.setColor(1, 1, 1)
            end
        end

        love.graphics.pop()
    end
end

return renderer
