local weak_table = require('util/weak_table')

local tilesets = { name = 'sheets', set = {}, unset = {} }

function tilesets.load(world)
    world.tilesets = weak_table()
end

function tilesets.unload(world)
    world.tilesets = nil
end

function tilesets.set.tiles(world, entity)
    local tiles = entity.tiles
    local src = tiles.src
    tiles.tileset = table.get(world.tilesets, src, function()
        local tileset = require('img/' .. src .. '/tileset')
        local tw, th = tileset.size[1], tileset.size[2]
        tileset.src = src
        for _, entry in ipairs(tileset) do
            entry.img = world.get.img(src .. '/' .. entry.src)
            local width, height = entry.img:getDimensions()
            if entry.fps then
                entry.frame_time = 1 / entry.fps
                entry.frame_ty = {}
            end
            entry.size = entry.size or { 1, 1 }
            entry.tiles = {}
            for x = 1, width / tw do
                entry.tiles[x] = {}
                for y = 1, height / th do
                    entry.tiles[x][y] = {
                        quad = love.graphics.newQuad(
                            (x - 1) * tw,
                            (y - 1) * th,
                            tw,
                            th,
                            width,
                            height)
                    }
                    if entry.frame_ty then
                        entry.frame_ty[y] = y
                    end
                end
            end
        end
        return tileset
    end)
end

systems.set.all(tilesets, { 'tiles', 'pos' }, function(world, entity)
    local tiles, pos = entity.tiles, entity.pos

    tiles.entities = {}

    for z = 1, #tiles do
        for y = 1, #tiles[z] do
            for x = 1, #tiles[z][y] do
                local tpos = vec2.add(pos, {
                    (x - 1) * tiles.tileset.size[1],
                    (y - 1) * tiles.tileset.size[2]
                })
                local decal = vec2.mul(tiles.tileset.size, 0.5)
                local aabb_min = vec2.sub(tpos, decal)
                local aabb_max = vec2.add(aabb_min, tiles.tileset.size)
                if z == 1 then
                    decal[2] = decal[2] - tpos[2]
                    tpos[2] = 0
                else
                    local offset = (z - 2) * tiles.tileset.size[2]
                    tpos[2] = tpos[2] + offset
                    decal[2] = decal[2] + offset
                end
                tiles.entities[#tiles.entities + 1] =
                    world.entities.add{
                        pos = tpos,
                        aabb = { aabb_min, aabb_max },
                        tile = { entity, tiles[z][y][x], decal }
                    }
            end
        end
    end
end)

systems.unset.all(tilesets, { 'tiles', 'pos' }, function(world, entity)
    local tiles = entity.tiles
    for i = 1, #tiles.entities do
        world.entities.remove(tiles.entities[i])
    end
end)

function tilesets.update(world, dt)
    for _, tileset in pairs(world.tilesets) do
        for _, entry in ipairs(tileset) do
            if entry.frame_time then
                entry.time = (entry.time or 0) + dt
                while entry.time > entry.frame_time do
                    entry.time = entry.time - entry.frame_time
                    for y, ty in ipairs(entry.frame_ty) do
                        entry.frame_ty[y] = (ty + entry.size[2] - 1) % #entry.frame_ty + 1
                    end
                end
            end
        end
    end
end

return tilesets
