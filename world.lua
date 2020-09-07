return function()
    local world = {
        systems = {
            filtered = {
                set = {},
                unset = {},
                root = {}
            }
        },

        entities = {},
        components = {},
    }

    function world.fn(key)
        world.systems.filtered.root[key] = {}
        world[key] = function(...)
            for _, system in ipairs(world.systems.filtered.root[key]) do
                system[key](world, ...)
            end
        end
    end

    world.fn('load')
    world.fn('unload')
    world.fn('keypressed')
    world.fn('keyreleased')
    world.fn('update')
    world.fn('draw')

    function world.systems.add(system)
        table.push(world.systems, system)
        for top_key, tbl in pairs(world.systems.filtered) do
            local is_root = top_key == 'root'
            local for_system = is_root and system or system[top_key]
            local for_world = world.systems.filtered[top_key]
            if for_system then
                for key, _ in pairs(is_root and for_world or for_system) do
                    if not for_world[key] then
                        for_world[key] = {}
                    end
                    if for_system[key] then
                        table.push(for_world[key], system)
                    end
                end
            end
        end
    end

    function world.entities.add(entity)
        table.push(world.entities, entity)
        for key, component in pairs(entity) do
            for _, system in ipairs(world.systems.filtered.set[key] or {}) do
                system.set[key](world, entity)
            end
        end
    end

    function world.entities.remove(entity)
        entity.to_remove = true
    end

    function world.components.set(entity, key, component)
        if entity[key] then
            world.components.unset(entity, key)
        end
        entity[key] = component
        for _, system in ipairs(world.systems.filtered.set[key] or {}) do
            system.set[key](world, entity)
        end
    end

    function world.components.unset(entity, key)
        for _, system in ipairs(world.systems.filtered.unset[key] or {}) do
            system.unset[key](world, entity)
        end
        entity[key] = nil
    end

    function world.flush()
        local empty = nil
        for i = 1, #world.entities do
            local entity = world.entities[i]
            if entity.to_remove then
                for key, component in pairs(entity) do
                    for system, fn in ipairs(world.systems.filtered.unset[key] or {}) do
                        system.unset[key](world, entity)
                    end
                end
                world.entities[i] = nil
                empty = empty or i
            elseif empty then
                world.entities[empty] = world.entities[i]
                world.entities[i] = nil
                empty = i
            end
        end
    end

    function world.by(key)
        local i, n = 1, #world.entities
        return function()
            while i <= n do
                local entity = world.entities[i]
                i = i + 1
                if entity[key] then
                    return entity
                end
            end
        end
    end

    return world
end
