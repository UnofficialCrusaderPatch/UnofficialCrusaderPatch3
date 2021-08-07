
-- Load a subset of aivs on startup, pointing to custom files

local startOfAIVMapNames = core.scanForAOB(utils.bytesToAOBString(table.pack(string.byte("aiv\\rat1.aiv", 1, -1))))

local aliases = {
    rat = 0,
    snake = 1,
    pig = 2,
    wolf = 3,
    saladin = 4,
    caliph = 5,
    sultan = 6,
    richard = 7,
    frederick = 8,
    phillip = 9,
    wazir = 10,
    emir = 11,
    nizar = 12,
    sheriff = 13,
    marshal = 14,
    abbot = 15
}

local AIVFileNumberAPI = {
    new = function(self, address)
        local o = {
            address = address
        }
        return setmetatable(o, self)
    end,

    __index = function(self, k)
        if tonumber(k) == nil then error("not a number: " .. k) end
        k = tonumber(k)
        if k < 1 or k > 8 then
            return error("key is out of bounds [1-8]")
        end
        return core.readString(self.address + (50*(k-1)))
    end,

    __newindex = function(self, k, v)
        if tonumber(k) == nil then error("not a number: " .. k) end
        k = tonumber(k)
        if k < 1 or k > 8 then
            return error("key is out of bounds [1-8]")
        end
        return core.writeString(self.address + (50*(k-1)), v)
    end
}

local AIVFilenameAPI = {
    new = function(self)
        local _nested_apis = {}
        for k=0,15 do
            _nested_apis[k] = AIVFileNumberAPI:new(startOfAIVMapNames + (50*8*k))
        end
        local o = {
            _nested_apis = _nested_apis
        }
        return setmetatable(o, self)
    end,

    __index = function(self, k)
        if type(k) == "string" then
            if tonumber(k) ~= nil then
                k = tonumber(k)
            else
                if aliases[k] == nil then
                    error("unknown alias: " .. k)
                end
                k = aliases[k]
            end
        end
        if type(k) ~= "number" then error("invalid argument 1, not a number") end
        return self._nested_apis[k]
    end,

    __newindex = function(self, k, v)
        if type(k) == "string" then
            if tonumber(k) ~= nil then
                k = tonumber(k)
            else
                if aliases[k] == nil then
                    error("unknown alias: " .. k)
                end
                k = aliases[k]
            end
        end
        if type(k) ~= "number" then error("invalid argument 1, not a number") end
        if type(v) ~= "string" then error("invalid argument 2, not a string") end
        if v:len() > 49 then
            error("string is too long (max: 49): " .. v)
        end
        self._nested_apis[k] = v
    end

}

local api = AIVFilenameAPI:new()

return {
    enable = function(self, config)
        if config == nil then return end
        for k, v in pairs(config) do
            for k2, v2 in pairs(v) do
                api[k][k2] = v2
            end
        end
    end,
    disable = function(self, config)

    end,

    -- ReadOnlyTable is preventing this from being prettier (we cannot expose 'api' because it becomes frozen)
    setAIVFileForAI = function(self, ai, castle, filename)
        api[ai][castle] = filename
    end,
    getAIVFileForAI = function(self, ai, castle)
        return api[ai][castle]
    end
}