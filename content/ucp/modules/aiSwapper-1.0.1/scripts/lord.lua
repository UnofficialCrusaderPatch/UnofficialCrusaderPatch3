local util = require("scripts.util")

--[[ IDs and Constants ]]--

local DATA_PATH_CHARACTER = "character.json"

local LORD_TYPE_VANILLA = {
  [0]  = 0,
  [1]  = 0,
  [2]  = 0,
  [3]  = 0,
  [4]  = 1,
  [5]  = 1,
  [6]  = 1,
  [7]  = 0,
  [8]  = 0,
  [9]  = 0,
  [10] = 1,
  [11] = 1,
  [12] = 1,
  [13] = 0,
  [14] = 0,
  [15] = 0,
}

local LORD_DOT = {
  None   = 0,
  Blue   = { 1, 2, 3, 4, 5 },
  Yellow = { 6, 7, 8, 9, 10 },
}

local LORD_TYPE = {
  Europ = 0,
  Arab  = 1,
}

--[[ Variables ]]--

local vanillaLordStrength = {}

local currentLordType = {}
-- init
for lordId, lordType in pairs(LORD_TYPE_VANILLA) do
  currentLordType[lordId] = lordType
end


--[[ Addresses and Hooks ]]--

-- looks like it is squares + strength in percent... first is player, than AI
local ptrLordStrengthArray = util.getAddress(
  "83 c0 04 3d ? ? ? ? 7c f2 33 c0 c2",
  "aiSwapper.lord", "'%s' was unable to find the start of the lord strength array.",
  function(foundAddress) return core.readInteger(foundAddress + 4) end
)

local ptrToLordTypeDetour = util.getAddress(
  "83 c0 fe 83 f8 0f 77 13",
  "aiSwapper.lord", "'%s' was unable to find the position to detour the lord type function."
)

-- first add a ret
core.writeCode(
  ptrToLordTypeDetour,
  { 0xc2, 0x04, 0x00 } -- ret 0x4
)
-- then detour
core.detourCode(function(registers)
  registers.EAX = currentLordType[registers.EAX - 2]
  return registers
end, ptrToLordTypeDetour, 8)

-- get vanillaLordStrength

for i = 0, 16 do -- 0 is player in this case
  local indexPtr = i * 8
  vanillaLordStrength[i - 1] = {
    dot = core.readInteger(ptrLordStrengthArray + indexPtr),
    strength = core.readInteger(ptrLordStrengthArray + indexPtr + 4)
  }
end

--[[ Functions ]]--

local function round(x)
  local modNum = x >= 0.0 and 1 or -1
  local n = x + 0.5 * modNum
  return n - n % modNum
end


local function resolveStrength(lordStrength)
  if lordStrength == nil or lordStrength < 0 then
    return nil
  end
  return round(lordStrength * 100)
end

local function resolveDot(color, count)
  if color == nil or count == nil or LORD_DOT[color] == nil or count < 0 or count > 5 then
    return nil
  end

  if color == "None" or count == 0 then
    return 0
  end
  return LORD_DOT[color][count]
end

local function resolveType(lordType)
  if lordType then
    return LORD_TYPE[lordType]
  end
  return nil
end


local function setLordType(index, lordTypeIndex)
  currentLordType[index] = lordTypeIndex
end

local function setLordDotAndStrength(index, dot, strength)
  local indexPtr = (index + 1) * 8
  core.writeInteger(ptrLordStrengthArray + indexPtr, dot)
  core.writeInteger(ptrLordStrengthArray + indexPtr + 4, strength)
end


local function resetLord(indexToReset)
  setLordType(indexToReset, LORD_TYPE_VANILLA[indexToReset])
  local vanillaStrength = vanillaLordStrength[indexToReset]
  setLordDotAndStrength(indexToReset, vanillaStrength.dot, vanillaStrength.strength)
end

local function setLord(indexToReplace, pathroot, aiName, loadedCharacterJson)
  if loadedCharacterJson == nil then
    local loadedJson, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, DATA_PATH_CHARACTER))
    if not loadedJson then
      log(WARNING, string.format("Could not load character file of AI '%s': %s", aiName, err))
      return
    end
    loadedCharacterJson = loadedJson
  end

  if not loadedCharacterJson.lord then
    log(WARNING, string.format("Could not load lord data of AI '%s': No lord data found.", aiName))
    return
  end

  local lordType = resolveType(loadedCharacterJson.lord.Type)
  if not lordType then
    log(WARNING,
      string.format("Could not set type of AI lord '%s': Wrong value: %s", aiName, loadedCharacterJson.lord.Type))
    lordType = LORD_TYPE_VANILLA[indexToReplace]
  end

  local lordDot = resolveDot(loadedCharacterJson.lord.DotColour, loadedCharacterJson.lord.DotCount)
  if not lordDot then
    log(WARNING, string.format("Could not set dot of AI lord '%s': At least one wrong value: %s, %d", aiName,
      loadedCharacterJson.lord.DotColour, loadedCharacterJson.lord.DotCount))
    lordDot = vanillaLordStrength[indexToReplace].dot
  end

  local lordStrength = resolveStrength(loadedCharacterJson.lord.StrengthMultiplier)
  if not lordStrength then
    log(WARNING, string.format("Could not set strength of AI lord '%s': Wrong value: %f", aiName,
      loadedCharacterJson.lord.StrengthMultiplier))
    lordDot = vanillaLordStrength[indexToReplace].strength
  end

  setLordType(indexToReplace, lordType)
  setLordDotAndStrength(indexToReplace, lordDot, lordStrength)

  return loadedCharacterJson
end


return {
  resetLord = resetLord,
  setLord   = setLord,
}
