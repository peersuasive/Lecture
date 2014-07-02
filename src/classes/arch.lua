local dec = require"decomp"

local mt = {}

local function new(_, book)
    if not book then
        return nil, "Missing book"
    end
    local dec = dec
    if not dec then
        return nil, "Couldn't initialise decompressor"
    end

    local self = {}
    local book, list = book, {}
    local function open(b)
        if not b then return nil, "Missing book" end
        book = b
        local l, e = dec.list(book)
        if not l then return nil, e end
        for _,f in next, l do
            list[#list+1] = not(f:match("/$")) and f or nil 
        end
        table.sort(list)
        return true
    end
    function self:open(b)
        return open(b)
    end

    function self:get(n)
        local data, e = dec.filter(book, n)
        return data and data[1], e
    end

    function self:list()
        return list
    end

    if(book)then 
        local r, e = open(book)
        if not(r) then return nil, e end
    end
    return self
end


return setmetatable(mt, {
    __call = new
})
