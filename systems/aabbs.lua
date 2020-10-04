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

systems.set.all(aabbs, { 'pos', 'sprite' }, function(world, entity)
    local pos, sprite, aabb = entity.pos, entity.sprite, entity.aabb
    world.components.set(entity, 'aabb', aabbs.for_pos_and_sprite(pos, sprite))
end)

systems.unset.all(aabbs, { 'pos', 'sprite' }, function(world, entity)
    world.components.unset(entity, 'aabb')
end)

function aabbs.set.attach(world, entity)
    local attach = entity.attach
    if attach.target.pos then
        world.components.set(entity, 'pos', vec2.add(attach.target.pos, attach.offset or { 0, 0 }))
    end
end

function aabbs.set.aabb(world, entity)
    world.sparse.insert(entity)
end

function aabbs.unset.aabb(world, entity)
    world.sparse.remove(entity)
    entity.sparse_pos = nil
end

function aabbs.update(world, dt)
    for entity in world.by('aabb') do
        if entity.sprite then
            entity.aabb = aabbs.for_pos_and_sprite(entity.pos, entity.sprite)
            world.sparse.update(entity)
        end
    end

    for entity in world.by('attach') do
        local attach = entity.attach
        if attach.target.pos then
            entity.pos = vec2.add(attach.target.pos, attach.offset or { 0, 0 })
        end
    end
end

return aabbs
