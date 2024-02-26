-- starting troops get loaded for example here: SHC 0044211c

local util = require("scripts.util")

--[[ IDs and Constants ]]--

local DATA_PATH_CHARACTER = "character.json"

local START_TROOPS_INDEX = {
  EuropArcher   = 0,
  Crossbowman   = 1,
  Spearman      = 2,
  Pikeman       = 3,
  Maceman       = 4,
  Swordsman     = 5,
  Knight        = 6,
  Unknown       = 7,     -- missing 7? -> nothing spawns? -> keep it supported, maybe someone wants to test something
  Engineer      = 8,
  Monk          = 9,
  ArabArcher    = 10,
  Slave         = 11,
  Slinger       = 12,
  Assassin      = 13,
  HorseArcher   = 14,
  ArabSwordsman = 15,
  FireThrower   = 16,
  FireBallista  = 17,    -- unmanned, maybe it is not used? Why no catapults?

  --[[
    - spawns two waves max (18), using the "default" start troops at least in normal match
    - nature (europe, arab) of the troops in singleplayer is those of the player lord
    - they do not count separately, having more than 18 spawns a bugged archer
    NOT TESTED: other modes, multiplayer, leave it at that
  ]] --
  --SimpleStart1    = 18 ,
  --SimpleStart2    = 19 ,
}
-- I am kinda wondering, if some of the values are actually not used as int? The lack of catapults...

local GAME_MODE_INDEX = {
  normal     = 0,
  crusader   = 1,
  deathmatch = 2,
}


--[[ Variables ]]--

local vanillaStartTroops = {}


--[[ Addresses and Hooks ]]--

local ptrStartTroopsArray = util.getAddress(
  "8d bf ? ? ? ? c7 44 24 1c 14",
  "aiSwapper.troops", "'%s' was unable to find the start of the start troops array.",
  function(foundAddress) return core.readInteger(foundAddress + 2) + 0x140 end -- uses a fixed offset
)

local function getModeAddress(aiIndex, modeIndex)
  return ptrStartTroopsArray + (aiIndex * 60 + modeIndex * 20) * 4
end


-- load vanilla values
for aiIndex = 0, 15 do
  vanillaStartTroops[aiIndex] = {}
  for modeName, modeIndex in pairs(GAME_MODE_INDEX) do
    local startTroopInts = {}
    local startAddr = getModeAddress(aiIndex, modeIndex)
    for startTroopsIndex = 0, 19 do
      startTroopInts[startTroopsIndex] = core.readInteger(startAddr + startTroopsIndex * 4)
    end
    vanillaStartTroops[aiIndex][modeIndex] = startTroopInts
  end
end


--[[ Functions ]]--

local function setStartTroopsForMode(aiIndex, modeIndex, valueTable)
  local valueTable = valueTable or vanillaStartTroops[aiIndex][modeIndex]
  local startAddress = getModeAddress(aiIndex, modeIndex)
  for index, value in pairs(valueTable) do
    core.writeInteger(startAddress + index * 4, value)
  end
end

local function resetStartTroops(indexToReset)
  setStartTroopsForMode(indexToReset, GAME_MODE_INDEX.normal, nil)
  setStartTroopsForMode(indexToReset, GAME_MODE_INDEX.crusader, nil)
  setStartTroopsForMode(indexToReset, GAME_MODE_INDEX.deathmatch, nil)
end

local function resolveValueTable(source)
  local valueTable = {
    [0] = 0,
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
    [7] = 0,
    [8] = 0,
    [9] = 0,
    [10] = 0,
    [11] = 0,
    [12] = 0,
    [13] = 0,
    [14] = 0,
    [15] = 0,
    [16] = 0,
    [17] = 0,
    [18] = 0,
    [19] = 0,
  }

  for troopName, troopValue in pairs(source) do
    local troopIndex = START_TROOPS_INDEX[troopName]
    if troopIndex == nil then
      log(WARNING, string.format("Unable to resolve start troop name: '%s'. Ignored.", troopName))
    else
      valueTable[troopIndex] = troopValue
    end
  end

  return valueTable
end


local function setStartTroops(indexToReplace, pathroot, aiName, loadedCharacterJson)
  if loadedCharacterJson == nil then
    local loadedJson, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, DATA_PATH_CHARACTER))
    if not loadedJson then
      log(WARNING, string.format("Could not load character file of AI '%s': %s", aiName, err))
      return
    end
    loadedCharacterJson = loadedJson
  end

  if not loadedCharacterJson.startTroops then
    log(WARNING, string.format("Could not load start troops data of AI '%s': No troop data found.", aiName))
    return
  end

  for modeName, modeTable in pairs(loadedCharacterJson.startTroops) do
    local modeIndex = GAME_MODE_INDEX[modeName]
    if modeIndex == nil then
      log(WARNING, string.format("Unable to resolve start troop game mode: '%s'. Ignored.", modeName))
    else
      setStartTroopsForMode(indexToReplace, modeIndex, resolveValueTable(modeTable))
    end
  end

  return loadedCharacterJson
end


return {
  resetStartTroops = resetStartTroops,
  setStartTroops   = setStartTroops,
}
