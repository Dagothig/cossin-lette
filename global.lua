PIXEL_PER_METER = 32
DAMPING = 32

function dump(o, pre, seen)
    seen = seen or {}
    pre = pre or ''
    if type(o) == 'table' then
        if seen[o] then
            return '<recursive>'
        end
        seen[o] = true

        local s = '{'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then
                k = k .. ' = '
            else
                k = ''
            end
            s = s .. '\n  ' .. pre .. k .. dump(v, pre .. '  ', seen) .. ','
        end
        return s .. '\n' .. pre .. '}'
    else
        return tostring(o)
    end
end

function trace()
    print(debug.traceback())
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

function table.batch(tbl, size)
    local batches = {}
    local batch = nil
    for i = 1, #tbl do
        if not batch or #batch == size then
            batch = {}
            batches[#batches + 1] = batch
        end
        batch[#batch + 1] = tbl[i]
    end

    return batches
end

iter = {}

function iter.empty()
    return nil
end

function iter.single(x)
    return function()
        local next = x
        x = nil
        return next
    end
end

function iter.table(iter, filter)
    local i = 1
    local tbl = {}
    for x in iter do
        if not filter or filter(x) then
            tbl[i] = x
            i = i + 1
        end
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

function vec2.mul(pt, x)
    return { pt[1] * x, pt[2] * x }
end

function vec2.interpolate(lhs, rhs, scale)
    local inverse = 1 - scale
    return {
        lhs[1] * inverse + rhs[1] * scale,
        lhs[2] * inverse + rhs[2] * scale
    }
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

fns = {}

function fns.override(obj, key, fn)
    local existing_fn = obj[key]
    obj[key] = existing_fn
        and function(...)
            existing_fn(...)
            fn(...)
        end
        or fn
end

systems = { set = {}, unset = {} }

function systems.set.all(system, components, fn)
    local composite_fn = function(world, entity, ...)
        for i = 1, #components do
            if not entity[components[i]] then
                return
            end
        end
        fn(world, entity, ...)
    end

    for i = 1, #components do
        fns.override(system.set, components[i], composite_fn)
    end
end

function systems.unset.all(system, components, fn)
    local composite_fn = function(world, entity, ...)
        for i = 1, #components do
            if not entity[components[i]] then
                return
            end
        end
        fn(world, entity, ...)
    end
    for i = 1, #components do
        fns.override(system.unset, components[i], composite_fn)
    end
end

font = love.graphics.newFont('fonts/Montserrat-Medium.ttf')
