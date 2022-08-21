
local util = require("scripts.util")

--[[ IDs and Constants ]]--

local LORD_TYPE_VANILLA = {
  [0 ]   =   0,
  [1 ]   =   0,
  [2 ]   =   0,
  [3 ]   =   0,
  [4 ]   =   1,
  [5 ]   =   1,
  [6 ]   =   1,
  [7 ]   =   0,
  [8 ]   =   0,
  [9 ]   =   0,
  [10]   =   1,
  [11]   =   1,
  [12]   =   1,
  [13]   =   0,
  [14]   =   0,
  [15]   =   0,
}


--[[ Variables ]]--

local currentLordType = {}
-- init
for lordId, lordType in pairs(LORD_TYPE_VANILLA) do
  currentLordType[lordId] = lordType
end


--[[ Addresses and Hooks ]]--

-- looks like it is squares + strength in percent... first is player, than AI
local ptrLordStrengthArray = core.AOBScan("83 c0 04 3d ? ? ? ? 7c f2 33 c0 c2", 0x400000)
if ptrLordStrengthArray == nil then
  log(ERROR, "'aiSwapper' was unable to find the start of the lord strength array.")
  error("'aiSwapper' can not be initialized.")
end
ptrLordStrengthArray = core.readInteger(ptrLordStrengthArray + 4)

local ptrToLordTypeDetour = core.AOBScan("83 c0 fe 83 f8 0f 77 13", 0x400000)
if ptrToLordTypeDetour == nil then
  log(ERROR, "'aiSwapper' was unable to find the position to detour the lord type function.")
  error("'aiSwapper' can not be initialized.")
end

-- first add a ret
core.writeCode(
  ptrToLordTypeDetour,
  {0xc2, 0x04, 0x00}  -- ret 0x4
)
-- then detour
core.detourCode(function(registers)
  registers.EAX = currentLordType[registers.EAX - 2]
  return registers
end, ptrToLordTypeDetour, 8)


--[[ Functions ]]--


return {
}