return function()
    local world = {
        systems = {
            filtered = {
                set = {},
                unset = {},
                events = {},
                root = { event = {} }
            }
        },

        entities = {},
        components = {},
        events = {},
        get = {},
        prefabs = {}
    }

    function world.fn(key, fn)
        world.systems.filtered.root[key] = {}
        world[key] = function(...)
            for _, system in ipairs(world.systems.filtered.root[key]) do
                system[key](world, ...)
            end
        end
        for _, system in ipairs(world.systems) do
            if system[key] then
                table.push(world.systems.filtered.root[key], system)
            end
        end
    end

    function world.unfn(key)
        world.systems.filtered.root[key] = nil
        world[key] = nil
    end

    world.fn('load')
    world.fn('unload')
    world.fn('keypressed')
    world.fn('keyreleased')
    world.fn('update')
    world.fn('draw')

    function world.systems.add(systems)
        for _, system in ipairs(systems) do
            if type(system) == 'string' then
                system = require('systems/' .. system)
            end
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
    end

    function world.entities.add(entity)
        local added = {}
        table.push(world.entities, added)
        for key, component in pairs(entity) do
            world.components.set(added, key, component)
        end
        return added
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
                    for _, system in ipairs(world.systems.filtered.unset[key] or {}) do
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

    function world.by(...)
        local keys = { ... }
        local i, n = 1, #world.entities
        return function()
            ::continue::
            while i <= n do
                local entity = world.entities[i]
                i = i + 1
                for _, key in ipairs(keys) do
                    if not entity[key] then
                        goto continue
                    end
                end
                return entity
            end
        end
    end

    function world.prefabs.apply(prefab, entity)
        for key, value in pairs(prefab) do
            if type(value) == 'table' then
                if not entity[key] then
                    entity[key] = {}
                end
                world.prefabs.apply(value, entity[key])
            else
                entity[key] = value
            end
        end
    end

    function world.events.trigger(type, entity, source, ...)
        for _, system in ipairs(world.systems.filtered.root.event) do
            system.event(world, type, entity, source, ...)
        end
        for _, system in ipairs(world.systems.filtered.events[type] or {}) do
            system.events[type](world, entity, source, ...)
        end
    end

    return world
end
