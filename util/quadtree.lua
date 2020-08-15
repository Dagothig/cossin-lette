local quadtree = {}
local aabb = {}
local stack = {}

function aabb.overlap(lhs, rhs)
    return (
        lhs.min[1] < rhs.max[1] and
        rhs.min[1] < lhs.max[1] and
        lhs.min[2] < rhs.max[2] and 
        rhs.min[2] < lhs.max[2])
end

function quadtree.new(region)
    local node = { min = min, max = max }
end

function quadtree.query_leaves(node, region)
    local to_visit = { node }
    return function()
        local node = table.remove(to_visit)
        while node do
            if node.min and node.max then 
                if aabb.overlap(node, region) then
                    to_visit[#to_visit + 1] = node.tl
                    to_visit[#to_visit + 1] = node.tr
                    to_visit[#to_visit + 1] = node.bl
                    to_visit[#to_visit + 1] = node.br
                end
            else
                return node
            end
            node = table.remove(to_visit)
        end
    end
end

function quadtree.query(node, region)
    local iter_leaves = quadtree.query_leaves(node, region)
    local i, leaf = 0, nil
    return function()
        while leaf do
            while i < #leaf do
                i = i + 1
                local element = leaf[i]
                if aabb.overlap(element, region) then
                    return element
                end
            end
            i, leaf = 0, iter_leaves()
        end
    end
end

function quadtree.insert(node, region, obj)
    for n in quadtree.query(node) do

    end
end

function quadtree.remove(node, region, obj)

return quadtree