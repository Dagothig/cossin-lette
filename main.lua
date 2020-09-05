require('global')
require('world')

cur = world()

function love.load()
    cur.systems.add(input_handler)
    cur.systems.add(actor)
    cur.systems.add(physics)
    cur.systems.add(imgs)
    cur.systems.add(sheets)
    cur.systems.add(aabbs)
    cur.systems.add(sprite_renderer)

    cur.load()

    cur.entities.add({
        name = 'cossin',
        pos = { 160, 160 },
        sprite = { src = 'cossin' },
        animator = {},
        actor = { speed = 0 },
        body = { shape = { type = 'circle', size = 20 } },
        keys = {
            up = { type = "y", value = 1 },
            left = { type = "x", value = -1 },
            right = { type = "x", value = 1 },
            down = { type = "y", value = -1 }
        },
        input = {}
    })
end

function love.keypressed(key)
    cur.keypressed(key)
end

function love.keyreleased(key)
    cur.keyreleased(key)
end

function love.update(dt)
    cur.update(dt)
    cur.flush()
end

function love.draw()
    cur.draw()
end
