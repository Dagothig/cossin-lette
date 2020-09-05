function buffer_list ()
    local list = {}
    local to_add = {}
    local to_remove = {}

    function list.iter()
    end

    function list.add(entry)
        table.push(to_add, entry)
    end

    function list.remove(entry)
        table.push(to_remove, entry)
    end

    function list.process()
        while #to_add > 0 or #to_remove > 0 do
        end
    end
end