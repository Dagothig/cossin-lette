local weak_table = require('util/weak_table')

local imgs = { name = 'imgs' }

function imgs.load(world)
    world.imgs = weak_table()
    function world.get.img(src)
        return table.get(world.imgs, src, function()
            return love.graphics.newImage('img/' .. src)
        end)
    end
end

function imgs.unload(world)
    world.imgs = nil
    world.get.img = nil
end

return imgs
