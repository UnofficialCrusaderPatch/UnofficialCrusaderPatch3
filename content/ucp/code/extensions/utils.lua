
---@class Set
---@private
local Set = {}
function Set:new(values)
    local o = {
        data = values or {}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Set:index(el)
    for k, v in pairs(self.data) do
        if v == el then
            return k
        end
    end
    return nil
end

function Set:contains(el)
    return self:index(el) ~= nil
end

function Set:add(el)
    if not self:contains(el) then
        table.insert(self.data, el)
        return true
    else
        return false
    end
end

function Set:delete(el)
    local index = self:index(el)
    if index ~= nil then
        table.remove(self.data, index)
        return true
    end
    return false
end

function Set:subtract(s)
    local result = Set:new()
    for k, v in pairs(self.data) do
        if not s:contains(v) then
            result:add(v)
        end
    end
    return result
end

function Set:update(s)
    for k, v in pairs(s.data) do
        self:add(v)
    end
    return self
end


---@private
---@param t table the table to compute the size of
local sizeOfTable = function(t)
    local result = 0
    for k, v in pairs(t) do
        result = result + 1
    end
    return result
end




--TODO test this thoroughly
---Creates a read only proxy table by proxying __index and __newindex of an existing table
---@class ReadOnlyTable
---@private
local ReadOnlyTable = {
    ---Create a new read-only table
    ---@param o table the object to make read-only
    new = function(self, o)
        if type(o) ~= "table" then
            error("the first parameter is not a table: " .. type(o))
        end
        return setmetatable({}, {
            __index = function(self, k)
                return o[k]
            end,
            __newindex = function(self, k, v)
                return error("setting values is not allowed: " .. k)
            end
        })
    end
}

---Change a table to a read-only table. Affects all nested tables too.
---@param o table the table to change into a read-only table
---@return table a read-only table
---@private
local function createRecursiveReadOnlyTable(o)
    for k, v in pairs(o) do
        if type(v) == "table" then
            o[k] = createRecursiveReadOnlyTable(v)
        end
    end
    return ReadOnlyTable:new(o)
end

return {
    createRecursiveReadOnlyTable = createRecursiveReadOnlyTable,
    ReadOnlyTable = ReadOnlyTable,
    Set = Set,
    sizeOfTable = sizeOfTable,
}