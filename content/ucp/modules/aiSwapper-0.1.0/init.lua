

--[[ IDs and Constants ]]--

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
}

--[[ Variables ]]--

local gmModule = nil
local textModule = nil
local aicModule = nil
local aivModule = nil
local filesModule = nil

local language = nil
local languageOverwrite = {} -- can be defined over the options to set a language for a specific AI

local resourceIds = {} -- contains table of tables with the structure aiIndex = {bigPicRes, smallPicRes}


--[[ Functions ]]--

local function getAiDataPath(aiName, dataPath)
  return string.format("ucp/resources/%s/%s", aiName, dataPath)
end

local function getAiDataPathWithLocale(aiName, locale, dataPath)
  return string.format("ucp/resources/%s/lang/%s/%s", aiName, locale, dataPath)
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
  return json:decode(fileData)
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
      gmModule.FreeResource(oldResource.normal)
    end
    if oldResource.small > -1 then
      gmModule.FreeResource(oldResource.small)
    end
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
    log(WARN, aiName .. " has no portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + indexToReplace, portraitResourceIds.normal, 0)
  end
  
  if portraitResourceIds.small < 0 then
    log(WARN, aiName .. " has no small portrait.")
  else
    gmModule.SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + indexToReplace, portraitResourceIds.small, 0)
  end
  
  freePortraitResource(indexToReplace)
  resourceIds[indexToReplace] = portraitResourceIds
end








local function setAI(positionToReplace, aiName)

  -- check if file exists somehow?
  
  

end


local function resetAI(positionToReset)
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

end

exports.disable = function(self, moduleConfig, globalConfig) error("not implemented") end

return exports