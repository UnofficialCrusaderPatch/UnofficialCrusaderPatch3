
--[[ variables and constants ]]--

local debugLog = false

local aliases = {
  [0 ]   = "rat"         ,
  [1 ]   = "snake"       ,
  [2 ]   = "pig"         ,
  [3 ]   = "wolf"        ,
  [4 ]   = "saladin"     ,
  [5 ]   = "caliph"      ,
  [6 ]   = "sultan"      ,
  [7 ]   = "richard"     ,
  [8 ]   = "frederick"   ,
  [9 ]   = "phillip"     ,
  [10]   = "wazir"       ,
  [11]   = "emir"        ,
  [12]   = "nizar"       ,
  [13]   = "sheriff"     ,
  [14]   = "marshal"     ,
  [15]   = "abbot"       ,
}

local aiWithCastleTable = {
  [0 ]  = false  ,
  [1 ]  = false  ,
  [2 ]  = false  ,
  [3 ]  = false  ,
  [4 ]  = false  ,
  [5 ]  = false  ,
  [6 ]  = false  ,
  [7 ]  = false  ,
  [8 ]  = false  ,
  [9 ]  = false  ,
  [10]  = false  ,
  [11]  = false  ,
  [12]  = false  ,
  [13]  = false  ,
  [14]  = false  ,
  [15]  = false  ,
}

local REPLACEMENTS = {}


--[[ init module ]]--

local init = false

local aivInitFuncAddr = core.AOBScan("83 ec 0c 53 55 56 57 8b f9 89", 0x400000)

local ptrGenerateAivFileStatCallPos = aivInitFuncAddr + 123
local ptrGenerateAivFileStatFunc = core.readInteger(ptrGenerateAivFileStatCallPos + 1) + ptrGenerateAivFileStatCallPos + 5

local ptrAIWithAvailableCastleArray = core.readInteger(aivInitFuncAddr + 179)

local ptrAivPerAIArray = nil
local ptrAivStatArray = nil
local ptrNumberOfAIsWithCastle = nil

local vanillaAIV = {
  aiWithAvailableCastle = {}, -- unused
  aivPerAIArray = {},         -- unused
  aivStatArray = {},
  numberOfAIsWithCastle = 0,  -- unused
}

-- should only be called once
local aivInitFunc = nil
aivInitFunc = core.hookCode(function(this)
  aivInitFunc(this)
  ptrAivPerAIArray = this + 0x3f05c
  ptrAivStatArray = this + 0x3da5c
  ptrNumberOfAIsWithCastle = this + 0x3f0ac
  
  -- save vanilla (NOTE: since it does not use the functions of the AI setters, this might be a bug source)
  for i = 0, 15 do
    local aiWithCastle = core.readInteger(ptrAIWithAvailableCastleArray + i * 4)
    vanillaAIV.aiWithAvailableCastle[i] = aiWithCastle
    if aiWithCastle > 0 then
      aiWithCastleTable[aiWithCastle - 1] = true
    end
    vanillaAIV.aivPerAIArray[i] = core.readInteger(ptrAivPerAIArray + i * 4)
    
    local aivStatIndexBase = i * 8
    for j = 0, 7 do
      local aivStatIndex = aivStatIndexBase + j
      vanillaAIV.aivStatArray[aivStatIndex] = core.readInteger(ptrAivStatArray + aivStatIndex * 4)
    end
  end
  vanillaAIV.numberOfAIsWithCastle = core.readInteger(ptrNumberOfAIsWithCastle)
  
  init = true
end, aivInitFuncAddr, 1, 1, 7)

local generateAivFileStatFunc = core.exposeCode(ptrGenerateAivFileStatFunc, 2, 1)
local stringBuffer = core.allocate(1001)


--[[ functions ]]--

local function overwriteTooLong(overwrite)
  if overwrite:len() > 1000 then
    log(WARNING, "Path to long. Max length is 1000 chars. Can not set overwrite: " .. overwrite)
    return true
  end
  return false
end

local function writeCString(address, str)
  core.writeString(address, str)
  core.writeByte(address + str:len(), 0)
end

local function validateAiAndCastleValues(ai, castle)
  local aiIndex, aiName = nil

  if type(ai) == "number" then
    if aliases[ai] == nil then
      error("Invalid ai argument: " .. ai)
    end
    aiIndex = ai
    aiName = aliases[ai]
  else
    local ok = false
    for index, name in pairs(aliases) do
      local isAi = name == ai
      if isAi then
        ok = true
        aiName = ai
        aiIndex = index
      end
    end
    if not ok then
      error("invalid ai argument: " .. ai)
    end
  end
  if type(castle) ~= "number" then
    if tonumber(castle) == nil then
        error("invalid castle argument: " .. castle)
    end
    castle = tonumber(castle)
  end
  if castle < 1 or castle > 8 then
    error("invalid castle argument: out of bounds [1-8]: " .. tostring(castle))
  end
  return aiIndex, aiName, castle
end

local function createDefaultAIVPath(ai, castle)
  return string.format("aiv\\%s%d.aiv", ai, castle)
end

local function getNumberOfCastlesPerAiPtr(aiIndex)
  return ptrAivPerAIArray + aiIndex * 4
end

local function getCastleStatIndex(aiIndex, castleIndex)
  return aiIndex * 8 + castleIndex - 1 -- because castle ptr is castleIndex - 1
end

local function getVanillaCastleStat(castleStatIndex)
  return vanillaAIV.aivStatArray[castleStatIndex]
end

local function getCastleStatPtr(castleStatIndex)
  return ptrAivStatArray + castleStatIndex * 4
end

local function doesCastleExist(castleStatPtr)
  return core.readInteger(castleStatPtr) > -1
end

local function doesVanillaCastleExist(vanillaCastleValue)
  return vanillaCastleValue > -1
end


local function setAIWithCastleActive(index, active)
  if aiWithCastleTable[index] == nil or aiWithCastleTable[index] == active then
    return -- no action needed
  end

  aiWithCastleTable[index] = active
  
  local num = 0
  for i = 0, 15 do
    if aiWithCastleTable[i] then
      core.writeInteger(ptrAIWithAvailableCastleArray + num * 4, i + 1)
      num = num + 1
    end
  end
  for i = num, 15 do
    core.writeInteger(ptrAIWithAvailableCastleArray + num * 4, 0)
  end
  
  core.writeInteger(ptrNumberOfAIsWithCastle, num)
end


local function setAivForAi(ai, castle, newFileName)
  local aiIndex, aiName, castleIndex = validateAiAndCastleValues(ai, castle)
  local defaultAiPath = createDefaultAIVPath(aiName, castleIndex)
  
  local castleStatIndex = getCastleStatIndex(aiIndex, castleIndex)
  local castleStatPtr = getCastleStatPtr(castleStatIndex)
  local currentPresent = doesCastleExist(castleStatPtr)
  
  local newCastleStat = nil
  local setToExistingCastle = nil
  if newFileName == "" then -- used for disabling castle
    setToExistingCastle = false
    newCastleStat = -1
  elseif newFileName == nil then -- resets
    newCastleStat = getVanillaCastleStat(castleStatIndex)
    setToExistingCastle = doesVanillaCastleExist(newCastleStat)
  else
    if overwriteTooLong(newFileName) then
      return
    end
  
    writeCString(stringBuffer, newFileName)
    newCastleStat = generateAivFileStatFunc(0, stringBuffer) -- does not use this ptr
    
    if newCastleStat < 0 then
      log(WARNING, string.format("Unable to set castle for AI '%s': Castle file not loadable.", aiName))
      return
    end
    
    setToExistingCastle = true
  end
  
  local castlePresenceChanged = setToExistingCastle ~= currentPresent

  REPLACEMENTS[defaultAiPath] = newFileName
  core.writeInteger(castleStatPtr, newCastleStat)
  
  if not castlePresenceChanged then
    return -- nothing else to change
  end
  
  local numberOfCastlesPtr = getNumberOfCastlesPerAiPtr(aiIndex)
  local currentNumberOfThisAIsCastles = core.readInteger(numberOfCastlesPtr)
  
  if newCastleStat < 0 then
    currentNumberOfThisAIsCastles = currentNumberOfThisAIsCastles - 1
  else
    currentNumberOfThisAIsCastles = currentNumberOfThisAIsCastles + 1
  end
  
  core.writeInteger(numberOfCastlesPtr, currentNumberOfThisAIsCastles)
  setAIWithCastleActive(aiIndex, currentNumberOfThisAIsCastles > 0)
end

local function isInit()
  if not init then
    log(WARNING, "aivloader not initialized yet. Ignoring request.")
  end
  return init
end


return {
  enable = function(self, config)
    debugLog = config.debugLog == true
  
    modules.files:registerOverrideFunction(function(fileName)

      if fileName:match("aiv\\.+.aiv$") then
        if REPLACEMENTS[fileName] ~= nil then
          if debugLog then
            log(DEBUG, string.format("Processing AIV override for: '%s'", fileName))
            log(DEBUG, string.format("\t replacement: '%s'", REPLACEMENTS[fileName]))
          end
          return REPLACEMENTS[fileName]
        end
      end
      return nil
    end)

    hooks.registerHookCallback("afterInit", function()
      for ai, v in pairs(config) do
        for castle, fileName in pairs(v) do
          setAivForAi(ai, castle, fileName)
        end
      end
    end)
  end,
  disable = function(self, config)

  end,

  -- ReadOnlyTable is preventing this from being prettier (we cannot expose 'api' because it becomes frozen)
  setAIVFileForAI = function(self, ai, castle, fileName)
    if not isInit() then return end
    setAivForAi(ai, castle, fileName)
  end,
  disableAIVForAi = function(self, ai, castle)
    if not isInit() then return end
    setAivForAi(ai, castle, "")
  end,
  resetAIVForAi = function(self, ai, castle)
    if not isInit() then return end
    setAivForAi(ai, castle, nil)
  end,
  resetAllAIVForAi = function(self, ai)
    if not isInit() then return end
    for i = 1, 8 do
      setAivForAi(ai, i, nil)
    end
  end,
  setMultipleAIVForAi = function(self, ai, castleToPathTable)
    if not isInit() then return end
    for castleIndex, filePath in pairs(castleToPathTable) do
      setAivForAi(ai, castleIndex, filePath)
    end
  end,
}