local util = require("scripts.util")
local helper = require("scripts.helperWrapper")
local enums = require("scripts.enums")


--[[ IDs and Constants ]]--

local DATA_PATH_BINKS = "binks"
local DATA_PATH_MAPPING_FILE = "mapping.json"

local SKRIMISH_BINK_ID = enums.SKRIMISH_MESSAGE_ID


--[[ Functions ]]--

local function performBinkSet(aiIndex, source)
  source = source or {}                               -- to avoid error
  for binkName, binkId in pairs(SKRIMISH_BINK_ID) do
    helper.SetBink(aiIndex, binkId, source[binkName]) -- nil will auto reset
  end
end

local function resetAiBinks(aiIndexToReset)
  performBinkSet(aiIndexToReset + 1, nil)
end

local function setAiBinks(aiIndexToReplace, pathroot, aiName, aiLang)
  local mappingPath = util.getPathForLocale(pathroot, aiLang,
    string.format("%s/%s", DATA_PATH_BINKS, DATA_PATH_MAPPING_FILE))
  local mappingData, msg = util.loadDataFromJSON(mappingPath)

  if mappingData == nil then
    log(WARNING, string.format("Unable to read bink mappings file of AI '%s'. %s.", aiName, msg))
    return
  end

  local binkRootPath = string.gsub(mappingPath, "/" .. DATA_PATH_MAPPING_FILE, "")
  local transformedIndexMappingData = util.createTableWithTransformedKeys(mappingData, string.upper)
  for typeName, binkPath in pairs(transformedIndexMappingData) do
    local completeBinkPath = string.format("%s/%s", binkRootPath, binkPath)
    if util.doesFileExist(completeBinkPath) then
      transformedIndexMappingData[typeName] = completeBinkPath
    else
      log(WARNING, string.format("Problems with bink file of AI '%s'. '%s' does not exist.", aiName, completeBinkPath))
      transformedIndexMappingData[typeName] = nil
    end
  end
  performBinkSet(aiIndexToReplace + 1, transformedIndexMappingData) -- index + 1, because cpp module uses proper start value (Rat = 1)
end


return {
  resetAiBinks = resetAiBinks,
  setAiBinks   = setAiBinks,
}
