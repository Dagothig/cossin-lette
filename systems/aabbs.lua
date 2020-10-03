local aabbs = { name = 'aabbs', set = {}, unset = {} }
local sparse = require('util/sparse')

function aabbs.load(world)
    world.sparse = sparse(64)
    world.by_aabb = world.sparse.region
end

function aabbs.unload(world)
    world.sparse = nil
    world.by_aabb = nil
end

function aabbs.for_pos_and_sprite(pos, sprite)
    local entry = sprite.sheet[sprite.entry]
    local min = vec2.sub(pos, entry.decal)
    local max = vec2.add(min, entry.size)
    return { min, max }
end

function aabbs.set.sprite(world, entity)
    local pos, sprite, aabb = entity.pos, entity.sprite, entity.aabb
    if pos and sprite and sprite.sheet and not aabb then
        world.components.set(entity, 'aabb', aabbs.for_pos_and_sprite(pos, sprite))
    end
end

function aabbs.set.aabb(world, entity)
    world.sparse.insert(entity)
end

function aabbs.unset.sprite(world, entity)
    world.components.unset(entity, 'aabb')
end

function aabbs.unset.aabb(world, entity)
    world.sparse.remove(entity)
    entity.sparse_pos = nil
end

aabbs.set.pos = aabbs.set.sprite
aabbs.unset.pos = aabbs.unset.sprite

function aabbs.update(world, dt)
    for entity in world.by('aabb') do
        if entity.sprite then
            entity.aabb = aabbs.for_pos_and_sprite(entity.pos, entity.sprite)
            world.sparse.update(entity)
        end
    end
end

return aabbs
