local prefabs = { name = 'prefabs' }

function prefabs.load(world)
    world.prefabs = weak_table()
end
