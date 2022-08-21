
-- get addresses

local setMessageForAiFuncStart = core.AOBScan("55 56 8b 74 24 10 8d 46 ff 83 f8 0f", 0x400000)
if setMessageForAiFuncStart == nil then
  log(ERROR, "'aiSwapperHelper' was unable to find the start of the ai message function.")
  error("'aiSwapperHelper' can not be initialized.")
end

-- all ptr are relative to the function, right?

local prepareAiMsgFunc = core.readInteger(setMessageForAiFuncStart + 0x3B) + setMessageForAiFuncStart + 0x3A + 5 -- relative call, so we need to reverse this
local messageFromArray = core.readInteger(setMessageForAiFuncStart + 0x20)
local aiBinkArray = core.readInteger(setMessageForAiFuncStart + 0x54)
local aiSfxArray = core.readInteger(setMessageForAiFuncStart + 0x4D)

local menuAiSelectSfxFuncStart = core.AOBScan("8b 4c 24 04 83 f9 10 77 27", 0x400000)
if menuAiSelectSfxFuncStart == nil then
  log(ERROR, "'aiSwapperHelper' was unable to find the start of the ai menu select sfx function.")
  error("'aiSwapperHelper' can not be initialized.")
end

local playSFXFunc = core.readInteger(menuAiSelectSfxFuncStart + 0x2C) + menuAiSelectSfxFuncStart + 0x2B + 5 -- relative call, so we need to reverse this
local playSFXFuncThisPtr = core.readInteger(menuAiSelectSfxFuncStart + 0x27)



-- handle weird way of manipulating the path strings

local SFX_BASE = "fx\\speech\\"
local BINK_BASE = "binks\\"

local ratComplain = true
local sultanComplain = true

local function getPathFromStringAddress(removePattern, addressString)
  local testString = string.gsub(addressString, removePattern, "")
  if testString:len() > 0 then
    if not testString.find(testString, "%D") then -- check if something else than numbers are in, and then if not
      return core.readString(tonumber(testString))
    end
  end
  
  return nil
end

modules.files:registerOverrideFunction(function(resourcePath)
  local realPath = getPathFromStringAddress(SFX_BASE, resourcePath)
  if realPath == nil then
    realPath = getPathFromStringAddress(BINK_BASE, resourcePath)
  end
  
  if realPath then -- else nil
    return realPath
  end
  
  if not ratComplain and string.find(resourcePath, "Genie_13") then
    return ""
  elseif not sultanComplain and string.find(resourcePath, "Genie_14") then
    return ""
  end
end)

local function setRatComplain(active)
  ratComplain = active
end

local function setSultanComplain(active)
  sultanComplain = active
end



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
  SetRatComplain = setRatComplain,
  SetSultanComplain = setSultanComplain,
}