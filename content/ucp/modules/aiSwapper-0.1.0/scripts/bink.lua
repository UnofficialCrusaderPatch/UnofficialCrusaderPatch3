
local util = require("scripts.util")
local helper = require("scripts.helperWrapper")
local enums = require("scripts.enums")


--[[ IDs and Constants ]]--

local DATA_PATH_REVERSE = "../../" -- returning from fx/speech
local DATA_PATH_BINKS = "binks"
local DATA_PATH_MAPPING_FILE = "mapping.json"

local SKRIMISH_BINK_ID = enums.SKRIMISH_MESSAGE_ID

--[[ Variables ]]--

--[[ Functions ]]--

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

local function resetAiBinks(aiIndexToReset)
  performTextSetBasedOnEnum(SKRIMISH_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_SKRIMISH_TEXT, getAiSkrimishLineIndex)
  performTextSetBasedOnEnum(NAMES_AND_MENU_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_NAMES_AND_MENU_TEXT, getAiNamesLineIndex)
end

local function setAiBinks(aiIndexToReplace, pathroot, aiName, aiLang)
  local linesPath = util.getPathForLocale(pathroot, aiName, aiLang, DATA_PATH_TEXT)
  local lineData, msg = util.loadDataFromJSON(linesPath)
  
  if lineData == nil then
    log(WARNING, string.format("Unable to read lines file of AI '%s'. %s.", aiName, msg))
    return
  end
  
  local transformedIndexLineData = util.createTableWithTransformedKeys(lineData, string.upper)
  
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



return {
  resetAiBinks  = resetAiBinks,
  setAiBinks    = setAiBinks,
}