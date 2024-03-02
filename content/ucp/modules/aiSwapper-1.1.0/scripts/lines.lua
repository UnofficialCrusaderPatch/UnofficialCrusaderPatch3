-- NOTE: Titles in-game are backed and can currently not be changed.
-- NOTE: Pointer to certain text parts are stored, so during this phase switches might cause nullptr access. (At least non-sense text.)
--  - tried to fix it with aiSwapperHelper

local util = require("scripts.util")
local enums = require("scripts.enums")

local textModule = modules.textResourceModifier


--[[ IDs and Constants ]]--

local DATA_PATH_TEXT = "lines.json"

local NUMBER_OF_SKRIMISH_LINES = 34
local INDEX_OF_AI_NAMES_AND_MENU_TEXT = 79
local AI_NAMES_AND_MENU_TEXT_ID_START = 111

local INDEX_OF_AI_SKRIMISH_TEXT = 231
local NUMBER_OF_TITLES = 8


local NAMES_AND_MENU_TEXT_ID = {
  COMPLETE_TITLE_1 = 0,
  COMPLETE_TITLE_2 = 1,
  COMPLETE_TITLE_3 = 2,
  COMPLETE_TITLE_4 = 3,
  COMPLETE_TITLE_5 = 4,
  COMPLETE_TITLE_6 = 5,
  COMPLETE_TITLE_7 = 6,
  COMPLETE_TITLE_8 = 7,
  AI_NAME          = 128,
  TITLE_1          = 129,
  TITLE_2          = 130,
  TITLE_3          = 131,
  TITLE_4          = 132,
  TITLE_5          = 133,
  TITLE_6          = 134,
  TITLE_7          = 135,
  TITLE_8          = 136,
  DESCRIPTION      = 274,
}

local SKRIMISH_TEXT_ID = enums.SKRIMISH_MESSAGE_ID


--[[ Functions ]]--

local function getAiSkrimishLineIndex(lordId, lineId)
  return lordId * NUMBER_OF_SKRIMISH_LINES + lineId
end

local function getAiNamesLineIndex(lordId, lineId)
  local linesToSkipForLords = NUMBER_OF_TITLES
  if lineId > NAMES_AND_MENU_TEXT_ID.TITLE_8 then
    linesToSkipForLords = 1                       -- because only 1 desc line
  elseif lineId >= NAMES_AND_MENU_TEXT_ID.AI_NAME then
    linesToSkipForLords = linesToSkipForLords + 1 -- because the name is there, making it 9 there
  end
  return AI_NAMES_AND_MENU_TEXT_ID_START + lineId + lordId * linesToSkipForLords
end

local function performTextSetBasedOnEnum(enum, source, aiIndex, linesIndexConstant, lineIndexGetter)
  source = source or {} -- to avoid error
  for lineName, lineId in pairs(enum) do
    local lineIndex = lineIndexGetter(aiIndex, lineId)
    textModule:SetText(linesIndexConstant, lineIndex, source[lineName]) -- nil will auto reset
  end
end

local function resetAiTexts(aiIndexToReset)
  performTextSetBasedOnEnum(SKRIMISH_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_SKRIMISH_TEXT, getAiSkrimishLineIndex)
  performTextSetBasedOnEnum(NAMES_AND_MENU_TEXT_ID, nil, aiIndexToReset, INDEX_OF_AI_NAMES_AND_MENU_TEXT,
    getAiNamesLineIndex)
end

local function setAiTexts(aiIndexToReplace, pathroot, aiName, aiLang)
  local linesPath = util.getPathForLocale(pathroot, aiLang, DATA_PATH_TEXT)
  local lineData, msg = util.loadDataFromJSON(linesPath)

  if lineData == nil then
    log(WARNING, string.format("Unable to read lines file of AI '%s'. %s.", aiName, msg))
    return
  end

  local transformedIndexLineData = util.createTableWithTransformedKeys(lineData, string.upper)

  -- set skrimish lines
  performTextSetBasedOnEnum(SKRIMISH_TEXT_ID, transformedIndexLineData, aiIndexToReplace, INDEX_OF_AI_SKRIMISH_TEXT,
    getAiSkrimishLineIndex)

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
  performTextSetBasedOnEnum(NAMES_AND_MENU_TEXT_ID, transformedIndexLineData, aiIndexToReplace,
    INDEX_OF_AI_NAMES_AND_MENU_TEXT, getAiNamesLineIndex)
end


return {
  resetAiTexts = resetAiTexts,
  setAiTexts   = setAiTexts,
}
