require('global')

love.window.setTitle("Cossin Lette")

local game = require('states/game')

local states = {}
local current

function states.push(state, payload)
    if current and current.on_pause then
        current.on_pause(state)
    end
    states[#states + 1] = state
    current = state
    if state.on_start then
        state.on_start(payload)
    end
end

function states.pop(payload)
    if current.on_end then
        current.on_end()
    end
    states[#states] = nil
    current = states[#states]
    if current and current.on_resume then
        current.on_resume(payload)
    end
end

function love.load()
    states.push(game())
end

function love.keypressed(key)
    if current and current.keypressed then
        current.keypressed(key)
    end
end

function love.keyreleased(key)
    if current and current.keyreleased then
        current.keyreleased(key)
    end
end

function love.update(dt)
    if current and current.update then
        current.update(dt)
    end
end

function love.draw()
    if current and current.draw then
        current.draw()
    end
end
