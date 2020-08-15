return function(cell_size)
    local sparse = {}

    function sparse.indices(aabb)
        return 
            { math.floor(aabb.min[1] / cell_size) + 1, math.floor(aabb.min[2] / cell_size) + 1 },
            { math.ceil(aabb.max[1] / cell_size), math.ceil(aabb.max[2] / cell_size) }
    end

    function sparse.cells(region, create_cells)
        local cell_min, cell_max = sparse.indices(region)
        local i, j = cell_min[1] - 1, cell_min[2]
        local strip = nil
        return function()
            while true do
                if j > cell_max[2] or not strip then
                    i, j = i + 1, cell_min[2]
                    strip = sparse[i]
                    if create_cells and not strip then
                        strip = {}
                        sparse[i] = strip
                    end
                end
                if i > cell_max[1] then
                    return nil
                end
                local cell = strip and strip[j]
                if create_cells and not cell then
                    cell = {}
                    strip[j] = cell
                end
                j = j + 1
                if cell then
                    return i, j - 1, cell
                end
            end
        end
    end

    function sparse.region(region)
        local cells_iter = sparse.cells(region)
        local _, _, cell = cells_iter()
        local i = 1
        local found = {}
        return function()
            while cell do
                while i <= #cell do
                    local element = cell[i]
                    i = i + 1
                    if not found[element] and aabb.overlap(region, element) then
                        found[element] = true
                        return element
                    end
                end
                _, _, cell = cells_iter()
                i = 1
            end

        end
    end

    function sparse.insert(obj)
        local search_fn = function (other) return other > obj end
        for _, _, cell in sparse.cells(obj, true) do
            table.insert(cell, table.search(cell, search_fn) or 1, obj)
        end
    end

    function sparse.remove(obj)
        for _, _, cell in sparse.cells(obj) do
            table.remove(cell, table.index(cell, obj))
        end
    end

    function sparse.update(obj, new)
        local old_min, old_max = sparse.indices(obj)
        local new_min, new_max = sparse.indices(new)
        local search_fn = function (other) return other > obj end
        for i, j, cell in sparse.cells(obj) do
            local inside_old = 
                i >= old_min[1] and
                i <= old_max[1] and
                j >= old_min[2] and
                j <= old_max[2]

            local inside_new = 
                i >= new_min[1] and
                i <= new_max[1] and
                j >= new_min[2] and
                j <= new_max[2]

            if inside_old and not inside_new then
                table.remove(cell, table.index(cell, obj))
            end
        end
        for i, j, cell in sparse.cells(new, true) do
            local inside_old =
                i >= old_min[1] and
                i <= old_max[1] and
                j >= old_min[2] and
                j <= old_max[2]

            local inside_new =
                i >= new_min[1] and
                i <= new_max[1] and
                j >= new_min[2] and
                j <= new_max[2]

            if not inside_old and inside_new then
                table.insert(cell, table.search(cell, search_fn) or 1, obj)
            end
        end
        obj.min, obj.max = new.min, new.max
    end
    
    return sparse
end