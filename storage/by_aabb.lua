local sparse = require('../util/sparse')
local by_entity = require('by_entity')

return function()
    local backing = by_entity()
    local storage = sparse(64)

    function storage.set(entity, component)
        storage[entity] = component
    end

    function storage.clear(entity, component)
        storage[entity] = nil
    end

    function storage.get(entity)
        return storage[entity]
    end

    return storage
end
