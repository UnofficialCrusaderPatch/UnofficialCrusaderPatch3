
local writeInteger = core.writeInteger

local AICharacterName = require("characters")
local FieldTypes = require("fieldtypes")

local personality = require("personality")
local AIPersonalityFieldsEnum = personality.enum
local AIPersonalityFieldTypes = personality.types

local aicArrayBaseAddr = core.readInteger(core.AOBScan("? ? ? ? e8 ? ? ? ? 89 1d ? ? ? ? 83 3d ? ? ? ? 00 75 44 6a 08 b9 ? ? ? ? e8 ? ? ? ? 85 c0 74 34 8b c5 2b 05"))

local booleanToInteger = function(value)
    if type(value) == "boolean" then
        return value
    end

    if type(value) == "number" then
        if value ~= 1 and value ~= 0 then
            error("incomprehensible boolean value: " .. value)
        else
            return value
        end
    end

    if type(value) == "string" then
        if value:lower() == "true" then
            value = 1
        elseif value:lower() == "false" then
            value = 0
        elseif value == "1" then
            value = 1
        elseif value == "0" then
            value = 0
        else
            error("incomprehensible boolean value: " .. value)
        end
    end

    return value
end

local fieldValueToInteger = function(fieldName, stringValue)
    local result = nil

    local fieldType = AIPersonalityFieldTypes[fieldName]

    if fieldType == nil then
        error("invalid field name: " .. fieldName)
    end

    result = FieldTypes[fieldType][stringValue]

    if result == nil then
        error("invalid field value: " .. stringValue .. " for fieldName " .. fieldName)
    end

    return result
end

local aiTypeToInteger = function(aiType)
    for k, v in pairs(AICharacterName) do
        if k == aiType then
            return v
        end
    end
    error("no ai exists with the name: " .. aiType)
end

-- You can consider this a forward declaration
local namespace = {}

-- functions you want to expose to the outside world
namespace = {
    enable = function(self, config)
        if modules.commands then
            modules.commands.registerCommand("setAICValue", self.onCommandSetAICValue)
            modules.commands.registerCommand("loadAICsFromFile", self.onCommandloadAICsFromFile)
        end

        local fileName = config.aicFile
        if fileName then
            hooks.registerHookCallback("afterInit", function()
                print("Overwritten AIC values from file: " .. fileName)
                namespace.overwriteAICsFromFile(fileName)
            end)
        end

    end,
    disable = function(self)
    end,
    onCommandSetAICValue = function(command)
        local aiType, fieldName, value = command:match("^/setAICValue ([A-Za-z0-9_]+) ([A-Za-z0-9_]+) ([A-Za-z0-9_]+)$")
        if aiType == nil or fieldName == nil or value == nil then
            modules.commands.displayChatText(
                "invalid command: " .. command .. " usage: " .. 
                "/setAICValue [aiType: 1-16 or AI character type] [field name] [value]"
            )
        else
            namespace.setAICValue(aiType, fieldName, value)
        end
    end,
    onCommandloadAICsFromFile = function(command)
        local path = command:match("^/loadAICsFromFile ([A-Za-z0-9_ /.:-]+)$")
        if path == nil then
            modules.commands.displayChatText(
                "invalid command: " .. command .. " usage: " .. 
                "/loadAICsFromFile [path]"
            )
        else
            namespace.overwriteAICsFromFile(path)
        end
    end,
    setAICValue = function(aiType, aicField, aicValue)
        if type(aiType) == "string" then
            aiType = aiTypeToInteger(aiType)
        end

        local aicAddr = aicArrayBaseAddr + ((4 * 169) * aiType)

        local set = false

        -- we are doing a loop because we need to know the index, so this is also an index() logic
        for fieldIndex, fieldName in pairs(AIPersonalityFieldsEnum) do
            if fieldName == aicField then
                local fieldType = AIPersonalityFieldTypes[fieldName]
                if fieldType == "integer" then
                elseif fieldType == "boolean" then
                    aicValue = booleanToInteger(aicValue)
                else
                    aicValue = fieldValueToInteger(aicField, aicValue)
                end
                set = true
                writeInteger(aicAddr + (4 * (fieldIndex - 1)), aicValue) -- lua is 1-based, therefore fieldIndex-1
                --TODO: optimize by writing a longer array of bytes...
            end
        end
        if not set then
            error("invalid aic field name specified: " .. aicField)
        end
    end,
    overwriteAIC = function(aiType, aicSpec)
        for name, value in pairs(aicSpec) do
            namespace.setAICValue(aiType, name, value)
        end
    end,
    overwriteAICsFromFile = function(aicFilePath)
        local file = io.open(aicFilePath, "rb")
        local spec = file:read("*all")

        local aicSpec = json:decode(spec)
        local aics = aicSpec.AICharacters

        for k, aic in pairs(aics) do
            namespace.overwriteAIC(aic.Name, aic.Personality)
        end
    end
}

return namespace
