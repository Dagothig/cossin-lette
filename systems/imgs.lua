local weak_table = require('util/weak_table')

local imgs = { name = 'imgs' }

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

return imgs
