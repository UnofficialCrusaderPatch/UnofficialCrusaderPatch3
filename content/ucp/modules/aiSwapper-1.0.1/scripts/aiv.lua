local util = require("scripts.util")

local aivModule = modules.aivloader


--[[ IDs and Constants ]]--

local DATA_PATH_AIVS = "aiv"
local DATA_PATH_MAPPING_FILE = "mapping.json"

local CASTLE_ID_PATTERN = "CASTLE_%d"
local CASTLE_FIRST_ID = 1
local CASTLE_LAST_ID = 8


--[[ Functions ]]--

local function resetAIV(indexToReset)
  aivModule:resetAllAIVForAi(indexToReset)
end

local function setAIV(aiIndexToReplace, pathroot, aiName)
  local mappingPath = util.getAiDataPath(pathroot, string.format("%s/%s", DATA_PATH_AIVS, DATA_PATH_MAPPING_FILE))
  local mappingData, msg = util.loadDataFromJSON(mappingPath)

  if mappingData == nil then
    log(WARNING, string.format("Unable to read aiv mappings file of AI '%s'. %s.", aiName, msg))
    return
  end

  local aivRootPath = string.gsub(mappingPath, "/" .. DATA_PATH_MAPPING_FILE, "")
  local transformedIndexMappingData = util.createTableWithTransformedKeys(mappingData, string.upper)

  local castlesToSet = {}
  for i = CASTLE_FIRST_ID, CASTLE_LAST_ID do
    local castleId = string.format(CASTLE_ID_PATTERN, i)
    local aivPath = transformedIndexMappingData[castleId]
    if not aivPath then
      castlesToSet[i] = "" -- disables castle
    else
      local completeAIVPath = string.format("%s/%s", aivRootPath, aivPath)
      if util.doesFileExist(completeAIVPath) then
        castlesToSet[i] = completeAIVPath
      else
        log(WARNING, string.format("Problems with aiv file of AI '%s'. '%s' does not exist.", aiName, completeAIVPath))
        castlesToSet[i] = "" -- disables castle
      end
    end
  end
  aivModule:setMultipleAIVForAi(aiIndexToReplace, castlesToSet)
end

return {
  resetAIV = resetAIV,
  setAIV   = setAIV,
}
