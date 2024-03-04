local util = require("scripts.util")
local helper = require("scripts.helperWrapper")
local enums = require("scripts.enums")


--[[ IDs and Constants ]]--

local DATA_PATH_SPEECH = "speech"
local DATA_PATH_MAPPING_FILE = "mapping.json"

local MESSAGE_FROM_NAME = "MESSAGE_FROM"
local SKRIMISH_SFX_ID = enums.SKRIMISH_MESSAGE_ID


--[[ Functions ]]--

local function performSfxSet(aiIndex, source)
  source = source or {}                            -- to avoid error
  for sfxName, sfxId in pairs(SKRIMISH_SFX_ID) do
    helper.SetSfx(aiIndex, sfxId, source[sfxName]) -- nil will auto reset
  end
  helper.SetMessageFrom(aiIndex, source[MESSAGE_FROM_NAME])
end

local function resetAiSfx(aiIndexToReset)
  local dllAiIndex = aiIndexToReset + 1
  performSfxSet(dllAiIndex, nil)
  helper.SetMessageFrom(dllAiIndex, nil)

  if aiIndexToReset == enums.LORD_ID.RAT then
    helper.SetRatComplain(true)
  elseif aiIndexToReset == enums.LORD_ID.SULTAN then
    helper.SetSultanComplain(true)
  end
end

local function setAiSfx(aiIndexToReplace, pathroot, aiName, aiLang)
  local mappingPath = util.getPathForLocale(pathroot, aiLang,
    string.format("%s/%s", DATA_PATH_SPEECH, DATA_PATH_MAPPING_FILE))
  local mappingData, msg = util.loadDataFromJSON(mappingPath)

  if mappingData == nil then
    log(WARNING, string.format("Unable to read sfx mappings file of AI '%s'. %s.", aiName, msg))
    return
  end

  local sfxRootPath = string.gsub(mappingPath, "/" .. DATA_PATH_MAPPING_FILE, "")
  local transformedIndexMappingData = util.createTableWithTransformedKeys(mappingData, string.upper)
  for typeName, sfxPath in pairs(transformedIndexMappingData) do
    local completeSfxPath = string.format("%s/%s", sfxRootPath, sfxPath)
    if util.doesFileExist(completeSfxPath) then
      transformedIndexMappingData[typeName] = completeSfxPath
    else
      log(WARNING, string.format("Problems with sfx file of AI '%s'. '%s' does not exist.", aiName, completeSfxPath))
      transformedIndexMappingData[typeName] = nil
    end
  end
  performSfxSet(aiIndexToReplace + 1, transformedIndexMappingData) -- index + 1, because cpp module uses proper start value (Rat = 1)

  -- this ignores if it is just a modified Rat, but I think this is ok
  if aiIndexToReplace == enums.LORD_ID.RAT then
    helper.SetRatComplain(false)
  elseif aiIndexToReplace == enums.LORD_ID.SULTAN then
    helper.SetSultanComplain(false)
  end
end


return {
  resetAiSfx = resetAiSfx,
  setAiSfx   = setAiSfx,
}
