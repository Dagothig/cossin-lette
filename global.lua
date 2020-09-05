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

function table.index(tbl, obj)
    return table.search(tbl, function (other) return other == obj end)
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

function aabb.overlap(lhs, rhs)
    return not rhs.min and aabb.contains(lhs, rhs) or (
        lhs.min[1] < rhs.max[1] and
        rhs.min[1] < lhs.max[1] and
        lhs.min[2] < rhs.max[2] and
        rhs.min[2] < lhs.max[2])
end
