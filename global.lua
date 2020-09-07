function dump(o, pre)
    pre = pre or ''
    if type(o) == 'table' then
        local s = '{'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then
                k = k .. ' = '
            else
                k = ''
            end
            s = s .. '\n  ' .. pre .. k .. dump(v, pre .. '  ') .. ','
        end
        return s .. '\n' .. pre .. '}'
    else
        return tostring(o)
    end
end

function cpy(t)
    local t2 = {}
    for k,v in pairs(t) do t2[k] = v end
    return t2
end

function push(arr, x)
    arr[#arr + 1] = x
end

function pairsByKeys (t, f)
    local a = {}
    for _, v in pairs(t) do table.insert(a, v) end
    table.sort(a, f)
    local i = 0
    return function ()
        i = i + 1
        return a[i]
    end
end

function table.new()
    return {}
end

function table.index(tbl, obj)
    for i = 1, #tbl do
        if tbl[i] == obj then
            return i
        end
    end
end

function table.search(tbl, fn)
    for i = 1, #tbl do
        if fn(tbl[i]) then
            return i
        end
    end
end

function table.push(tbl, obj)
    tbl[#tbl + 1] = obj
end

function table.get(tbl, key, fn)
    local val = tbl[key]
    if not val then
        val = fn()
        tbl[key] = val
    end
    return val
end

iter = {}

function iter.single(x)
    return function()
        local next = x
        x = nil
        return next
    end
end

function iter.table(iter)
    local i = 1
    local tbl = {}
    for x in iter do
        tbl[i] = x
        i = i + 1
    end
    return tbl
end

vec2 = {}

function vec2.sub(lhs, rhs)
    return { lhs[1] - rhs[1], lhs[2] - rhs[2] }
end

function vec2.add(lhs, rhs)
    return { lhs[1] + rhs[1], lhs[2] + rhs[2] }
end

function vec2.eq(lhs, rhs)
    return lhs[1] == rhs[1] and lhs[2] == rhs[2]
end

aabb = {}

function aabb.eq(lhs, rhs)
    return vec2.eq(lhs[1], rhs[1]) and vec2.eq(lhs[2], rhs[2])
end

function aabb.contains(box, pt)
    return (
        box[1][1] < pt[1] and pt[1] < box[2][1] and
        box[1][2] < pt[2] and pt[2] < box[2][2])
end

function aabb.overlap(lhs, rhs)
    return (
        lhs[1][1] < rhs[2][1] and rhs[1][1] < lhs[2][1] and
        lhs[1][2] < rhs[2][2] and rhs[1][2] < lhs[2][2])
end
