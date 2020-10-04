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
            'ui',
            'physics_renderer')

        game.world.load()

        local cossin = game.world.entities.add{
            name = 'cossin',
            pos = { 160, 160 },
            sprite = { src = 'cossin' },
            animator = {},
            actor = { speed = 240 },
            body = {
                shape = { type = 'circle', radius = 20 }
            },
            keys = {
                up = { type = "y", value = 1 },
                left = { type = "x", value = -1 },
                right = { type = "x", value = 1 },
                down = { type = "y", value = -1 },
                space = { type = "interaction" }
            },
            input = {},
            camera = {}
        }

        game.world.entities.add{
            name = 'cossin_interaction',
            body = { shape = { type = 'circle', radius = 40 }, sensor = 'interaction' },
            attach = { target = cossin, offset = { 20, 0 } }
        }

        local autrecossin = game.world.entities.add{
            name = 'autrecossin',
            pos = { 120, 120 },
            sprite = { src = 'cossin' },
            animator = {},
            actor = { speed = 240 },
            body = { shape = { type = 'circle', radius = 20 } },
            script = {
                interaction = function(world, entity, other)
                    print(entity.name, other.name)
                end,
                sensor_exit = function(world, entity, sensor, other)
                    print(entity.name, other.name)
                end
            }
        }

        game.world.entities.add{
            name = 'autrecossin_range',
            body = {
                shape = { type = 'circle', radius = 80 },
                sensor = true
            },
            attach = { target = autrecossin }
        }

        game.world.entities.add{
            name = 'test',
            size = { 240, 120 },
            ui = { src = 'ui/pane' },
            attach = { target = autre, offset = { 0, 20 } },
            text = { value = "Woo! This is text to be displayed... And \nchanges lines." }
        }

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
