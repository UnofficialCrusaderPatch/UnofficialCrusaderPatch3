
--[[
The game discovers map files by using FindFirstFileA and FindNextFileA
The logic is as follows:

local ptrInfoStruct -- place where the info is placed in
local handle = FindFirstFileA("maps\\*.map", ptrInfoStruct)
if handle ~= -1 then
  while mapFileCounter < 500 do
    
    storeMapFileInfo()

    mapFileCounter += 1
    
    local n = FindNextFileA(handle, ptrInfoStruct)
    if n == 0 then
      -- we ran out of MAPS
      handle = FindFirstFileA("Documents\\Stronghold Crusader\\maps\\*.map", ptrInfoStruct)
      if handle == -1 then break end
      
    end
  end
  
  FindClose(handle)
end

The functionality below is seperated into two parts: injection of extra maps, swallowing existing MAPS


--]]

---These functions are only used by the game for .map and .sav loading.
---To read the resulting file path of these functions, do: core.readString(struct + 44)
local FindFirstFileA, FindNextFileA, FindFirstFileA_stub, FindNextFileA_stub, FindClose, FindClose_stub

local DISABLE_GAME_DIR_MAPS = false
local DISABLE_USER_DIR_MAPS = false
local DISABLE_USER_DIR_SAVS = false
local DISABLE_GAME_DIR_MAPS_EXTREME = false
local DISABLE_USER_DIR_MAPS_EXTREME = false
local DISABLE_USER_DIR_SAVS_EXTREME = false
local EXTRA_GAME_MAP_DIRECTORIES = nil
local EXTRA_USER_MAP_DIRECTORIES = nil
local EXTRA_USER_SAV_DIRECTORIES = nil
local EXTRA_GAME_MAP_DIRECTORIES_EXTREME = nil
local EXTRA_USER_MAP_DIRECTORIES_EXTREME = nil
local EXTRA_USER_SAV_DIRECTORIES_EXTREME = nil

---Table to hold 'target' extra dirs pairs.
---@type table<string, table<string>>
local EXTRA_DIRS = {}

---@class IterationSession
local IterationSession = { }

---@type IterationSession
local CURRENT_ITERATION_SESSION

local BUFFER = core.allocate(1001, true)
local OPEN_SESSIONS = {}

local function writeBytesFill(address, b, count)
  local data = {}
  for i=1, count do
    table.insert(data, b)
  end
  
  core.writeBytes(address, data)
end

function IterationSession:new(target, struct, skipOriginalFiles, extraDirectories)
    log(VERBOSE, string.format("IterationSession:new(%X, %X, %s, %s)", target, struct, skipOriginalFiles, tostring(extraDirectories)))
    local o = {
        target=target,
        targetString=core.readString(target),
        struct=struct,
        skipOriginalFiles=skipOriginalFiles,
        isHandlingExtraDirectories=false,
        extraDirectories=extraDirectories,
        extraDirIndex=0,
    }
    self.__index = self
    o = setmetatable(o, self)    
    return o
end

function IterationSession:first( target, struct)
    log(VERBOSE, string.format("IterationSession:first(%X, %X)", target, struct))
    if struct ~= self.struct then
      log(FATAL, 'IterationSession:first : invalid struct' .. tostring(struct))
        error("invalid 'struct'")
    end
    
    self.handle = FindFirstFileA( target, struct)
    log(VERBOSE, string.format("IterationSession:first(%X, %X) registering open session %X", target, struct, self.handle))
    table.insert(OPEN_SESSIONS, self)
    
    if self.handle ~= -1 then
         log(VERBOSE, string.format("IterationSession:first(%X, %X) found first file", target, struct))
         
         local fname = core.readString(struct + 0x2C)
         
        if not self.isHandlingExtraDirectories and self.skipOriginalFiles then
            log(VERBOSE, string.format("IterationSession:first(%X, %X) swallowing files", target, struct))

                -- TODO: untested line
            if self.extraDirectories ~= nil then
              log(VERBOSE, string.format("IterationSession:first(%X, %X) shifting to extra", target, struct))
              self.isHandlingExtraDirectories = true
              return self:findFirstFileInNextExtraDirectory(struct)
            end
            
            -- TODO: close handle?
            return -1
        end
         
        log(VERBOSE, string.format("IterationSession:first(%X, %X) permitting files %X", target, struct, self.handle))
        return self.handle
    else
        log(VERBOSE, string.format("IterationSession:first(%X, %X) found no first file", target, struct))
      if self.extraDirectories ~= nil then
        log(DEBUG, "No files in: " .. core.readString(target) .. " . Moving on to extra directories")
        self.isHandlingExtraDirectories = true
        return self:findFirstFileInNextExtraDirectory( target, struct)
      else
        log(DEBUG, "No files in: " .. core.readString(target) .. " . Finishing")
        return -1
      end
    end
end

function IterationSession:findFirstFileInNextExtraDirectory(struct)
    log(VERBOSE, string.format("IterationSession:extra(%X)", struct))
    
    self.isHandlingExtraDirectories = true
    
    if struct ~= self.struct then
      log(FATAL, 'IterationSession:extra : invalid struct' .. tostring(struct))
        error("invalid 'struct'")
    end
    
    if self.extraDirIndex == 0 then
        self.extraDirIndex = 1
    else
        --Apparently, we ran out of files in this extraDir, move unto the next.
        self.extraDirIndex = self.extraDirIndex + 1
    end

    while self.extraDirectories ~= nil and self.extraDirectories[self.extraDirIndex] ~= nil do
        log(VERBOSE, string.format("IterationSession:extra(%X) extra directory %s", struct, self.extraDirIndex))
        
        log(VERBOSE, string.format("IterationSession:extra(%X) closing handle %X", struct, self.handle))
        
        if self.handle ~= -1 then self:close() end
       
        self.targetString = self.extraDirectories[self.extraDirIndex]
        self.target = BUFFER
        writeBytesFill(BUFFER, 0, 1001)
        core.writeString(BUFFER, self.targetString) 
        
        log(VERBOSE, string.format("IterationSession:extra(%X) shifting target to %s", struct, self.targetString))
        
        log(VERBOSE, string.format("IterationSession:extra(%X) finding first file %X", struct, self.target))
        self.handle = FindFirstFileA(self.target, struct)
        
        if self.handle ~= -1 then
          log(VERBOSE, string.format("IterationSession:extra(%X) found first file %X %X", struct, self.target, self.handle))    
          return self.handle
        else
            log(VERBOSE, string.format("IterationSession:extra(%X) found NO first file %X", struct, self.target))            
        --No file in this directory, move on to next extraDir
            self.extraDirIndex = self.extraDirIndex + 1
        end
    end

    log(VERBOSE, string.format("IterationSession:extra(%X) end of extra", struct))
    -- Reached end of EXTRA_DIRS
    return -1
end

function IterationSession:next( handle, struct)
    log(VERBOSE, string.format("IterationSession:next(%X, %X)", handle, struct))
    
    if self.handle ~= handle then
      log(VERBOSE, string.format("IterationSession:next(%X, %X): handle from game is not equal (anymore) to the stored one %X", handle, struct, self.handle))
      handle = self.handle
    end

    if struct ~= self.struct then
      log(FATAL, 'IterationSession:next : invalid struct' .. tostring(struct))
        error("invalid 'struct'")
    end
    
    if not self.isHandlingExtraDirectories then
      if self.skipOriginalFiles then
        log(VERBOSE, string.format("IterationSession:next(%X, %X) skipping original files", handle, struct))
        local found = FindNextFileA(handle, struct) 
        
        while found ~= 0 do
          found = FindNextFileA(handle, struct) 
        end
        
        --We ran out of files in this target, inject extra directories
        log(VERBOSE, string.format("IterationSession:next(%X, %X) finished skipping files", handle, struct))
        return self:findFirstFileInNextExtraDirectory( struct)
      else
        log(VERBOSE, string.format("IterationSession:next(%X, %X) finding next file", handle, struct))
        local found = FindNextFileA( handle, struct)
        
        if found ~= 0 then
          log(VERBOSE, string.format("IterationSession:next(%X, %X) found next file: %x", handle, struct, found))        
          return handle
        else
          log(VERBOSE, string.format("IterationSession:next(%X, %X) NOT found next file, moving on to extra: %x", handle, struct, found))        
            --We ran out of files in this target, inject extra directories
            return self:findFirstFileInNextExtraDirectory( struct)
        end
      end
    else
    log(VERBOSE, string.format("IterationSession:next(%X, %X) finding next file", handle, struct))
      local found = FindNextFileA( handle, struct)
      if found == TRUE then
        log(VERBOSE, string.format("IterationSession:next(%X, %X) found next file: %x", handle, struct, found))
          --There is a file lined up. Consume it, or yield it? For now, always yield
          return handle
      else
      log(VERBOSE, string.format("IterationSession:next(%X, %X) NOT found next file, moving on to extra: %x", handle, struct, found))        
          --We ran out of files in this target, inject extra directories
          return self:findFirstFileInNextExtraDirectory(struct)
      end     
    end
end

function IterationSession:close()
  log(VERBOSE, string.format("IterationSession:close implicitly %X", self.handle))
  local theIndex = nil
  
  for index, session in pairs(OPEN_SESSIONS) do
    if session.handle == self.handle then
      log(VERBOSE, string.format("IterationSession:close closing %X", self.handle))
      theIndex = index
      FindClose(self.handle)
    end
  end

  if theIndex ~= nil then
    log(VERBOSE, string.format("IterationSession:close removing %X at %X", self.handle, theIndex))
    table.remove(OPEN_SESSIONS, theIndex)
    return true
  else
    log(VERBOSE, string.format("IterationSession:close tried to close a non-existent session"))
    return false
  end
end


local function FindFirstFileA_hook(target, struct)
    log(VERBOSE, string.format("FindFirstFileA_hook(%X, %X)", target, struct))
    local targetString = core.readString(target)
    local isUserPath = targetString:find(":") or targetString:find("~")
   
    log(VERBOSE, string.format("FindFirstFileA_hook: targetString: %s", targetString))
   
    if targetString:reverse():sub(1, ("\\*.map"):len()):lower() == ("\\*.map"):reverse() then
      -- maps
      log(VERBOSE, string.format("FindFirstFileA_hook: maps: %s", targetString))
      if targetString:sub(1, ("maps\\*.map"):len()):lower() == "maps\\*.map" then
        -- game folder maps
        log(VERBOSE, string.format("FindFirstFileA_hook: game folder maps: %s", targetString))
        CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_GAME_DIR_MAPS, EXTRA_GAME_MAP_DIRECTORIES)
      elseif targetString:sub(1, ("mapsExtreme\\*.map"):len()):lower() == "mapsextreme\\*.map" then
        -- game folder maps: extreme
        log(VERBOSE, string.format("FindFirstFileA_hook: game folder maps extreme: %s", targetString))
        CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_GAME_DIR_MAPS_EXTREME, EXTRA_GAME_MAP_DIRECTORIES_EXTREME)
      else
        if targetString:reverse():sub(1, ("maps\\*.map"):len()):lower() == ("maps\\*.map"):reverse() then
          -- user folder maps
          log(VERBOSE, string.format("FindFirstFileA_hook: user folder maps: %s", targetString))
          CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_USER_DIR_MAPS, EXTRA_USER_MAP_DIRECTORIES)  
        elseif targetString:reverse():sub(1, ("mapsExtreme\\*.map"):len()):lower() == ("mapsextreme\\*.map"):reverse() then
          -- user folder maps extreme
          log(VERBOSE, string.format("FindFirstFileA_hook: user folder maps extreme: %s", targetString))
          CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_USER_DIR_MAPS_EXTREME, EXTRA_USER_MAP_DIRECTORIES_EXTREME)
        else
          log(WARNING, string.format("FindFirstFileA_hook: unknown: %s", targetString))
          CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, false, nil)
        end
        
      end
      
    elseif targetString:reverse():sub(1, ("\\*.sav"):len()):lower() == ("\\*.sav"):reverse() then
      -- savs
      log(VERBOSE, string.format("FindFirstFileA_hook: savs: %s", targetString))
      if targetString:reverse():sub(1, ("saves\\*.sav"):len()):lower() == ("saves\\*.sav"):reverse() then
        -- user folder savs
        log(VERBOSE, string.format("FindFirstFileA_hook: user folder savs: %s", targetString))
        CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_USER_DIR_SAVS, EXTRA_USER_SAV_DIRECTORIES)  
      elseif targetString:reverse():sub(1, ("SavesExtreme\\*.sav"):len()):lower() == ("savesextreme\\*.sav"):reverse() then
        -- user folder savs extreme
        log(VERBOSE, string.format("FindFirstFileA_hook: user folder savs extreme: %s", targetString))
        CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, DISABLE_USER_DIR_SAVS_EXTREME, EXTRA_USER_SAV_DIRECTORIES_EXTREME)
      else
        log(WARNING, string.format("FindFirstFileA_hook: unknown: %s", targetString))
        CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, false, nil)
      end
    else
      log(VERBOSE, string.format("FindFirstFileA_hook: handle like normal: %s", targetString))
      CURRENT_ITERATION_SESSION = IterationSession:new(target, struct, false, nil)
    end
   
    log(VERBOSE, string.format("FindFirstFileA_hook: first for: %s", targetString))
    return CURRENT_ITERATION_SESSION:first( target, struct)
end

local function FindNextFileA_hook(handle, struct)
    log(VERBOSE, string.format("FindNextFileA_hook(%X, %X)", handle, struct))
    local ret = CURRENT_ITERATION_SESSION:next(handle, struct)
    if ret == -1 or ret == 0 then
        return FALSE
    else
        return TRUE
    end
end

local function FindClose_hook(handle)
  log(VERBOSE, string.format("FindClose_hook(%X)", handle))
  local tryOne = CURRENT_ITERATION_SESSION:close()
  if not tryOne then
    log(VERBOSE, string.format("FindClose_hook: raw closing handle, because handle (%X) not in open sessions (e.g. %X)? ", handle, CURRENT_ITERATION_SESSION.handle))
    FindClose(handle)
  end
end


local MAP_SUFFIX = ".map"

local function registerOverridesForDirectory(dir, extreme)

  log(DEBUG, "Registering map files in: " .. tostring(dir))
  
  local status, results = pcall(function() 
    return table.pack(ucp.internal.listFiles(dir))
  end)
  
  if status == nil or status == false then 
    log(WARNING, string.format("Cannot register directory. Folder does not exist: %s", tostring(dir)))
    log(WARNING, string.format("Accompanying error message: %s", results))
    return
  end

  for k, path in ipairs(results) do
    if path:sub(-MAP_SUFFIX:len()) == MAP_SUFFIX then

      local mapName = path:match("([^/\\]+)[.]map$")

      local trigger = "maps\\" .. mapName .. ".map"
      if extreme then
        trigger = "mapsExtreme\\" .. mapName .. ".map"
      end
      log(DEBUG, "Registering " ..  tostring(trigger) .. " => " .. tostring(path))
      modules.files:overrideFileWith(trigger, path)
    end
  end

end

local function registerExtraDir(target, dir)
    log(INFO, "Registering extra directory: " .. tostring(dir))

    local addr = core.allocate(dir:len() + 1)
    core.writeString(addr, dir)
    core.writeByte(addr + dir:len(), 0)
    EXTRA_DIRS[target] = {[1] = addr}

end

local function prepareDir(dir, ext)
  -- FindNextFile Directory should end with *.map
  local fnfDir = dir
  
  if dir:sub(-1) == "\\" or dir:sub(-1) == "/" then
      fnfDir = dir .. string.format("*.%s", ext)
  end
  if fnfDir:sub(-6) ~= string.format("\\*.%s", ext) and fnfDir:sub(-6) ~= string.format("/*.%s", ext) then
      fnfDir = fnfDir .. string.format("\\*.%s", ext)
  end
  
  fnfDir = ucp.internal.resolveAliasedPath(fnfDir)
  
  return fnfDir
end

return {

    setOption = function(key, value)
      if key == "disable-game-maps" then
        if value == true then
          DISABLE_GAME_DIR_MAPS = true
        else
          DISABLE_GAME_DIR_MAPS = false
        end
      end

      if key == "disable-game-maps-extreme" then
        if value == true then
          DISABLE_GAME_DIR_MAPS_EXTREME = true
        else
          DISABLE_GAME_DIR_MAPS_EXTREME = false
        end
      end

      if key == "disable-user-maps" then
        if value == true then
          DISABLE_USER_DIR_MAPS = true
        else
          DISABLE_USER_DIR_MAPS = false
        end
      end

      if key == "disable-user-maps-extreme" then
        if value == true then
          DISABLE_USER_DIR_MAPS_EXTREME = true
        else
          DISABLE_USER_DIR_MAPS_EXTREME = false
        end
      end

      if key == "disable-user-savs" then
        if value == true then
          DISABLE_USER_DIR_SAVS = true
        else
          DISABLE_USER_DIR_SAVS = false
        end
      end

      if key == "disable-user-savs-extreme" then
        if value == true then
          DISABLE_USER_DIR_SAVS_EXTREME = true
        else
          DISABLE_USER_DIR_SAVS_EXTREME = false
        end
      end

      if key == "extra-map-directory" then
        if value:len() > 0 then
          local dir = value
          log(DEBUG, string.format('extra-map-directory: %s', dir))

          -- FindNextFile Directory should end with *.map
          local fnfDir = prepareDir(dir, "map")

          log(DEBUG, "Registering extra map dir: " .. tostring(fnfDir))

          EXTRA_GAME_MAP_DIRECTORIES = {fnfDir}

          registerExtraDir("maps\\*.map", fnfDir)
          -- registerExtraDir("mapsExtreme\\*.map", fnfDir)
          
          registerOverridesForDirectory(dir, false)
        else
          log(DEBUG, "No extra map directory found in the config")
        end
      end

      if key == "extra-map-extreme-directory" then
        if value:len() > 0 then
          local dir = value
          log(DEBUG, string.format('extra-map-extreme-directory: %s', dir))

          -- FindNextFile Directory should end with *.map
          local fnfDir = prepareDir(dir, "map")

          log(DEBUG, "Registering extra map extreme dir: " .. tostring(fnfDir))

          EXTRA_GAME_MAP_DIRECTORIES_EXTREME = {fnfDir}

          -- registerExtraDir("maps\\*.map", fnfDir)
          registerExtraDir("mapsExtreme\\*.map", fnfDir)
          
          registerOverridesForDirectory(dir, true)
        else
          log(DEBUG, "No extra map extreme directory found in the config")
        end
      end

      if key == "extra-sav-directory" then
          --TODO: how to know the target? We don't know the user username and the documents path?
          --registerExtraDir("maps\\*.map", config["extra-sav-directory"])
          print("WARNING: not implemented: 'extra-sav-directory'")
      end
    end,

    enable = function(config)

        local addressOfFindFirstFileARef = core.readInteger(core.AOBScan("8D 4C 24 60 51 57") + 8)
        local addressOfFindFirstFileA = core.readInteger(addressOfFindFirstFileARef)
        local callingConventionFindFirstFileA = 2
        local argCountFindFirstFileA = 2

        FindFirstFileA = core.exposeCode(addressOfFindFirstFileA, argCountFindFirstFileA, callingConventionFindFirstFileA) -- actually stdcall, so 2 args

        FindFirstFileA_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, argCountFindFirstFileA * 4, 0x00}) --nops and return 08
        core.hookCode(FindFirstFileA_hook, FindFirstFileA_stub, argCountFindFirstFileA, callingConventionFindFirstFileA, 5)
        core.writeCode(addressOfFindFirstFileARef, {FindFirstFileA_stub})

        local addressOfFindNextFileARef = core.readInteger(core.AOBScan("8D 4C 24 60 51 52") + 8)
        local addressOfFindNextFileA = core.readInteger(addressOfFindNextFileARef)
        local callingConventionFindNextFileA = 2
        local argCountFindNextFileA = 2

        FindNextFileA = core.exposeCode(addressOfFindNextFileA, argCountFindNextFileA, callingConventionFindNextFileA) -- actually stdcall

        FindNextFileA_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, argCountFindNextFileA * 4, 0x00}) --nops and return 08
        core.hookCode(FindNextFileA_hook, FindNextFileA_stub, argCountFindNextFileA, callingConventionFindNextFileA, 5)
        core.writeCode(addressOfFindNextFileARef, {FindNextFileA_stub})
        
        
        local addressOfFindCloseRef = core.readInteger(core.AOBScan("FF ? ? ? ? ? 8B ? ? ? ? ? ? 64 ? ? ? ? ? ? 59") + 2)
        local addressOfFindClose = core.readInteger(addressOfFindCloseRef)
        local callingConventionFindClose = 2
        local argCountFindClose = 1
        
        FindClose = core.exposeCode(addressOfFindClose, argCountFindClose, callingConventionFindClose)
        
        FindClose_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, argCountFindClose * 4, 0x00}) --nops and return 08
        core.hookCode(FindClose_hook, FindClose_stub, argCountFindClose, callingConventionFindClose, 5)
        core.writeCode(addressOfFindCloseRef, {FindClose_stub})
        
        
        
        -- local jumpFrom = core.AOBScan("8B ? ? ? ? ? ? 64 ? ? ? ? ? ? 59 5F 5E 5D 5B 8B ? ? ? ? ? ? 33 CC E8 ? ? ? ? 81 ? ? ? ? ? C2 04 00 33 ED")
        -- local jumpFromSize = 7
        
        local jumpFrom = core.AOBScan("0F ? ? ? ? ? 81 ? ? ? ? ? 0F ? ? ? ? ? 8B ? ? ? ? ? EB 07")
        local jumpFromSize = 6
        
        local ediInstruction = core.readBytes(jumpFrom + 18, 6)
        
        
        local jumpTo = core.AOBScan("39 6C 24 20 0F ? ? ? ? ? 39 6C 24 30")
        
        core.insertCode(jumpFrom, jumpFromSize, {
          ediInstruction,
          core.jeTo(jumpTo),
        }, nil, "after")
    end

}