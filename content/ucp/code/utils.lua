---@module utils
local utils = {}

core = require('core')

-- Creates a new memory allocation and returns its address.
function utils.createLuaFunctionWrapper(callback)
    local newMemoryAllocation = core.allocate(6)
    core.writeInteger(newMemoryAllocation, 0x90909090) -- we will yoink this
    core.writeByte(newMemoryAllocation + 4, 0x90)
    core.writeByte(newMemoryAllocation + 5, 0xC3)

    core.detourCode(callback, newMemoryAllocation, 5)

    return newMemoryAllocation
end

--[[
Converts byte `value` to an unsigned byte (0-255).
--]]
function utils.ub(value)
    if value < 0 then
        return 256 + value -- (256 + -1 = 255)
    else
        return value
    end
end

function utils.smallIntegerToBytes(value)
    return {
        (value >> 0) & 0xFF,
        (value >> 8) & 0xFF,
    }
end

function utils.intToBytes(value)
    return {
        (value >> 0) & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
    }
end

utils.itob = utils.intToBytes

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
function utils.intToHex(input)
    return string.format("%X", input)
end

utils.bytesToAOBString = function(b)
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

function table.length(t)
    local counter = 0
    for k, v in pairs(t) do counter = counter + 1 end
    return counter
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

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

utils.OrderedTable = {
    new = function(self)
        local o = {

        }

        local keyOrder = {}

        local ot = setmetatable({}, {

            __index = function(self, k)
                return o[k]
            end,

            __newindex = function(self, k, v)
                table.insert(keyOrder, k)
                o[k] = v
            end,

            __ipairs = function(self)
                error("using ipairs on an OrderedTable is probably not want you want")
            end,

            __pairs = function(self)
                -- Iterator function takes the table and an index and returns the next index and associated value
                -- or nil to end iteration

                local i = nil

                local function stateless_iter(tbl, k)
                    local k
                    -- Implemented own key,value selection logic in place of next
                    i, k = next(keyOrder, i)
                    if nil ~= k then
                        return k, o[k]
                    end
                end

                -- Return an iterator function, the table, starting point
                return stateless_iter, self, nil
            end,
        })

        self.__index = self

        return ot
    end,

}

function utils.unpack(fmt, data, simplify)
    if simplify == nil then
        simplify = true
    end

    local result = {}
    local offset = 1

    while offset <= data:len() do
        local unpacked = table.pack(string.unpack(fmt, data, offset))

        offset = unpacked[unpacked.n] -- last value is the new offset

        if unpacked.n == 2 then
            -- special case: new offset and 1 value

            table.insert(result, unpacked[1])
        else
            unpacked.n = nil
            if offset ~= table.remove(unpacked) then -- remove the last value, which is new offset
                -- assert that truth
                error(debug.traceback("offset not equal to removed value"))
            end

            table.insert(result, unpacked)
        end
    end

    if #result == 1 and simplify then
        return result[1]
    end

    return result
end

function utils.pack(fmt, data)
    local result = {}
    local value

    for offset = 1, #data, 1 do
        local datum = data[offset]

        if type(datum) == "table" then
            value = string.pack(fmt, table.unpack(datum))
        else
            value = string.pack(fmt, datum)
        end

        result[offset] = value
    end

    return table.concat(result)
end

local AOBExtractor = {}
function AOBExtractor.parse(target)
    local contains = function(t, value)
        for k, v in pairs(t) do if v == value then return true end end
        return false
    end

    local validBytes = {
        "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "F", "f",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "?",
    }

    local aob = {}
    local currentaob = 0

    local groups = {}
    local currentgroup = 0

    local i = 1

    while i <= #target do
        local c = target:sub(i, i)
        local cn = target:sub(i + 1, i + 1)

        if c == " " then

        elseif c == "@" then
            if cn == "(" then
                if currentgroup ~= 0 then error("Capture groups cannot be nested. Missing ')'") end

                table.insert(groups, {
                    type = "relative_address",
                    start = nil,
                    stop = nil,
                    size = 0,
                })

                currentgroup = #groups

                i = i + 1 -- extra + 1 since we processed two chars
            else
                error("Expected (")
            end
        elseif c == "I" then
            if cn == "(" then
                if currentgroup ~= 0 then error("Capture groups cannot be nested. Missing ')'") end

                table.insert(groups, {
                    type = "integer",
                    start = nil,
                    stop = nil,
                    size = 0,
                })

                currentgroup = #groups

                i = i + 1 -- extra + 1 since we processed two chars
            else
                error("Expected (")
            end
        elseif c == "(" then
            if currentgroup ~= 0 then error("Capture groups cannot be nested. Missing ')'") end

            -- Not prefixed with I or S
            table.insert(groups, {
                type = "bytes",
                start = nil, -- assume a byte will follow
                stop = nil,
                size = 0,
            })

            currentgroup = #groups
        elseif c == ")" then
            if currentgroup == 0 then error("Missing '('") end

            local group = groups[currentgroup]
            group.stop = #aob
            group.size = 1 + (group.stop - group.start)

            if group.type == "integer" and group.size ~= 4 then
                error(string.format(
                    "Capture group of type I() cannot be of a size other than 4. Size was: %s. Error occurred at: %s",
                    group.size, i))
            end

            if group.type == "relative_address" and group.size ~= 5 then
                error(string.format(
                    "Capture group of type @() cannot be of a size other than 5. Size was: %s. Error occurred at: %s",
                    group.size, i))
            end

            currentgroup = 0
        elseif contains(validBytes, c) then
            if currentaob == 0 then
                currentaob = #aob + 1

                if c == "?" then
                    aob[currentaob] = c
                    currentaob = 0 -- finished with this byte
                else
                    if contains(validBytes, cn) and cn ~= "?" then
                        aob[currentaob] = c .. cn
                        currentaob = 0

                        i = i + 1 -- we processed an extra char
                    else
                        error(string.format("Could not parse: %s . Syntax error at: %s, character: %s", target, i, c))
                    end
                end
            else
                error(string.format("How did we get here: %s, %s", target, i))
            end

            if currentgroup ~= 0 then
                if groups[currentgroup].start == nil then
                    groups[currentgroup].start = #aob
                end
            end
        else
            error(string.format("Invalid character: %s", c))
        end

        i = i + 1
    end

    if currentgroup ~= 0 then
        error("Missing ')'")
    end

    if currentaob ~= 0 then
        error("Missing final byte")
    end

    return {
        aob = table.concat(aob, " "),
        groups = groups,
    }
end

function AOBExtractor.extract(target, start, stop, unpacked)
	log(VERBOSE, string.format("AOBExtractor.extract: unpacked: %s, target: %s", unpacked, target))
    if unpacked == nil or unpacked == true then
        unpacked = true
    else
        unpacked = false
    end

    local parsed = AOBExtractor.parse(target)
	log(VERBOSE, string.format("AOBExtractor.extract: unpacked: %s, parsed: %s", unpacked, parsed.aob))

    local address = core.AOBScan(parsed.aob, start, stop)
	log(VERBOSE, string.format("AOBExtractor.extract: unpacked: %s, found: 0x%X for parsed: %s", unpacked, address, parsed.aob))

    local results = {}

    for k, group in pairs(parsed.groups) do
        if group.type == "integer" then
            table.insert(results, core.readInteger(address + (group.start - 1)))
        elseif group.type == "bytes" then
            table.insert(results, core.readBytes(address + (group.start - 1), group.size))
        elseif group.type == "relative_address" then
            table.insert(results, 5 + address + (group.start - 1) + core.readInteger(address + (group.start - 1) + 1))
        else
            error(string.format("Invalid group type: %s", group.type))
        end
    end
	
	log(VERBOSE, string.format("AOBExtractor.extract: unpacked: %s, first result: 0x%X", unpacked, results[1] or "nil|0"))

    if unpacked then
        return table.unpack({ address, table.unpack(results) })
    else
        return { address, results }
    end
end

---Use capture groups in AOB search strings to immediately return values of interest
---Searches through the memory for an array of bytes expressed as a hex string (where `?` can be used as wildcards: "FF 00 ? AA").
---If the target is not found in memory, an error will be raised.
---If the target is found, capture groups are evaluated and also returned.
---
---Supported capture groups are: @(), I(), ()
---These return: a relative address made absolute (jmp/call, 5 bytes), an integer (4 bytes), array of bytes
---
---@param target string the hex string to search for
---@param start number the starting address of the memory to start searching from
---@param stop number the last address of the memory to stop searching at
---@param unpacked boolean|nil optional whether to return result in unpacked form (default) or not
---@return ...number results the address of target in memory, and the result of capture groups
function utils.AOBExtract(target, start, stop, unpacked)
    return AOBExtractor.extract(target, start, stop, unpacked)
end

return utils
