local world = require('world')
local actor = require('systems/actor')

return function()
    local game = { world = world() }

    function game.on_start(payload, done)
        game.world = world()
        game.world.systems.add{
            'input_handler',
            'actor',
            'physics',
            'imgs',
            'sheets',
            'tilesets',
            'aabbs',
            'renderer',
            'ui'
            --'physics_renderer'
            --'aabb_renderer'
        }

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
            actor = {
                speed = 240,
                speech = 'bubble',
                {
                    vars = { barnak = true },
                    interaction = {
                        { 'look_at', 'entity', 'source' },
                        { 'say', 'entity', "Hey!" },
                        { 'look_at', 'entity' }
                    }
                },
                {
                    interaction = {
                        { 'look_at', 'entity', 'source' },
                        { 'say', 'entity', "Salut Cossin! Est-ce que tu as vu Georges? Il est pas trop beau", { timeout_type = 'unresponsive' } },
                        { 'look_at', 'entity' },
                        { 'var', 'barnak', true },
                        { 'move_to', 'entity', { 80, 80 } },
                        { 'wait', 1 },
                        { 'say', 'entity', "Entéka... BARNAK" }
                    },
                    failure = {
                        { 'say', 'entity', "Woh!" },
                        { 'say', 'entity', "M'a m'en rappeler!" }
                    },
                    unresponsive = {
                        { 'say', 'entity', "Heille tu m'écoutes tu?" }
                    },
                    sensor_exit = {
                        { 'say', 'entity', "Oh heille, pars pas! J'ai des choses très importantes à te dire!" }
                    }
                }
            },
            move_target = { pos = { 120, 120 } },
            body = { shape = { type = 'circle', radius = 20 } }
        }

        game.world.entities.add{
            name = 'autrecossin_range',
            body = {
                shape = { type = 'circle', radius = 80 },
                sensor = true
            },
            attach = { target = autrecossin }
        }

        game.world.prefabs.bubble = {
            name = 'bubble',
            size = { 200, 100 },
            ui = {
                src = 'ui/bubble',
                decorations = {
                    { anchor = { 'center', 'end' }, src = 'ui/guedille' }
                }
            },
            attach = {
                offset = { -100, -200 },
            },
            text = {}
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
