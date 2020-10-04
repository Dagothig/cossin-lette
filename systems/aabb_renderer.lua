local aabb_renderer = { name = 'aabb_renderer' }

function aabb_renderer.draw_camera(world, entity, x, y, w, h)
    for entity in world.by_aabb{
        { love.graphics.inverseTransformPoint(x, y) },
        { love.graphics.inverseTransformPoint(x + w, y + h) }
    } do
        local aabb = entity.aabb
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(1)
        love.graphics.line(
            aabb[1][1], aabb[1][2],
            aabb[1][1], aabb[2][2],
            aabb[2][1], aabb[2][2],
            aabb[2][1], aabb[1][2],
            aabb[1][1], aabb[1][2])
    end
end

return aabb_renderer
