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