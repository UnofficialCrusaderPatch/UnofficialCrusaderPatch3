

-- get addresses

local setMessageForAiFuncStart = core.AOBScan("55 56 8b 74 24 10 8d 46 ff 83 f8 0f", 0x400000)
if setMessageForAiFuncStart == nil then
  print("'aiSwapperHelper' was unable to find the start of the ai message function.")
  error("'aiSwapperHelper' can not be initialized.")
end

-- all ptr are relative to the function, right?

local prepareAiMsgFunc = core.readInteger(setMessageForAiFuncStart + 0x3B) + setMessageForAiFuncStart + 0x3A + 5 -- relative call, so we need to reverse this
local messageFromArray = core.readInteger(setMessageForAiFuncStart + 0x20)
local aiBinkArray = core.readInteger(setMessageForAiFuncStart + 0x54)
local aiSfxArray = core.readInteger(setMessageForAiFuncStart + 0x4D)

local menuAiSelectSfxFuncStart = core.AOBScan("8b 4c 24 04 83 f9 10 77 27", 0x400000)
if menuAiSelectSfxFuncStart == nil then
  print("'aiSwapperHelper' was unable to find the start of the ai menu select sfx function.")
  error("'aiSwapperHelper' can not be initialized.")
end

local playSFXFunc = core.readInteger(menuAiSelectSfxFuncStart + 0x2C) + menuAiSelectSfxFuncStart + 0x2B + 5 -- relative call, so we need to reverse this
local playSFXFuncThisPtr = core.readInteger(menuAiSelectSfxFuncStart + 0x27)

local binkAndSfxPlayFuncStart = core.AOBScan("53 55 8b 6c 24 0c 56 8b f1 8d 5e 0c", 0x400000)
if binkAndSfxPlayFuncStart == nil then
  print("'aiSwapperHelper' was unable to find the start of the bink and sfx play func.")
  error("'aiSwapperHelper' can not be initialized.")
end


-- handle weird way of manipulating the path strings

local function getStringAddressFromString(addressString)
  if addressString:len() > 0 then
    if not addressString.find(addressString, "%D") then -- check if something else than numbers are in, and then if not
      return tonumber(addressString)
    end
  end
  
  return nil
end


local playBinkAndSfxFunc = nil
playBinkAndSfxFunc = core.hookCode(function(this, binkPtr, soundPtr)
  local binkStr = core.readString(binkPtr)
  local soundStr = core.readString(soundPtr)
  
  local realBinkPtr = getStringAddressFromString(binkStr)
  if not realBinkPtr then
    realBinkPtr = binkPtr
  end
  
  local realSoundPtr = getStringAddressFromString(soundStr)
  if not realSoundPtr then
    realSoundPtr = soundPtr
  end
  
  print(core.readString(realBinkPtr))
  print(core.readString(realSoundPtr))
  
  playBinkAndSfxFunc(this, realBinkPtr, realSoundPtr)
end, binkAndSfxPlayFuncStart, 3, 1, 7)

local requireTable = require("aiSwapperHelper.dll") -- loads the dll in memory and runs luaopen_aiSwapperHelper


-- write the jmp to the own function
core.writeCode(
  setMessageForAiFuncStart,
  {0xE9, requireTable.funcAddress_DetouredSetMessageForAi - setMessageForAiFuncStart - 5}  -- call to func
)

-- set func address
core.writeCode(
  requireTable.address_PrepareAiMsgFunc,
  {prepareAiMsgFunc}
)

-- set all array addresses
core.writeCode(
  requireTable.address_AMessageFromArray,
  {messageFromArray}
)
core.writeCode(
  requireTable.address_AiBinkArray,
  {aiBinkArray}
)
core.writeCode(
  requireTable.address_AiSfxArray,
  {aiSfxArray}
)

-- write the jmp to the own function
core.writeCode(
  menuAiSelectSfxFuncStart,
  {0xE9, requireTable.funcAddress_PlayMenuSelectSFX - menuAiSelectSfxFuncStart - 5}  -- call to func
)

-- set func address
core.writeCode(
  requireTable.address_PlaySFXFunc,
  {playSFXFunc}
)

-- write ptr
core.writeCode(
  requireTable.address_ObjPtrForPlaySFX,
  {playSFXFuncThisPtr}
)



return {
  SetMessageFrom = requireTable.lua_SetMessageFrom,
  SetSfx = requireTable.lua_SetSfx,
  SetBink = requireTable.lua_SetBink,
}