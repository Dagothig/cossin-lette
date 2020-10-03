local world = require('world')

return function()
    local game = { world = world() }

    function game.on_start(payload, done)
        game.world = world()
        game.world.systems.add(
            'events',
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
                shape = { type = 'circle', size = 20 }
            },
            keys = {
                up = { type = "y", value = 1 },
                left = { type = "x", value = -1 },
                right = { type = "x", value = 1 },
                down = { type = "y", value = -1 },
                space = { type = "interaction", value = 1 }
            },
            input = {},
            camera = {}
        }

        local cossinInteraction = game.world.entities.add{
            name = 'interaction',
            body = {
                shape = { type = 'circle', size = 40 },
                sensor = { target = cossin, offset = { 10, 0 } }
            }
        }

        local autre = game.world.entities.add{
            name = 'autrecossin',
            pos = { 120, 120 },
            sprite = { src = 'cossin' },
            animator = {},
            actor = { speed = 240 },
            body = { shape = { type = 'circle', size = 20 } },
            script = {
                interaction = function(world, entity, other)
                    print('interaction', other.name)
                end,
                exit = function(world, entity, other)
                    print('exit', other.name)
                end
            }
        }

        local autreSensor = game.world.entities.add{
            name = 'autrecossin_range',
            body = {
                shape = { type = 'circle', size = 80 },
                sensor = { target = autre }
            }
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
