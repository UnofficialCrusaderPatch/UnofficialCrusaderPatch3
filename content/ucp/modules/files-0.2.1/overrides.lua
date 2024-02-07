
--- Keys in this dictionary are lower case. Values have their original case.
local FILE_OVERRIDES = {}
local FILE_OVERRIDE_FUNCTIONS = {}

local logFileAccess = nil


local function onOpenFile(file)

  local override = nil

  for k, func in pairs(FILE_OVERRIDE_FUNCTIONS) do
    override = func(file)
    if override ~= nil then
      return override
    end
  end

  file = file:lower()

  override = FILE_OVERRIDES[file]
  if override ~= nil then
    return override
  end

  return nil
end


local function overwriteResource(filepath)
  if logFileAccess then
    log(DEBUG, "Game opened file: " .. tostring(filepath))
  end

  local override = onOpenFile(filepath)

  if override == nil then
    if logFileAccess then
      log(DEBUG, "No override found for: '" .. tostring(filepath) .. "'")
    end
  else
    override = ucp.internal.resolveAliasedPath(override)
    if logFileAccess then
      log(DEBUG, "File '" .. tostring(filepath) .. "' overriden with: " .. tostring(override))
    end
  end
  
  return override
end

local function setupIOhooks()
    
    -- _open: 0x005816c3 & Extreme: 0x581b10
    local _openAddress = core.AOBScan("55 8B EC 51 6A 00 8D 45 FC")
    -- core.writeCode(_openAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    -- core.writeCode(_openAddress, { 0xE9, core.getRelativeAddress(_openAddress, io.ucrt._open, -5) })
    
    local _open = core.exposeCode(io.ucrt._open, 3, 0)
    local o_open
    local function _openHook(fileName, mode, perm)
      local luaFileName = core.readString(fileName)
      -- log(VERBOSE, "_open: " .. luaFileName .. " mode: " .. string.format("%X", mode) .. " perm: " .. string.format("%X", perm))

      luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

      --local retValue = open(fileName, mode, perm)
      local retValue
      local o = overwriteResource(luaFileName)
      if o ~= nil then
        -- log(VERBOSE, "Overriding with: " .. o)
        -- core.writeString(ovrsBuffer, o)
        retValue = io.openFileDescriptor(o, mode, perm)
        -- retValue = _open(ucp.internal.registerString(o), mode, perm)
      else
        -- log(VERBOSE, "Not overriding : " .. luaFileName)
        retValue = _open(fileName, mode, perm)
      end
    
  
      -- log(VERBOSE, retValue)
      
      return retValue
    
    end
    
    o_open = core.hookCode(_openHook, _openAddress, 3, 0, 6)
    
    -- _close: 0x00580f38 & Extreme: 0x581385
    local _closeAddress = core.AOBScan("6A 10 68 ? ? ? ? E8 ? ? ? ? 8B 45 08 83 F8 FE 75 1B E8 ? ? ? ? 83 20 00 E8 ? ? ? ? C7 ? ? ? ? ? 83 C8 FF E9 ? ? ? ? 33 FF 3B C7 7C 08 3B ? ? ? ? ? 72 21 E8 ? ? ? ? 89 38 E8 ? ? ? ? C7 ? ? ? ? ? 57 57 57 57 57 E8 ? ? ? ? 83 C4 14 EB C9 8B C8 C1 F9 05 8D ? ? ? ? ? ? 8B F0 83 E6 1F C1 E6 06 8B 0B 0F ? ? ? ? 83 E1 01 74 BF 50 E8 ? ? ? ? 59 89 7D FC 8B 03 F6 ? ? ? ? 74 0E")
    core.writeCode(_closeAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_closeAddress, { 0xE9, core.getRelativeAddress(_closeAddress, io.ucrt._close, -5) })



    -- _read: 0x005815c6 & Extreme: 0x581a13
    local _readAddress = core.AOBScan("6A 10 68 ? ? ? ? E8 ? ? ? ? 8B 45 08 83 F8 FE 75 1B E8 ? ? ? ? 83 20 00 E8 ? ? ? ? C7 ? ? ? ? ? 83 C8 FF E9 ? ? ? ? 33 F6")
    core.writeCode(_readAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_readAddress, {0xE9, core.getRelativeAddress(_readAddress, io.ucrt._read, -5) })

    -- _write: 0x00581f6f & Extreme: 0x5823bc
    local _writeAddressPre = core.AOBScan("E8 ? ? ? ? 83 C4 0C 3B C7 75 0F")
    local _writeAddress = core.readInteger(_writeAddressPre + 1) + _writeAddressPre + 5
    core.writeCode(_writeAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_writeAddress, {0xE9, core.getRelativeAddress(_writeAddress, io.ucrt._write, -5) })

 
    -- fopen: 0x005804cd & Extreme: 0x58091a
    local fopenAddress = core.AOBScan("6A 40 FF 74 24 0C")
    -- core.writeCode(fopenAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    -- core.writeCode(fopenAddress, {0xE9, core.getRelativeAddress(fopenAddress, io.ucrt.fopen, -5) })
    
    
    local fopen = core.exposeCode(io.ucrt.fopen, 2, 0)
    local o_fopen
    local function fopenHook(fileName, mode)
      local luaFileName = core.readString(fileName)
      -- log(2, "fopen: " .. luaFileName .. " mode: " .. mode)

      luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

      local retValue
      local o = overwriteResource(luaFileName)
      if o ~= nil then
        -- log(2, "Overriding with: " .. o)
        -- core.writeString(ovrsBuffer, o)
        retValue = io.openFilePointer(o, core.readString(mode))
      else
        retValue = fopen(fileName, mode)
      end
      
  
      -- log(2, retValue)
      
      return retValue
    
    end
    
    o_fopen = core.hookCode(fopenHook, fopenAddress, 2, 0, 6)

    
    -- fflush: 0x00583298 & Extreme: 0x5836e8
    local fflushAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 F6 39 75 08")
    core.writeCode(fflushAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fflushAddress, {0xE9, core.getRelativeAddress(fflushAddress, io.ucrt.fflush, -5) })
    

    -- ftell: 0x0058028f & Extreme: 0x5806dc
    local ftellAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 C0 33 F6 39 75 08 0F 95 C0 3B C6 75 1D E8 ? ? ? ? C7 ? ? ? ? ? 56 56 56 56 56 E8 ? ? ? ? 83 C4 14 83 C8 FF EB 27")
    core.writeCode(ftellAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(ftellAddress, {0xE9, core.getRelativeAddress(ftellAddress, io.ucrt.ftell, -5) })
    
    -- local ftell = core.exposeCode(io.ucrt.ftell, 1, 0)
    

    -- do pipes CreatePipe actually support seek? No they don't
    -- fseek: 0x00580384 & Extreme: 0x5807d1
    local fseekAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 C0 33 F6 39 75 08 0F 95 C0 3B C6 75 1D E8 ? ? ? ? C7 ? ? ? ? ? 56 56 56 56 56 E8 ? ? ? ? 83 C4 14 83 C8 FF EB 3E")
    core.writeCode(fseekAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fseekAddress, {0xE9, core.getRelativeAddress(fseekAddress, io.ucrt.fseek, -5) })
    
        

    
    -- fclose: 0x0057fcb2 & Extreme: 0x5800ff
    local fcloseAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 83 4D E4 FF")
    core.writeCode(fcloseAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fcloseAddress, {0xE9, core.getRelativeAddress(fcloseAddress, io.ucrt.fclose, -5) })
    

    -- fread_s: 0x0057ff34 & Extreme: 0x580381
    local fread_sAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 F6 89 75 E4 39 75 10")
    core.writeCode(fread_sAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fread_sAddress, {0xE9, core.getRelativeAddress(fread_sAddress, io.ucrt.fread_s, -5) })
    
    -- fwrite: 0x0058099b & Extreme: 0x580de8
    local fwriteAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 F6 39 75 0C")
    core.writeCode(fwriteAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fwriteAddress, {0xE9, core.getRelativeAddress(fwriteAddress, io.ucrt.fwrite, -5) })
     
    -- fsopen: 0x00580409 & Extreme: 0x580856
    local fsopenAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 DB 89 5D E4 33 C0 8B 7D 08")
    core.writeCode(fsopenAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(fsopenAddress, {0xE9, core.getRelativeAddress(fsopenAddress, io.ucrt._fsopen, -5) })
    
    -- -- __flush which is the same as fflush?
    -- core.writeCode(0x0058311a, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    -- core.writeCode(0x0058311a, {0xE9, core.getRelativeAddress(0x0058311a, io.ucrt.fflush, -5) })    

    -- flsall which is I assume _flushall
    -- _flushall: 0x005831be & Extreme: 0x58360e
    local _flushAllAddress = core.AOBScan("6A 14 68 ? ? ? ? E8 ? ? ? ? 33 FF 89 7D E4 89 7D DC")
    core.writeCode(_flushAllAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_flushAllAddress, {0xE9, core.getRelativeAddress(_flushAllAddress, io.ucrt._flushall, -5) })        
    
    -- _fgetpos: 0x005833f2 & Extreme: 0x583842
    local _fgetposAddress = core.AOBScan("57 33 FF 39 7C 24 08")
    core.writeCode(_fgetposAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_fgetposAddress, {0xE9, core.getRelativeAddress(_fgetposAddress, io.ucrt.fgetpos, -5) })  

    -- _fsetpos: 0x0058345d & Extreme: 0x5838ad
    local _fsetposAddress = core.AOBScan("56 33 F6 39 74 24 08")
    core.writeCode(_fsetposAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_fsetposAddress, {0xE9, core.getRelativeAddress(_fsetposAddress, io.ucrt.fsetpos, -5) })  
    
    -- _fileno: 0x0058c4cb & Extreme: 0x58c8fb
    local _filenoAddress = core.AOBScan("8B 44 24 04 56 33 F6 3B C6 75 1D E8 ? ? ? ? 56 56 56 56 56 C7 ? ? ? ? ? E8 ? ? ? ? 83 C4 14 83 C8 FF")
    core.writeCode(_filenoAddress, {0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_filenoAddress, {0xE9, core.getRelativeAddress(_filenoAddress, io.ucrt._fileno, -5) })   

    -- _fgetwc: 0x00580735 & Extreme: 0x580b82
    local _fgetwcAddress = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 33 C0 33 F6 39 75 08 0F 95 C0 3B C6 75 1E")
    core.writeCode(_fgetwcAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_fgetwcAddress, {0xE9, core.getRelativeAddress(_fgetwcAddress, io.ucrt.getwc, -5) })      

    -- do pipes CreatePipe actually support seek? No they don't
    -- _lseek: 0x0058277e & Extreme: 0x582b4b
    local _lseekAddressPre = core.AOBScan("6A 01 6A 00 FF 74 24 0C")
    local _lseekAddress = core.readInteger(_lseekAddressPre + 8 + 1) + (_lseekAddressPre + 8) + 5
    core.writeCode(_lseekAddress, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, })
    core.writeCode(_lseekAddress, {0xE9, core.getRelativeAddress(_lseekAddress, io.ucrt._lseek, -5) })          

end

local function setupBinkHook()

  local addressOfBinkOpenRef = core.readInteger(core.AOBScan("68 ? ? ? ? 50 FF ? ? ? ? ? 89 44 BE 50") + 8 )
  local addressOfBinkOpen = core.readInteger(addressOfBinkOpenRef)

  local BinkOpen_callingConvention = 2
  local BinkOpen_argCount = 2

  local BinkOpen = core.exposeCode(addressOfBinkOpen, BinkOpen_argCount, BinkOpen_callingConvention)

  local BinkOpen_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, BinkOpen_argCount * 4, 0x00}) --nops and return 08

  local BinkOpen_hook = function(fileName, flags)
    local luaFileName = core.readString(fileName)

    luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

    local retValue
    local o = overwriteResource(luaFileName)
    if o ~= nil then
      -- core.writeString(ovrsBuffer, o)
      retValue = BinkOpen(ucp.internal.registerString(o), flags)
    else
      retValue = BinkOpen(fileName, flags)
    end
    
    return retValue
  end

  core.hookCode(BinkOpen_hook, BinkOpen_stub, BinkOpen_argCount, BinkOpen_callingConvention, 5)
  core.writeCode(addressOfBinkOpenRef, {BinkOpen_stub})
end


local function setupMilesHook() 

  local addressOfAILOpenStreamRef = core.readInteger(core.AOBScan("8B 54 24 14 8B 46 04") + 13)
  local addressOfAILOpenStream = core.readInteger(addressOfAILOpenStreamRef)


  local AIL_open_stream_argCount = 3
  local AIL_open_stream_callingConvention = 2

  local AIL_open_stream = core.exposeCode(addressOfAILOpenStream, AIL_open_stream_argCount, AIL_open_stream_callingConvention)

  
  local AIL_open_stream_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, AIL_open_stream_argCount * 4, 0x00}) --nops and return 0C

  local AIL_open_stream_hook = function(dig, fileName, stream_mem)
    local luaFileName = core.readString(fileName)

    luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

    local retValue
    local o = overwriteResource(luaFileName)
    if o ~= nil then
      retValue = AIL_open_stream(dig, ucp.internal.registerString(o), stream_mem)
    else
      retValue = AIL_open_stream(dig, fileName, stream_mem)
    end
    
    return retValue
  end

  core.hookCode(AIL_open_stream_hook, AIL_open_stream_stub, AIL_open_stream_argCount, AIL_open_stream_callingConvention, 5)
  core.writeCode(addressOfAILOpenStreamRef, {AIL_open_stream_stub})


  local addressOfAILFileReadRef = core.readInteger(core.AOBScan('57 8B 7C 24 0C 6A 00 57 FF ? ? ? ? ?') + 10)
  local addressOfAILFileRead = core.readInteger(addressOfAILFileReadRef)

  local AIL_file_read_argCount = 2
  local AIL_file_read_callingConvention = 2

  local AIL_file_read = core.exposeCode(addressOfAILFileRead, AIL_file_read_argCount, AIL_file_read_callingConvention)

  local AIL_file_read_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, AIL_file_read_argCount * 4, 0x00})

  local AIL_file_read_hook = function(fileName, dest)
    local luaFileName = core.readString(fileName)

    luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

    local retValue
    local o = overwriteResource(luaFileName)
    if o ~= nil then
      retValue = AIL_file_read(ucp.internal.registerString(o), dest)
    else
      retValue = AIL_file_read(fileName, dest)
    end
    
    return retValue
  end

  core.hookCode(AIL_file_read_hook, AIL_file_read_stub, AIL_file_read_argCount, AIL_file_read_callingConvention, 5)
  core.writeCode(addressOfAILFileReadRef, {AIL_file_read_stub})


  local addressOfAILFileSizeRef = core.readInteger(core.AOBScan("8B ? ? ? ? ? 57 89 ? ? ? ? ? ? FF ? ? ? ? ?") + 16)
  local addressOfAILFileSize = core.readInteger(addressOfAILFileSizeRef)

  local AIL_file_size_argCount = 1
  local AIL_file_size_callingConvention = 2

  local AIL_file_size = core.exposeCode(addressOfAILFileSize, AIL_file_size_argCount, AIL_file_size_callingConvention)

  local AIL_file_size_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, AIL_file_size_argCount * 4, 0x00})

  local AIL_file_size_hook = function(fileName)
    local luaFileName = core.readString(fileName)

    luaFileName = ucp.internal.resolveAliasedPath(luaFileName)

    local retValue
    local o = overwriteResource(luaFileName)
    if o ~= nil then
      retValue = AIL_file_size(ucp.internal.registerString(o))
    else
      retValue = AIL_file_size(fileName)
    end
    
    return retValue
  end

  core.hookCode(AIL_file_size_hook, AIL_file_size_stub, AIL_file_size_argCount, AIL_file_size_callingConvention, 5)
  core.writeCode(addressOfAILFileSizeRef, {AIL_file_size_stub})

end

return {
  enable = function(config)

    if config and config.logFileAccess then
      logFileAccess = true
    end
    
    setupIOhooks()

    setupBinkHook()

    setupMilesHook()

  end,

  overrideFileWith = function(file, newFile)    
    file = file:lower()

    newFile = newFile:gsub("/+", "\\")

    log(DEBUG, "Registering override for: " .. file .. ": " .. newFile)

    FILE_OVERRIDES[file] = newFile
  end,

  registerOverrideFunction = function(func)
    table.insert(FILE_OVERRIDE_FUNCTIONS, func)
  end
}
