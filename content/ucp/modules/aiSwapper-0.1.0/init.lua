

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


local NUMBER_OF_LINES = 34
local INDEX_OF_AI_TEXT = 231

-- missing: description and AI names
local TEXT_ID = {
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


local function setAiTextLine(lineIndex, text)
  textModule.SetText(INDEX_OF_AI_TEXT, lineIndex, text) -- nil will reset it
end

local function getAiLineIndex(lordId, lineId)
  return lordId * NUMBER_OF_LINES + lineId
end

local function resetAiTexts(aiIndexToReset)
  local resetStart = getAiLineIndex(aiIndexToReset, 0)
  for i = resetStart, resetStart + NUMBER_OF_LINES - 1 do
    setAiTextLine(i, nil)
  end
end

local function setAiTexts(aiIndexToReplace, aiName, aiLang)
  local linesPath = getPathForLocale(aiName, aiLang, DATA_PATH.TEXT)
  local lineData, msg = loadDataFromJSON(linesPath)
  
  if lineData == nil then
    log(WARNING, string.format("Unable to read lines file of AI '%s'. %s.", aiName, msg))
    return
  end
  
  local transformedIndexLineData = {}
  for lineName, text in pairs(lineData) do
    transformedIndexLineData[string.upper(lineName)] = text -- identifier to uppercase
  end
  
  for lineName, lineId in pairs(TEXT_ID) do
    local lineIndex = getAiLineIndex(aiIndexToReplace, lineId)
    setAiTextLine(lineIndex, transformedIndexLineData[lineName]) -- nil will auto reset
  end
end

-- TODO: AI names and descriptions




local function setAI(positionToReplace, aiName)
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
  
  -- will only be true if true, nil will also be false
  if meta.switched.portrait then
    loadAndSetPortrait(positionToReplace, aiName)
  end

  if meta.switched.lines then
    setAiTexts(positionToReplace, aiName, aiLang)
  end
  

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