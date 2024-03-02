-- NOTE: switch through console causes crashes sometimes, not easily reproduce-able

--[[ Requires ]]--

local enums = nil
local util = nil
local portrait = nil
local text = nil
local aic = nil
local bink = nil
local sfx = nil
local aiv = nil
local lord = nil
local troops = nil

--[[ IDs and Constants ]]--

local AI_ROOT_FOLDER = "ucp/resources/ai/"

local DATA_PATH_META = "meta.json"


--[[ Variables ]]--

local options = nil


--[[ Functions ]]--

local function getLordIndex(input)
  local inputType = type(input)
  if inputType == "number" and math.floor(input) == input then
    return input
  elseif inputType == "string" then
    return enums.LORD_ID[string.upper(input)] or -1
  else
    return -1
  end
end

local function determineOrVerifyLanguage(aiLang, meta)
  if aiLang == nil then
    aiLang = options.defaultLanguage
  end

  if aiLang == nil then
    aiLang = meta.defaultLang
  end

  if meta.supportedLang ~= nil and not util.containsValue(meta.supportedLang, aiLang) then
    log(WARNING, string.format("Language '%s' is not supported. Using fallback.", aiLang))
    aiLang = meta.defaultLang -- may or may not be default folder
  end
  return aiLang
end


local function setAiPart(setFunc, resetFunc, shouldModify, dataPresent, aiPosition, pathroot, ...)
  if shouldModify == nil then -- if nil, nothing is done
    return nil
  end
  if shouldModify and dataPresent then -- silently resets if the data is missing
    return setFunc(aiPosition, pathroot, ...)
  else
    return resetFunc(aiPosition) -- resets if shouldModify false or no data present
  end
end


local function setAI(lordToReplace, aiName, control, pathroot, aiLang)
  local positionToReplace = getLordIndex(lordToReplace)
  if not util.containsValue(enums.LORD_ID, positionToReplace) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord to replace given.", aiName))
    return
  end

  pathroot = ucp.internal.resolveAliasedPath(pathroot or (AI_ROOT_FOLDER .. aiName))

  local meta, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, DATA_PATH_META))
  if meta == nil then
    log(WARNING, string.format("Unable to set AI '%s'. Issues with meta file: %s", aiName, err))
    return
  end

  aiLang = determineOrVerifyLanguage(aiLang, meta)

  if meta.switched == nil then
    log(WARNING, string.format("Unable to set AI '%s'. No switch settings in meta file found.", aiName))
    return
  end


  -- all parts take care of their own reset, otherwise they are not usable on their own

  control = control or {
    [enums.CONFIG_CONTROL_ENTRY.BINKS] = true,
    [enums.CONFIG_CONTROL_ENTRY.SPEECH] = true,
    [enums.CONFIG_CONTROL_ENTRY.AIC] = true,
    [enums.CONFIG_CONTROL_ENTRY.AIV] = true,
    [enums.CONFIG_CONTROL_ENTRY.LORD] = true,
    [enums.CONFIG_CONTROL_ENTRY.STARTTROOPS] = true,
    [enums.CONFIG_CONTROL_ENTRY.LINES] = true,
    [enums.CONFIG_CONTROL_ENTRY.PORTRAIT] = true,
  }

  setAiPart(portrait.loadAndSetPortrait, portrait.resetPortrait, control.portrait,
    meta.switched.portrait, positionToReplace, pathroot, aiName)
  setAiPart(text.setAiTexts, text.resetAiTexts, control.lines, meta.switched.lines,
    positionToReplace, pathroot, aiName, aiLang)

  local loadedCharacterJson = nil
  loadedCharacterJson = setAiPart(aic.setAIC, aic.resetAIC, control.aic, meta.switched.aic,
    positionToReplace, pathroot, aiName, loadedCharacterJson)
  loadedCharacterJson = setAiPart(lord.setLord, lord.resetLord, control.lord, meta.switched.lord,
    positionToReplace, pathroot, aiName, loadedCharacterJson)
  loadedCharacterJson = setAiPart(troops.setStartTroops, troops.resetStartTroops, control.startTroops,
    meta.switched.startTroops, positionToReplace, pathroot, aiName, loadedCharacterJson)

  setAiPart(bink.setAiBinks, bink.resetAiBinks, control.binks, meta.switched.binks,
    positionToReplace, pathroot, aiName, aiLang)
  setAiPart(sfx.setAiSfx, sfx.resetAiSfx, control.speech, meta.switched.speech,
    positionToReplace, pathroot, aiName, aiLang)
  setAiPart(aiv.setAIV, aiv.resetAIV, control.aiv, meta.switched.aiv,
    positionToReplace, pathroot, aiName)
end


-- resets everything
local function resetAI(positionToReset)
  portrait.resetPortrait(positionToReset)
  text.resetAiTexts(positionToReset)
  aic.resetAIC(positionToReset)
  bink.resetAiBinks(positionToReset)
  sfx.resetAiSfx(positionToReset)
  aiv.resetAIV(positionToReset)
  lord.resetLord(positionToReset)
  troops.resetStartTroops(positionToReset)
end

local function generateApplyOptionsControl(aiControl, alreadyPlaced)
  local result = {}
  for optionKey, optionValue in pairs(aiControl) do
    if not alreadyPlaced:contains(optionKey) then
      alreadyPlaced:add(optionKey)

      -- false would trigger reset, which we do not need for initial ai placement
      if optionValue then
        result[optionKey] = optionValue
      end
    end
  end
  return result
end

local function applyAIOptions(indexToReplace)
  if not options.ai[indexToReplace] then
    return
  end

  local alreadyPlaced = extensions.utils.Set:new()
  for _, aiOption in ipairs(options.ai[indexToReplace]) do
    local aiControl = generateApplyOptionsControl(aiOption.control, alreadyPlaced)
    setAI(indexToReplace, aiOption.name, aiControl, aiOption.root, aiOption.language)
  end
end

local function resetAIWithOptions(lordToReplace, toVanilla)
  local positionToReset = getLordIndex(lordToReplace)
  if not util.containsValue(enums.LORD_ID, positionToReset) then
    log(WARNING, "Unable to reset AI. Invalid lord to replace given.")
    return
  end

  resetAI(positionToReset)

  if not toVanilla then
    applyAIOptions(positionToReset)
  end
end


local function resetAllAIWithOptions(toVanilla)
  for name, index in pairs(enums.LORD_ID) do
    resetAIWithOptions(index, toVanilla)
  end
end

local function transformConfigData(aiName, settings, collector)
  local index = enums.LORD_ID[string.upper(aiName)]
  if index == nil then
    log(WARNING, string.format("Unable to apply AI options for '%s'. Unknown lord.", aiName))
    return
  end

  local configMerger = {}
  for setting, entry in pairs(settings) do
    if not util.containsValue(enums.CONFIG_CONTROL_ENTRY, setting) then
      log(WARNING, string.format("Unable to apply AI setting '%s' for '%s'. Unknown setting.", setting, aiName))
    else
      local sourceKey = string.format("%s-%s-%s", entry.root, entry.name, entry.language)

      if not configMerger[sourceKey] then
        local config = {}
        configMerger[sourceKey] = config

        -- transform to path with version
        config.root = io.resolveAliasedPath(entry.root)

        config.name = entry.name
        config.control = {}
        config.language = entry.language
        config.extension = entry
      end
      configMerger[sourceKey].control[setting] = entry.active
    end
  end

  local aiConfigArray = {}
  local indexCount = 1
  for _, entry in pairs(configMerger) do
    aiConfigArray[indexCount] = entry
    indexCount = indexCount + 1
  end
  collector[aiName] = aiConfigArray
end

--[[ Main Func ]]--

local exports = {}

exports.enable = function(self, moduleConfig, globalConfig)
  -- load requires here, so that the cpp helper module can find the functions
  enums = require("scripts.enums")
  util = require("scripts.util")
  portrait = require("scripts.portrait")
  text = require("scripts.lines")
  aic = require("scripts.aic")
  bink = require("scripts.bink")
  sfx = require("scripts.sfx")
  aiv = require("scripts.aiv")
  lord = require("scripts.lord")
  troops = require("scripts.troops")

  -- get options
  options = moduleConfig
  if not options.ai then
    options.ai = {}
  else
    local compatibleAiSettings = {}
    for ai, settings in pairs(options.ai) do
      transformConfigData(ai, settings, compatibleAiSettings)
    end
    options.ai = compatibleAiSettings
  end

  -- set functions

  self.SetAI = setAI
  self.ResetAI = resetAIWithOptions
  self.ResetAllAI = resetAllAIWithOptions

  hooks.registerHookCallback("afterInit", function()
    for index, _ in pairs(options.ai) do
      applyAIOptions(index)
    end
    log(INFO, "Applied AI Options.")
  end)
end

exports.disable = function(self, moduleConfig, globalConfig) error("not implemented") end

return exports
