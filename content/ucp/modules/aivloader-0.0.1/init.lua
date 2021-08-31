
-- Load a subset of aivs on startup, pointing to custom files

local startOfAIVMapNames = core.scanForAOB(utils.bytesToAOBString(table.pack(string.byte("aiv\\rat1.aiv", 1, -1))))
local FILENAME_LENGTH = 50
local CLEAR_BYTES = {}
for i=1,FILENAME_LENGTH do table.insert(CLEAR_BYTES, 0) end

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

local function getFileNameAddress(ai, castle)
    if type(ai) == "string" then
        if tonumber(ai) ~= nil then
            ai = tonumber(ai)
        else
            if aliases[ai] == nil then
                error("unknown alias: " .. k)
            end
            ai = aliases[ai]
        end
    end
    if type(ai) ~= "number" then error("invalid argument 1, not a number: " .. ai) end
    if tonumber(castle) == nil then error("invalid argument 2, not a number: " .. castle) end
    castle = tonumber(castle)
    if castle < 1 or castle > 8 then
        return error("invalid argument 2: key is out of bounds [1-8]")
    end
    return startOfAIVMapNames + (FILENAME_LENGTH*ai) + ((castle-1)*FILENAME_LENGTH)
end

local function clearEntry(address)
    core.writeBytes(address, CLEAR_BYTES)
end

local function writeFileName(ai, castle, fileName)
    local address = getFileNameAddress(ai, castle)
    if type(fileName) ~= "string" then error("invalid argument 3, not a string: " .. tostring(fileName)) end
       if fileName:len() > 49 then
            error("string is too long (max: 49): " .. fileName)
        end
    clearEntry(address)
    core.writeString(address, fileName)
    print("overwritten AI '" .. ai .. "' castle #" .. castle .. " at " .. address .. "d with: " .. core.readString(address))
end

local REPLACEMENTS = {}

local function replaceFileWith(ai, castle, newFileName)
    if not ai:match("[a-z]+") then error("invalid ai argument: " .. ai) end
    if type(castle) ~= "number" then
        if tonumber(castle) == nil then
            error("invalid castle argument: " .. castle)
        end
        castle = tonumber(castle)
    end
    if castle < 1 or castle > 8 then error("invalid castle argument: out of bounds [1-8]") end
    print("Replacing: '" .. "aiv\\" .. ai .. castle .. ".aiv'" .. " with: " .. newFileName)
    REPLACEMENTS["aiv\\" .. ai .. castle .. ".aiv"] = newFileName
end

return {
    enable = function(self, config)
        modules.files.registerOverrideFunction(function(fileName)
            print("Processing AIV override for: " .. fileName)
            if fileName:match("aiv\\.+.aiv$") then
                if REPLACEMENTS[fileName] ~= nil then
                    return REPLACEMENTS[fileName]
                end
            end
            return nil
        end)

        for ai, v in pairs(config) do
            for castle, fileName in pairs(v) do
                replaceFileWith(ai, castle, fileName)
            end
        end

    end,
    disable = function(self, config)

    end,

    -- ReadOnlyTable is preventing this from being prettier (we cannot expose 'api' because it becomes frozen)
    setAIVFileForAI = function(ai, castle, fileName)
        replaceFileWith(ai, castle, fileName)
    end,

}