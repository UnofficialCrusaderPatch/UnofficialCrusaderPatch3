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

local AI_ROOT_FOLDER = "ucp/resources/ai"

local DATA_PATH_META = "meta.json"


--[[ Variables ]]--

local options = nil


--[[ Functions ]]--

local function determineLanguage(indexToReplace, aiName, meta)
  local aiLang = nil
  if options.ai[indexToReplace] and options.ai[indexToReplace][aiName] then
    aiLang = options.ai[indexToReplace][aiName].language
  end
  
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
  if shouldModify and dataPresent then  -- silently resets if the data is missing
    return setFunc(aiPosition, pathroot, ...)
  else
    return resetFunc(aiPosition) -- resets if shouldModify false or no data present
  end
end


local function setAI(positionToReplace, aiName, control, pathroot)
  if not util.containsValue(enums.LORD_ID, positionToReplace) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  pathroot = pathroot or AI_ROOT_FOLDER

  local meta, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, aiName, DATA_PATH_META))
  if meta == nil then
    log(WARNING, string.format("Unable to set AI '%s'. Issues with meta file: %s", aiName, err))
    return
  end
  
  local aiLang = determineLanguage(positionToReplace, aiName, meta)
  
  if meta.switched == nil then
    log(WARNING, string.format("Unable to set AI '%s'. No switch settings in meta file found.", aiName))
    return
  end
  
  
  -- all parts take care of their own reset, otherwise they are not usable on their own
  
  control = control or {
    binks = true,
    speech = true,
    aic = true,
    aiv = true,
    lord = true,
    startTroops = true,
    ["lines"] = true,
    portrait = true,
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
  if not util.containsValue(enums.LORD_ID, positionToReset) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  portrait.resetPortrait(positionToReset)
  text.resetAiTexts(positionToReset)
  aic.resetAIC(positionToReset)
  bink.resetAiBinks(positionToReset)
  sfx.resetAiSfx(positionToReset)
  aiv.resetAIV(positionToReset)
  lord.resetLord(positionToReset)
  troops.resetStartTroops(positionToReset)
end


local function applyAIOptions(indexToReplace)
  if options.ai[indexToReplace] then
    for aiName, aiOptions in pairs(options.ai[indexToReplace]) do
      setAI(indexToReplace, aiName, aiOptions.control)
    end
  end
end


local function resetAIWithOptions(positionToReset, toVanilla)
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
    options.ai = util.createTableWithTransformedKeys(options.ai, function(aiName) return enums.LORD_ID[string.upper(aiName)] end, false)
  end
  
  -- set functions
  
  self.SetAI = setAI
  self.ResetAI = resetAIWithOptions
  self.ResetAllAI = resetAllAIWithOptions
  
  hooks.registerHookCallback("afterInit", function()
    for name, index in pairs(enums.LORD_ID) do
      applyAIOptions(index)
    end
  end)
end

exports.disable = function(self, moduleConfig, globalConfig) error("not implemented") end

return exports