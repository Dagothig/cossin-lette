return function()
    local storage = {}

    function storage.get(entity)
        return storage[entity]
    end

    function storage.set(entity, component)
        storage[entity] = component
    end

    function storage.clear(entity, component)
        storage[entity] = nil
    end

    return storage
end
