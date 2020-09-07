return function()
    local tbl = {}
    local meta = {}
    meta.__mode = 'k'
    setmetatable(tbl, meta)
    return tbl
end
