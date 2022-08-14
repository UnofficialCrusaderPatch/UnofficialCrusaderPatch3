-- NOTE: does not capture certain types of files, mostly normal sfx

--[[ Constants ]]--

local MAX_PATH_LENGTH = 1000

local TYPE_EXTENSION = {
  SPEECH        = "wav",
  AIV           = "aiv",
  BINKS         = "bik",
  GFX           = "tgx",
  GM            = "gm1",
  HELP          = "hlp",
  FX            = "wav",
  MUSIC         = "raw",
  MAPS          = "map",
  MAPS_EXTREME  = "map",
  FACES         = "bmp",
}

local RESOURCE_LOAD_ID = {
  [0x1 ]  = "UNKNOWN",
  [0x2 ]  = "CASTLES",    -- not used
  [0x6 ]  = "SCENARIOS",  -- not used
  [0xa ]  = "GM",
  [0xb ]  = "GFX",
  [0xc ]  = "HELP",
  [0xd ]  = "BINKS",
  [0xe ]  = "FX",
  [0xf ]  = "MAPS",
  [0x10]  = "SCORES",     -- not used?
  [0x11]  = "GFX8",       -- not used?
  [0x12]  = "SPEECH",
  [0x13]  = "FACES",
}

local TYPES_HANDLED_BY_OPEN = extensions.utils.Set:new({"aiv", "raw", "tex"})
local TYPES_HANDLED_BY_RESOURCE_LOAD = extensions.utils.Set:new({"tgx", "gm1", "bik", "map", "act", "bmp", "wav", "hlp"})


--[[ Variables ]]--

local fileopen_use_address = core.AOBScan("E8 ? ? ? ? 83 c4 0c 83 f8 ff 89 86 08 0d 08 00 89 be c4 0b 00 00 75 07 5f 33 c0 5e c2 0c 00")
local fileopen_address = core.readInteger(fileopen_use_address + 1) + fileopen_use_address + 5 -- turn into absolute address
local resourceLoaderFuncStart = core.AOBScan("83 ec 24 a1 ? ? ? ? 33 c4 89 44 24 20 53 55", 0x400000)

local FILE_OVERRIDES = {}
local FILE_OVERRIDE_FUNCTIONS = {}

local resourceLoadFunc = nil
local stringBuffer = core.allocate(1001)

local logFileAccess = nil


--[[ Funtions ]]--

local function overwriteTooLong(overwrite)
  if overwrite:len() > 1000 then
    log(WARNING, "Path to long. Max length is 1000 chars. Can not set overwrite: " .. overwrite)
    return true
  end
  return false
end

local function onOpenFile(file)
  for k, func in pairs(FILE_OVERRIDE_FUNCTIONS) do
    local fresult = func(file)
    if fresult ~= nil then
      if not overwriteTooLong(fresult) then
        if logFileAccess then
          log(DEBUG, "... overridden with file: " .. override)
        end
        return fresult
      end
    end
  end

  if FILE_OVERRIDES[file] ~= nil then
    if logFileAccess then
      log(DEBUG, "... overridden with file: " .. override)
    end
    return FILE_OVERRIDES[file]
  end

  return nil
end


local function overwriteResource(filepath)
  if logFileAccess then
    log(DEBUG, "Game opened file: " .. filepath)
  end

  return onOpenFile(filepath)
end


local function getExtension(filepath)
  local _, _, ext = filepath.find(filepath, "%.(%a+)$")
  return ext
end


local function isHandled(handler, otherHandlers, filepath)
  local ext = getExtension(filepath)
  
  if not handler:contains(ext) then
    local handledByOther = false
    for index, otherHandler in pairs(otherHandlers) do
      handledByOther = handledByOther or otherHandler:contains(ext)
    end
    if not handledByOther then
      log(WARNING, "Encountered file not set to be handled by any endpoint: " .. filepath)
    end
    return false
  end

  return true
end


local function writeCString(address, str)
  core.writeString(address, str)
  core.writeByte(address + str:len(), 0)
end


local function fileOpenDetour(registers)
  local file = core.readString(core.readInteger(registers.ESP + 4))

  if not isHandled(TYPES_HANDLED_BY_OPEN, {TYPES_HANDLED_BY_RESOURCE_LOAD}, file) then
    return
  end

  local override = overwriteResource(file)
  if override ~= nil then
    writeCString(stringBuffer, override)
    core.writeInteger(registers.ESP + 4, stringBuffer)
  end
end


local function resourceLoadHook(this, resourceFileType, shortFileNamePtr)
  resourceLoadFunc(this, resourceFileType, shortFileNamePtr)

  local resourceAddress = this + 0x7AEE0 + resourceFileType * 1001
  local resourceString = core.readString(resourceAddress)
  
  local wasGmFile = false -- they arrive without ending here
  if string.find(resourceString, "gm\\") then
    wasGmFile = true
    resourceString = string.format("%s.gm1", resourceString)
  end
  
  if not isHandled(TYPES_HANDLED_BY_RESOURCE_LOAD, {TYPES_HANDLED_BY_OPEN}, resourceString) then
    return
  end

  local override = overwriteResource(resourceString)
  if override ~= nil then
    if wasGmFile then
      resourceString = string.gsub(resourceString, ".gm1", "")
    end
    writeCString(resourceAddress, override)
  end
end


return {
  enable = function(config)
    if config and config.logFileAccess then
      logFileAccess = true
    end
    
    core.detourCode(fileOpenDetour, fileopen_address, 6)
    resourceLoadFunc = core.hookCode(resourceLoadHook, resourceLoaderFuncStart, 3, 1, 8)
  end,

  overrideFileWith = function(file, newFile)
    if logFileAccess then
      log(DEBUG, "Registering override for: " .. file .. ": " .. newFile)
    end
    
    if overwriteTooLong(newFile) then
      return
    end
    
    FILE_OVERRIDES[file] = newFile
  end,

  registerOverrideFunction = function(func)
    table.insert(FILE_OVERRIDE_FUNCTIONS, func)
  end
}