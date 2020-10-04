local ui = { name = 'ui', set = {} }
local weak_table = require('util/weak_table')

function ui.load(world)
    world.panes = weak_table()
end

function ui.unload(world)
    world.panes = nil
end

function ui.set.ui(world, entity)
    local ui = entity.ui
    ui.pane = table.get(world.panes, ui.src, function()
        local pane = { src = ui.src }
        pane.img = world.get.img(pane.src .. '.png')
        local width, height = pane.img:getDimensions()
        local tw, th = width / 3, height / 3

        pane.tw = tw
        pane.th = th
        pane.quads = {
            tl = love.graphics.newQuad(0, 0, tw, th, width, height),
            ts = love.graphics.newQuad(tw, 0, tw, th, width, height),
            tr = love.graphics.newQuad(tw * 2, 0, tw, th, width, height),
            ls = love.graphics.newQuad(0, th, tw, th, width, height),
            ce = love.graphics.newQuad(tw, th, tw, th, width, height),
            rs = love.graphics.newQuad(tw * 2, th, tw, th, width, height),
            bl = love.graphics.newQuad(0, th * 2, tw, th, width, height),
            bs = love.graphics.newQuad(tw, th * 2, tw, th, width, height),
            br = love.graphics.newQuad(tw * 2, th * 2, tw, th, width, height),
        }

        return pane
    end)

    if ui.decorations then
        for i = 1, #ui.decorations  do
            local decoration = ui.decorations[i]
            decoration.img = world.get.img(decoration.src .. '.png')
            decoration.size = { decoration.img:getDimensions() }
        end
    end
end

function ui.anchor_position(type, ps, pe, size)
    if type == 'start' then
        return ps, size
    elseif type == 'end' then
        return pe, 0
    elseif type == 'center' then
        return (ps + pe) / 2, size/2
    else
        return 0, 0
    end
end

function ui.draw_camera(world)
    love.graphics.setColor(1, 1, 1)
    for entity in world.by('ui') do
        local pos, size = entity.pos, entity.size
        if pos and size then
            local pane, decorations = entity.ui.pane, entity.ui.decorations
            local x1, y1 = pos[1], pos[2]
            local x2, y2 = x1 + pane.tw, y1 + pane.th
            local dx, dy = size[1] - 2 * pane.tw, size[2] - 2 * pane.th
            local x3, y3 = x2 + dx, y2 + dy
            dx = dx / pane.tw
            dy = dy / pane.th
            love.graphics.draw(pane.img, pane.quads.tl, x1, y1, 0, 1, 1)
            love.graphics.draw(pane.img, pane.quads.ts, x2, y1, 0, dx, 1)
            love.graphics.draw(pane.img, pane.quads.tr, x3, y1, 0, 1, 1)
            love.graphics.draw(pane.img, pane.quads.ls, x1, y2, 0, 1, dy)
            love.graphics.draw(pane.img, pane.quads.ce, x2, y2, 0, dx, dy)
            love.graphics.draw(pane.img, pane.quads.rs, x3, y2, 0, 1, dy)
            love.graphics.draw(pane.img, pane.quads.bl, x1, y3, 0, 1, 1)
            love.graphics.draw(pane.img, pane.quads.bs, x2, y3, 0, dx, 1)
            love.graphics.draw(pane.img, pane.quads.br, x3, y3, 0, 1, 1)

            if decorations then
                for i = 1, #decorations do
                    local decoration = decorations[i]
                    local x, ox = ui.anchor_position(decoration.anchor[1], x2, x3, decoration.size[1])
                    local y, oy = ui.anchor_position(decoration.anchor[2], y2, y3, decoration.size[2])
                    love.graphics.draw(
                        decoration.img,
                        x, y,
                        0,
                        1, 1,
                        ox, oy)
                end
            end
        end
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(font)
    for entity in world.by('text', 'pos') do
        local text, ui, pos, size = entity.text, entity.ui, entity.pos, entity.size
        local x, y = pos[1], pos[2]

        if size then
            local tw, th = ui and ui.pane.tw or 0, ui and ui.pane.th or 0
            if ui then
                x = x + tw * 2
                y = y + th * 2
            end
            love.graphics.printf(text.value, x, y, size[1] - tw * 4)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(text.value, x - 1000, y, 2000, 'center')
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function ui.say(world, entity, text)

end

return ui
