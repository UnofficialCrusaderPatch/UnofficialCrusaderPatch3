
--[[ Requires ]]--

local util = require("scripts.util")
local portrait = require("scripts.portrait")
local text = require("scripts.lines")


--[[ IDs and Constants ]]--

local AI_ROOT_FOLDER = "ucp/resources/ai"

local LORD_ID = {
  RAT         = 0,
  SNAKE       = 1,
  PIG         = 2,
  Wolf        = 3,
  SALADIN     = 4,
  CALIPH      = 5,
  SULTAN      = 6,
  RICHARD     = 7,
  FREDERICK   = 8,        
  PHILLIP     = 9,
  WAZIR       = 10,
  EMIR        = 11,
  NIZAR       = 12,
  SHERIFF     = 13,
  MARSHAL     = 14,
  ABBOT       = 15,
}

local DATA_PATH_META = "meta.json"


--[[ Variables ]]--

local aicModule = nil
local aivModule = nil
local filesModule = nil

local language = nil
local languageOverwrite = nil -- is {},  can be defined over the options to set a language for a specific AI


--[[ Functions ]]--

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
  if not util.containsValue(LORD_ID, positionToReplace) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  pathroot = pathroot or AI_ROOT_FOLDER

  local meta, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, aiName, DATA_PATH_META))
  if meta == nil then
    log(WARNING, string.format("Unable to set AI '%s'. Issues with meta file: %s", aiName, err))
    return
  end

  local aiLang = languageOverwrite[aiName]
  if aiLang == nil then
    aiLang = language
    if aiLang == nil then
      aiLang = meta.defaultLang
    end
  end
  
  if meta.supportedLang ~= nil and not util.containsValue(meta.supportedLang, aiLang) then
    log(WARNING, string.format("Language '%s' is not supported. Using fallback.", aiLang))
    aiLang = meta.defaultLang -- may or may not be default folder
  end
  
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

  setAiPart(portrait.loadAndSetPortrait, portrait.resetPortrait, control.portrait, meta.switched.portrait, positionToReplace, pathroot, aiName)
  setAiPart(text.setAiTexts, text.resetAiTexts, control.lines, meta.switched.lines, positionToReplace, pathroot, aiName, aiLang)
end


-- resets everything
local function resetAI(positionToReset)
  if not util.containsValue(LORD_ID, positionToReset) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  portrait.resetPortrait(positionToReset)
  text.resetAiTexts(positionToReset)
end



--[[ Main Func ]]--

local exports = {}

exports.enable = function(self, moduleConfig, globalConfig)

  -- get modules for easier variable access
  aicModule = modules.aicloader
  aivModule = modules.aivloader
  filesModule = modules.files
  
  self.SetAI = setAI
  self.ResetAI = resetAI


  -- get options
  
  language = moduleConfig.defaultLanguage
  languageOverwrite = moduleConfig.languageOverwrite or {}
end

exports.disable = function(self, moduleConfig, globalConfig) error("not implemented") end

return exports