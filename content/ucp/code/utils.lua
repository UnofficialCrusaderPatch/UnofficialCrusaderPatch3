---@module namespace
local namespace = {}

core = require('core')

-- Creates a new memory allocation and returns its address.
function namespace.createLuaFunctionWrapper(callback)
    newMemoryAllocation = core.allocate(6)
    core.writeInteger(newMemoryAllocation, 0x90909090) -- we will yoink this
    core.writeByte(newMemoryAllocation + 4, 0x90)
    core.writeByte(newMemoryAllocation + 5, 0xC3)

    core.detourCode(callback, newMemoryAllocation, 5)

    return newMemoryAllocation
end

--[[
Converts byte `value` to an unsigned byte (0-255).
--]]
function namespace.ub(value)
    if value < 0 then
        return 256 + value -- (256 + -1 = 255)
    else
        return value
    end
end

function namespace.smallIntegerToBytes(value)
    return {
        (value >> 0) & 0xFF,
        (value >> 8) & 0xFF,
    }
end

function namespace.intToBytes(value)
    return {
        (value >> 0) & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
    }
end

namespace.itob = namespace.intToBytes

function table.join(t, sep, fmt)
    if fmt == nil then
        fmt = "%x"
    end
    result = ""
    for k, v in pairs(t) do
        if k ~= 1 then
            result = result .. sep
        end
        result = result .. string.format(fmt, v)
    end
    return result
end

-- Converts int into hex
function namespace.intToHex(input)
    return string.format("%X", input)
end

namespace.bytesToAOBString = function(b)
    local targetString = ""
    for k, v in ipairs(b) do
        if k > 0 then
            targetString = targetString .. " "
        end

        if v < 16 then
            targetString = targetString .. "0"
        end
        targetString = targetString .. string.format("%x", v)
    end
    return targetString
end

function table.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. table.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

---Overwrite all key-value pairs that are in o2 and in o with values from o2. Recurse if type table
function table.update(o, o2)
    local t = {}

    for k, v in pairs(o) do
        local v2 = o2[k]
        if o2[k] ~= nil then
            if type(v) == "table" or type(v2) == "table" then
                t[k] = table.update(v, v2)
            else
                t[k] = v2
            end
        else
            t[k] = v
        end
    end

    return t
end

function table.find(t1, target)
    for k, v in pairs(t1) do
        if v == target then
            return k
        end
    end
    return nil
end

function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function table.values(t)
    local values = {}
    for k, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

function inheritsMetaTable(obj, metaTable)
    local needle = getmetatable(obj)
    while needle ~= nil do
        if needle == metaTable then
            return true
        end
        needle = getmetatable(needle)
    end
end

return namespace