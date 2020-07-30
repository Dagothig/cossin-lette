require('global')

components = {}
initializers = {}
systems = {}

function register_components(...)
    for _, name in ipairs({...}) do
        local status, fn = pcall(require, 'components/' .. name)
        if status then
            set, initializer = fn()
        else
            set = {}
            initializer = function(entity, component)
                set[entity] = component
                return component
            end
        end
        initializers[name] = initializer
        components[name] = set
    end
end

function register_systems(...)
    for _, name in ipairs({...}) do
        local system = require('systems/' .. name)
        push(systems, system)
    end
end

function call_systems(key, ...)
    for _, system in ipairs(systems) do
        if system[key] then
            system[key](components, ...)
        end
    end
end

function love.load()
    register_components(
        'sheets',
        'sprites',
        'animators',
        'inputs',
        'actors',
        'bodies')
    register_systems(
        'input_handler',
        'actor',
        'physics',
        'sprite_renderer')

    cossin = 0
    components.sheets[cossin] = require('img/cossin')
    components.sprites[cossin] = { entity = cossin, pos = { 160, 160 }, entry = 1, strip = 1, tile = 1 }
    components.animators[cossin] = { flags = {} }
    components.actors[cossin] = { input = { x = 0, y = 0 }, state = {}, dir = 0, speed = 4 }
    components.inputs[cossin] = {
        keys = {
            up = { type = "y", value = 1 },
            left = { type = "x", value = -1 },
            right = { type = "x", value = 1 },
            down = { type = "y", value = -1 }
        }
    }
    components.bodies[cossin] = { pos = { 160, 160 }, shape = { type = 'circle', size = 20 } }

    baba = 1
    components.sheets[baba] = require('img/cossin')
    components.sprites[baba] = { entity = baba, pos = { 300, 180 }, entry = 1, strip = 3, tile = 2 }
    components.animators[baba] = { flags = { dir = 0.25 } }
    components.bodies[baba] = { pos = { 300, 180 }, shape = { type = 'circle', size = 20 } }
    
    call_systems('load')
end

function love.keypressed(key)
    call_systems('keypressed', key)
end

function love.keyreleased(key)
    call_systems('keyreleased', key)
end

function love.update(dt)
    call_systems('update', dt)
end

function love.draw()
    call_systems('draw')
end
