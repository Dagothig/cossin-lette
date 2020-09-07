require('global')

local world = require('world')
local input_handler = require('systems/input_handler')
local actor = require('systems/actor')
local physics = require('systems/physics')
local imgs = require('systems/imgs')
local sheets = require('systems/sheets')
local aabbs = require('systems/aabbs')
local sprite_renderer = require('systems/sprite_renderer')

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
        actor = { speed = 3 },
        body = { shape = { type = 'circle', size = 20 } },
        keys = {
            up = { type = "y", value = 1 },
            left = { type = "x", value = -1 },
            right = { type = "x", value = 1 },
            down = { type = "y", value = -1 }
        },
        input = {}
    })

    for i = 1, 1000 do
        cur.entities.add({
            name = 'cossin2',
            pos = { math.random(0, 3000), math.random(0, 3000) },
            sprite = { src = 'cossin' },
            body = { shape = { type = 'circle', size = 20 } },
        })
    end

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
