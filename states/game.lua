local world = require('world')

return function()
    local game = { world = world() }

    function game.on_start(payload, done)
        game.world = world()
        game.world.systems.add(
            'input_handler',
            'actor',
            'physics',
            'imgs',
            'sheets',
            'tilesets',
            'aabbs',
            'renderer',
            'ui')

        game.world.load()

        game.world.entities.add{
            name = 'cossin',
            pos = { 160, 160 },
            sprite = { src = 'cossin' },
            animator = {},
            actor = { speed = 240 },
            body = { shape = { type = 'circle', size = 20 } },
            keys = {
                up = { type = "y", value = 1 },
                left = { type = "x", value = -1 },
                right = { type = "x", value = 1 },
                down = { type = "y", value = -1 },
                space = { type = "interaction", value = true }
            },
            input = {},
            camera = { draw_aabb = true }
        }

        for i = 1, 1000 do
            game.world.entities.add{
                name = 'autrecossin',
                pos = { math.random(0, 3000), math.random(0, 3000) },
                sprite = { src = 'cossin' },
                body = { shape = { type = 'circle', size = 20 } },
                actor = {}
            }
        end

        game.world.entities.add{
            name = 'tiles',
            pos = { 160, 160 },
            tiles = {
                src = 'forest',
                {
                    { { { 6, 1, 1 } }, { { 6, 2, 1 } }, { { 6, 3, 1 } } },
                    { { { 6, 1, 2 } }, { { 6, 2, 2 } }, { { 6, 3, 2 } } },
                    { { { 6, 1, 3 } }, { { 6, 2, 3 } }, { { 6, 3, 3 } } }
                }, {
                    {},
                    {},
                    { { { 3, 1, 1 } } }
                }, {
                    {},
                    { { { 3, 1, 1 } } }
                }, {
                    { { { 3, 1, 1 } } }
                }
            }
        }

        game.world.entities.add{
            name = 'test',
            pos = { 250, 30 },
            size = { 240, 120 },
            ui = { src = 'ui/pane' },
            text = { value = "Woo! This is text to be displayed... And \nchanges lines." }
        }
    end

    function game.keypressed(key)
        game.world.keypressed(key)
    end

    function game.keyreleased(key)
        game.world.keyreleased(key)
    end

    function game.update(dt)
        game.world.update(dt)
        game.world.flush()
    end

    function game.draw()
        game.world.draw()
    end

    return game
end
