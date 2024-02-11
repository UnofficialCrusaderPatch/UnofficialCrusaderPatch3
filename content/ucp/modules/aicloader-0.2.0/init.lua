local writeInteger = core.writeInteger
local readInteger = core.readInteger

local AICharacterName = require("characters")

local Personality = require("personality")

local aicArrayBaseAddr = core.readInteger(core.AOBScan(
"? ? ? ? e8 ? ? ? ? 89 1d ? ? ? ? 83 3d ? ? ? ? 00 75 44 6a 08 b9 ? ? ? ? e8 ? ? ? ? 85 c0 74 34 8b c5 2b 05"))

local isInitialized = false
local vanillaAIC = {}

local additionalAIC = {}

local aiTypeToInteger = function(aiType)
  local aiInteger = AICharacterName[aiType]
  if aiInteger ~= nil then
    return aiInteger
  end
  error("no ai exists with the name: " .. aiType)
end

local function initializedCheck()
  if isInitialized then
    return true
  end

  log(WARNING, "AIC loader not yet initialized. Call ignored.")
  return false
end

local function saveVanillaAIC()
  local vanillaStartAddr = aicArrayBaseAddr + 4 * 169
  local vanillaEndAddr = aicArrayBaseAddr + 4 * 169 * 16 + 4 * 168
  for addr = vanillaStartAddr, vanillaEndAddr, 4 do
    vanillaAIC[addr] = readInteger(addr)
  end
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

    hooks.registerHookCallback("afterInit", function()
      saveVanillaAIC()

      isInitialized = true

      -- call override reset here, since initialization is through
      for _, aiType in pairs(AICharacterName) do
        Personality.resetOverridenValues(aiType)
      end

      if config.aicFiles then
        if type(config.aicFiles) == "table" then
          for i, fileName in pairs(config.aicFiles) do
            if fileName:len() > 0 then
              print("Overwritten AIC values from file: " .. fileName)
              namespace.overwriteAICsFromFile(fileName)
            end
          end
        else
          error("aicFiles should be a yaml array")
        end
      end

      log(INFO, "AIC loader initialized.")
    end)
  end,

  disable = function(self)
    if not initializedCheck() then
      return
    end
  end,

  onCommandSetAICValue = function(command)
    if not initializedCheck() then
      return
    end

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
    if not initializedCheck() then
      return
    end

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
    if not initializedCheck() then
      return
    end

    local status, err = pcall(function()
      if type(aiType) == "string" then
        aiType = aiTypeToInteger(aiType)
      end

      local additional = additionalAIC[aicField]
      if additional then
        additional.handlerFunction(aiType, aicValue)
        return
      end

      local aicAddr = aicArrayBaseAddr + ((4 * 169) * aiType)
      local fieldIndex, fieldValue = Personality.getAndValidateAicValue(aicField, aicValue)
      writeInteger(aicAddr + (4 * fieldIndex), fieldValue)
      --TODO: optimize by writing a longer array of bytes... (would only apply to native AIC structure)
    end)

    if not status then
      log(WARNING, string.format("Error while setting '%s': '%s'. Value ignored.", aicField, err))
    end
  end,

  overwriteAIC = function(aiType, aicSpec)
    if not initializedCheck() then
      return
    end

    for name, value in pairs(aicSpec) do
      namespace.setAICValue(aiType, name, value)
    end
  end,

  overwriteAICsFromFile = function(aicFilePath)
    if not initializedCheck() then
      return
    end

    local file = io.open(aicFilePath, "rb")
    local spec = file:read("*all")

    local aicSpec = yaml.parse(spec)
    local aics = aicSpec.AICharacters

    for k, aic in pairs(aics) do
      namespace.overwriteAIC(aic.Name, aic.Personality)
    end
  end,

  resetAIC = function(aiType)
    if not initializedCheck() then
      return
    end

    if type(aiType) == "string" then
      aiType = aiTypeToInteger(aiType)
    end

    local vanillaStartAddr = aicArrayBaseAddr + 4 * 169 * aiType
    local vanillaEndAddr = aicArrayBaseAddr + 4 * 169 * aiType + 4 * 168
    for addr = vanillaStartAddr, vanillaEndAddr, 4 do
      writeInteger(addr, vanillaAIC[addr])
    end

    Personality.resetOverridenValues(aiType)

    for _, additional in pairs(additionalAIC) do
      additional.resetFunction(aiType)
    end
  end,

  -- index == nil removes override; valueFunction needs to return final integer to write
  -- to allow renaming, there is no check if an index is overriden multiple times, to take care!
  -- resetFunction will always reveive an AI index starting from 1 (Rat) to 16 (Abbot)
  setAICValueOverride = function(aicField, index, valueFunction, resetFunction)
    Personality.setAICValueOverride(aicField, index, valueFunction, resetFunction)
  end,

  -- handlerFunction == nil removes additional AIC; handlerFunction only gets value from file, nothing else is done
  -- resetFunction will always reveive an AI index starting from 1 (Rat) to 16 (Abbot)
  setAdditionalAICValue = function(aicField, handlerFunction, resetFunction)
    if handlerFunction == nil then
      additionalAIC[aicField] = nil
      return
    end
    if not handlerFunction or type(handlerFunction) ~= "function" then
      error(string.format("Received no valid handler function for additional AIC with name '%s'.", aicField), 0)
    end
    if not resetFunction or type(resetFunction) ~= "function" then
      error(string.format("Received no valid reset function for additional AIC with name '%s'.", aicField), 0)
    end
    if additionalAIC[aicField] then
      log(WARNING,
        string.format("Replacing current handler for additional AIC with name %s. Is this intended?", aicField))
    end
    additionalAIC[aicField] = {
      handlerFunction = handlerFunction,
      resetFunction = resetFunction,
    }
  end
}

return namespace
