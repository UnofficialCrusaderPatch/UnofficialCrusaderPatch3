

--[[ IDs and Constants ]]--

local AI_ROOT_FOLDER = "ucp/resources/ai"

local GM_DATA = {
  GM_INDEX                  = 46    ,
  FIRST_ICON_INDEX          = 522   ,
  FIRST_SMALL_ICON_INDEX    = 700   ,
}

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

local DATA_PATH = {
  NORMAL_PORTRAIT     = "portrait.png",
  SMALL_PORTRAIT      = "portrait_small.png",
  META                = "meta.json",
  TEXT                = "lines.json",
}


local NUMBER_OF_SKRIMISH_LINES = 34
local INDEX_OF_AI_NAMES_AND_MENU_TEXT = 79
local AI_NAMES_AND_MENU_TEXT_ID_START = 111

local INDEX_OF_AI_SKRIMISH_TEXT = 231
local NUMBER_OF_TITLES = 8


local NAMES_AND_MENU_TEXT_ID = {
  COMPLETE_TITLE_1    = 0   ,
  COMPLETE_TITLE_2    = 1   ,
  COMPLETE_TITLE_3    = 2   ,
  COMPLETE_TITLE_4    = 3   ,
  COMPLETE_TITLE_5    = 4   ,
  COMPLETE_TITLE_6    = 5   ,
  COMPLETE_TITLE_7    = 6   ,
  COMPLETE_TITLE_8    = 7   ,
  AI_NAME             = 128 ,
  TITLE_1             = 129 ,
  TITLE_2             = 130 ,
  TITLE_3             = 131 ,
  TITLE_4             = 132 ,
  TITLE_5             = 133 ,
  TITLE_6             = 134 ,
  TITLE_7             = 135 ,
  TITLE_8             = 136 ,
  DESCRIPTION         = 274 ,
}

local SKRIMISH_TEXT_ID = {
  UNKNOWN_1     = 0   ,
  TAUNT_1       = 1   ,
  TAUNT_2       = 2   ,
  TAUNT_3       = 3   ,
  TAUNT_4       = 4   ,
  ANGER_1       = 5   ,
  ANGER_2       = 6   ,
  PLEAD         = 7   ,
  NERVOUS_1     = 8   ,
  NERVOUS_2     = 9   ,
  VICTORY_1     = 10  ,
  VICTORY_2     = 11  ,
  VICTORY_3     = 12  ,
  VICTORY_4     = 13  ,
  REQUEST       = 14  ,
  THANKS        = 15  ,
  ALLY_DEATH    = 16  ,
  CONGRATS      = 17  ,
  BOAST         = 18  ,
  HELP          = 19  ,
  EXTRA         = 20  ,
  UNKNOWN_2     = 21  ,
  UNKNOWN_3     = 22  ,
  SIEGE         = 23  ,
  NO_ATTACK_1   = 24  ,
  NO_ATTACK_2   = 25  ,
  NO_HELP_1     = 26  ,
  NO_HELP_2     = 27  ,
  NO_SENT       = 28  ,
  SENT          = 29  ,
  TEAM_WINNING  = 30  ,
  TEAM_LOSING   = 31  ,
  HELP_SENT     = 32  ,
  WILL_ATTACK   = 33  ,
}

--[[ Variables ]]--

local gmModule = nil
local textModule = nil
local aicModule = nil
local aivModule = nil
local filesModule = nil

local language = nil
local languageOverwrite = nil -- is {},  can be defined over the options to set a language for a specific AI

local resourceIds = {} -- contains table of tables with the structure aiIndex = {bigPicRes, smallPicRes}


--[[ Functions ]]--

-- returns new table containing the value references of the source, but with transformed keys
-- collisions in the transformed keys lead to overwrites
local function createTableWithTransformedKeys(source, transformer, recursive)
  local newTable = {}
  for key, value in pairs(source) do
    if recursive and type(value) == "table" then
      value = createTableWithTransformedKeys(value, transformer, recursive)
    end
    newTable[transformer(key)] = value
  end
  return newTable
end

-- source https://stackoverflow.com/a/33511163 (1. comment)
local function containsValue(tableToCheck, value)
  for key, val in pairs(tableToCheck) do
    if val == value then
      return true
    end
  end
  return false
end


local function getAiDataPath(aiName, dataPath)
  return string.format("%s/%s/%s", AI_ROOT_FOLDER, aiName, dataPath)
end

local function getAiDataPathWithLocale(aiName, locale, dataPath)
  if locale == nil then -- save against nil
    return getAiDataPath(aiName, dataPath)
  end
  return string.format("%s/%s/lang/%s/%s", AI_ROOT_FOLDER, aiName, locale, dataPath)
end


local function openFileForByteRead(path)
  local file, msg = io.open(path, "rb")
  if not file then
    return file, msg
  end
  return file
end

-- source: https://stackoverflow.com/a/4991602
local function doesFileExist(path)
  local file = openFileForByteRead(path)
  if file ~= nil then
    file:close()
    return true
  else
    return false
  end
end

local function loadByteDataFromFile(path)
  local file, msg = openFileForByteRead(path)
  if not file then
    return file, msg
  end
  local fileData = file:read("*all")
  file:close()
  return fileData
end

local function loadDataFromJSON(path)
  local data, msg = loadByteDataFromFile(path)
  if not data then
    return data, msg
  end

  local status, jsonOrErr = pcall(json.decode, json, data)
  if status then
    return jsonOrErr, nil
  else
    return nil, jsonOrErr
  end
end


-- checks locale path, else returns default
-- at the moment, the default language is also checked this way
local function getPathForLocale(aiName, locale, dataPath)
  local localePath = getAiDataPathWithLocale(aiName, locale, dataPath)
  if doesFileExist(localePath) then
    return localePath
  else
    return getAiDataPath(aiName, dataPath)
  end
end


local function freePortraitResource(index)
  if resourceIds[index] ~= nil then
    local oldResource = resourceIds[index]
    if oldResource.normal > -1 then
      gmModule.FreeGm1Resource(oldResource.normal)
    end
    if oldResource.small > -1 then
      gmModule.FreeGm1Resource(oldResource.small)
    end
    resourceIds[index] = nil -- removing resource id to prevent issues
  end
end

local function resetPortrait(index)
  gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + index, -1, -1)
  gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + index, -1, -1)
  freePortraitResource(index)
end

local function loadAndSetPortrait(indexToReplace, aiName)
  local normalPortraitPath = getAiDataPath(aiName, DATA_PATH.NORMAL_PORTRAIT)
  local smallPortraitPath = getAiDataPath(aiName, DATA_PATH.SMALL_PORTRAIT)

  local portraitResourceIds = {
    normal  = doesFileExist(normalPortraitPath) and gmModule.LoadResourceFromImage(normalPortraitPath) or -1,
    small   = doesFileExist(smallPortraitPath) and gmModule.LoadResourceFromImage(smallPortraitPath) or -1,
  }
   
  if portraitResourceIds.normal < 0 then
    log(WARNING, aiName .. " has no portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + indexToReplace, portraitResourceIds.normal, 0)
  end
  
  if portraitResourceIds.small < 0 then
    log(WARNING, aiName .. " has no small portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + indexToReplace, portraitResourceIds.small, 0)
  end

  freePortraitResource(indexToReplace)
  resourceIds[indexToReplace] = portraitResourceIds
end


local function getAiSkrimishLineIndex(lordId, lineId)
  return lordId * NUMBER_OF_SKRIMISH_LINES + lineId
end

local function getAiNamesLineIndex(lordId, lineId)
  local linesToSkipForLords = NUMBER_OF_TITLES
  if lineId > NAMES_AND_MENU_TEXT_ID.TITLE_8 then
    linesToSkipForLords = 1 -- because only 1 desc line
  elseif lineId >= NAMES_AND_MENU_TEXT_ID.AI_NAME then
    linesToSkipForLords = linesToSkipForLords + 1 -- because the name is there, making it 9 there
  end
  return AI_NAMES_AND_MENU_TEXT_ID_START + lineId + lordId * linesToSkipForLords
end

local function performTextSetBasedOnEnum(enum, source, aiIndex, linesIndexConstant, lineIndexGetter)
  source = source or {} -- to avoid error
  for lineName, lineId in pairs(enum) do
    local lineIndex = lineIndexGetter(aiIndex, lineId)
    textModule.SetText(linesIndexConstant, lineIndex, source[lineName]) -- nil will auto reset
  end
end

local function resetAiTexts(aiIndexToReset)
  performTextSetBasedOnEnum(SKRIMISH_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_SKRIMISH_TEXT, getAiSkrimishLineIndex)
  performTextSetBasedOnEnum(NAMES_AND_MENU_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_NAMES_AND_MENU_TEXT, getAiNamesLineIndex)
end

local function setAiTexts(aiIndexToReplace, aiName, aiLang)
  local linesPath = getPathForLocale(aiName, aiLang, DATA_PATH.TEXT)
  local lineData, msg = loadDataFromJSON(linesPath)
  
  if lineData == nil then
    log(WARNING, string.format("Unable to read lines file of AI '%s'. %s.", aiName, msg))
    return
  end
  
  local transformedIndexLineData = createTableWithTransformedKeys(lineData, string.upper)
  
  -- set skrimish lines
  performTextSetBasedOnEnum(SKRIMISH_TEXT_ID, transformedIndexLineData, aiIndexToReplace, INDEX_OF_AI_SKRIMISH_TEXT, getAiSkrimishLineIndex)
  
  -- create complete titles
  local aiNameStr = transformedIndexLineData.AI_NAME
  if aiNameStr then
    for i = 1, 8 do
      local title = transformedIndexLineData["TITLE_" .. i]
      if title then
        transformedIndexLineData["COMPLETE_TITLE_" .. i] = string.format("%s, %s", aiNameStr, title)
      end
    end
  end
  
  -- set names and description
  performTextSetBasedOnEnum(NAMES_AND_MENU_TEXT_ID, transformedIndexLineData, aiIndexToReplace, INDEX_OF_AI_NAMES_AND_MENU_TEXT, getAiNamesLineIndex)
end

-- TODO: AI names and descriptions


local function setAiPart(setFunc, resetFunc, shouldModify, dataPresent, aiPosition, ...)
  if shouldModify then
    if dataPresent then
      setFunc(aiPosition, ...)
    else
      resetFunc(aiPosition)
    end
  end
end

local function setAI(positionToReplace, aiName, control)
  if not containsValue(LORD_ID, positionToReplace) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end

  local meta, err = loadDataFromJSON(getAiDataPath(aiName, DATA_PATH.META))
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
  
  if meta.supportedLang ~= nil and not containsValue(meta.supportedLang, aiLang) then
    log(WARNING, string.format("Language '%s' is not supported. Using fallback.", aiLang))
    aiLang = meta.defaultLang -- may or may not be default folder
  end
  
  if meta.switched == nil then
    log(WARNING, string.format("Unable to set AI '%s'. No switch settings in meta file found.", aiName))
    return
  end
  
  
  -- all parts take care of their own reset, otherwise they are not useable on their own
  
  local finalControl = {
    binks = true,
    speech = true,
    aic = true,
    aiv = true,
    lord = true,
    startTroops = true,
    ["lines"] = true,
    portrait = true,
  }
  if control then
    for key, value in pairs(control) do
      finalControl[key] = value and finalControl[key]
    end
  end

  setAiPart(loadAndSetPortrait, resetPortrait, finalControl.portrait, meta.switched.portrait, positionToReplace, aiName)
  setAiPart(setAiTexts, resetAiTexts, finalControl.lines, meta.switched.lines, positionToReplace, aiName, aiLang)
end


-- resets everything
local function resetAI(positionToReset)
  if not containsValue(LORD_ID, positionToReset) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  resetPortrait(positionToReset)
  resetAiTexts(positionToReset)
end



--[[ Main Func ]]--

local exports = {}

exports.enable = function(self, moduleConfig, globalConfig)

  -- get modules for easier variable access
  gmModule = modules.gmResourceModifier
  textModule = modules.textResourceModifier
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