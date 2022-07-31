

--[[ IDs and Constants ]]--

local AI_ROOT_FOLDER = "ucp/resources/ai"

local GM_DATA = {
  GM_INDEX                  = 46    ,
  FIRST_ICON_INDEX          = 522   ,
  FIRST_SMALL_ICON_INDEX    = 700   ,
}

local LORD_ID = {
  RAT         = 1,
  SNAKE       = 2,
  PIG         = 3,
  Wolf        = 4,
  SALADIN     = 5,
  CALIPH      = 6,
  SULTAN      = 7,
  RICHARD     = 8,
  FREDERICK   = 9,        
  PHILLIP     = 10,
  WAZIR       = 11,
  EMIR        = 12,
  NIZAR       = 13,
  SHERIFF     = 14,
  MARSHAL     = 15,
  ABBOT       = 16,
}

local DATA_PATH = {
  NORMAL_PORTRAIT     = "portrait.png",
  SMALL_PORTRAIT      = "portrait_small.png",
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
  return json:decode(data)
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
  local cppIndex = index - 1 -- because lua starts at 1
  gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + cppIndex, -1, -1)
  gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + cppIndex, -1, -1)
  freePortraitResource(index)
end

local function loadAndSetPortrait(indexToReplace, aiName)
  local cppIndex = indexToReplace - 1 -- because lua starts at 1
  
  local normalPortraitPath = getAiDataPath(aiName, DATA_PATH.NORMAL_PORTRAIT)
  local smallPortraitPath = getAiDataPath(aiName, DATA_PATH.SMALL_PORTRAIT)

  local portraitResourceIds = {
    normal  = doesFileExist(normalPortraitPath) and gmModule.LoadResourceFromImage(normalPortraitPath) or -1,
    small   = doesFileExist(smallPortraitPath) and gmModule.LoadResourceFromImage(smallPortraitPath) or -1,
  }
   
  if portraitResourceIds.normal < 0 then
    log(WARNING, aiName .. " has no portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + cppIndex, portraitResourceIds.normal, 0)
  end
  
  if portraitResourceIds.small < 0 then
    log(WARNING, aiName .. " has no small portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + cppIndex, portraitResourceIds.small, 0)
  end

  resourceIds[indexToReplace] = portraitResourceIds
end






-- resets everything
local function resetAI(positionToReset)
  if not containsValue(LORD_ID, positionToReset) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end
  
  resetPortrait(positionToReset)
  
end


local function setAI(positionToReplace, aiName)
  if not containsValue(LORD_ID, positionToReplace) then
    log(WARNING, string.format("Unable to set AI '%s'. Invalid lord index.", aiName))
    return
  end

  local meta, err = loadDataFromJSON(getAiDataPath(aiName, "meta.json"))
  if meta == nil then
    log(WARNING, string.format("Unable to set AI '%s'. No meta file found.", aiName))
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
  
  -- resets everything; while more to do, it will make sure that at least no other AI dirties the result
  resetAI(positionToReplace)
  
  -- will only be true if true, nil will also be false
  if meta.switched.portrait then
    loadAndSetPortrait(positionToReplace, aiName)
  end

  
  

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