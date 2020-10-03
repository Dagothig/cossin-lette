local next_sparse_id = 1
return function(cell_size)
    local sparse = { id = next_sparse_id }
    next_sparse_id = next_sparse_id + 1

    function sparse.indices(box)
        return
            { math.floor(box[1][1] / cell_size) + 1, math.floor(box[1][2] / cell_size) + 1 },
            { math.ceil(box[2][1] / cell_size), math.ceil(box[2][2] / cell_size) }
    end

    function sparse.cells(box, create_cells)
        local min, max = sparse.indices(box)
        local i, j = min[1], min[2] - 1
        return function()
            while true do
                j = j + 1
                while j > max[2] do
                    i, j = i + 1, min[2]
                    if i > max[1] then
                        return nil
                    end
                end
                if sparse[i] or create_cells then
                    local strip = table.get(sparse, i, table.new)
                    if strip[j] or create_cells then
                        if i < min[1] or i > max[1] then
                            (nil)()
                        end
                        if j < min[2] or j > max[2] then
                            (nil)()
                        end
                        return table.get(strip, j, table.new), i, j
                    end
                end
            end
        end
    end

    function sparse.region(box, loose)
        local iter = sparse.cells(box)
        local cell, i, j = iter()
        local k = 0
        local found = {}
        return function()
            while cell do
                k = k + 1
                while k > #cell do
                    cell, i, j = iter()
                    k = 1
                    if not cell then
                        return nil
                    end
                end
                local element = cell[k]
                if not found[element] and (loose or aabb.overlap(box, element.aabb)) then
                    found[element] = true
                    return element, i, j, k
                end
            end
        end
    end

    function sparse.insert(obj)
        for cell, i, j in sparse.cells(obj.aabb, true) do
            cell[#cell + 1] = obj
        end
        obj[sparse.id] = { obj.aabb, obj.pos }
    end

    function sparse.remove(obj)
        local entry = obj[sparse.id]
        if not entry then
            return
        end

        local aabb = entry[1]
        for cell in sparse.cells(aabb) do
            table.remove(cell, table.index(cell, obj))
        end
        obj[sparse.id] = nil
    end

    function sparse.update(obj)
        local entry = obj[sparse.id]
        local old_aabb, old_pos = entry[1], entry[2]
        if aabb.eq(old_aabb, obj.aabb) and vec2.eq(old_pos, obj.pos) then
            return
        else
            entry[1], entry[2] = obj.aabb, obj.pos
        end

        local new_min, new_max = sparse.indices(obj.aabb)
        for cell, i, j in sparse.cells(old_aabb) do
            if i < new_min[1] or new_max[1] < i or j < new_min[2] or new_max[2] < j then
                table.remove(cell, table.index(cell, obj))
            end
        end

        local old_min, old_max = sparse.indices(old_aabb)
        for cell, i, j in sparse.cells(obj.aabb, true) do
            if i < old_min[1] or old_max[1] < i or j < old_min[2] or old_max[2] < j then
                cell[#cell + 1] = obj
            end
        end
    end

    return sparse
end
