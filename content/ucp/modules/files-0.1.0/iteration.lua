
---These functions are only used by the game for .map and .sav loading.
---To read the resulting file path of these functions, do: core.readString(struct + 44)
local FindFirstFileA, FindNextFileA, FindFirstFileA_stub, FindNextFileA_stub

local DISABLE_GAME_DIR_MAPS = false
local DISABLE_GAME_DIR_USER_MAPS = false
local DISABLE_GAME_DIR_USER_SAVS = false

---Table to hold 'target' extra dirs pairs.
---@type table<string, table<string>>
local EXTRA_DIRS = {}

---@class IterationSession
local IterationSession = { }

---@type IterationSession
local CURRENT_ITERATION_SESSION

function IterationSession:new( target, struct)
    local o = {
        target=core.readString(target),
        struct=struct,
        extraDirIndex=0,
    }
    self.__index = self
    return setmetatable(o, self)
end

function IterationSession:first( target, struct)
    local handle = FindFirstFileA( target, struct)
    if handle ~= -1 then
        return handle
    else
        log(INFO, "No files in: " .. core.readString(target) .. " moving on to extra directories")
        return CURRENT_ITERATION_SESSION:nextExtra( handle, struct)
    end
end

function IterationSession:nextExtra( struct)
    if self.extraDirIndex == 0 then
        self.extraDirIndex = 1
    else
        --Apparently, we ran out of files in this extraDir, move unto the next.
        self.extraDirIndex = self.extraDirIndex + 1
    end

    while EXTRA_DIRS[self.target] ~= nil and EXTRA_DIRS[self.target][self.extraDirIndex] ~= nil do
        local newTarget = EXTRA_DIRS[self.target][self.extraDirIndex]
        local newHandle = FindFirstFileA( newTarget, struct)
        log(INFO, "checking directory: " .. core.readString(newTarget))
        if newHandle ~= -1 then
            return newHandle
        else
            --No file in this directory, move on to next extraDir
            self.extraDirIndex = self.extraDirIndex + 1
        end
    end

    -- Reached end of EXTRA_DIRS
    return -1
end

function IterationSession:next( handle, struct)
    if struct ~= self.struct then
        error("invalid 'struct'")
    end

    local found = FindNextFileA( handle, struct)
    if found == TRUE then
        --There is a file lined up. Consume it, or yield it? For now, always yield
        return handle
    else
        --We ran out of files in this target, inject extra directories
        return self:nextExtra( struct)
    end

end


local function FindFirstFileA_hook(target, struct)
    CURRENT_ITERATION_SESSION = IterationSession:new(target, struct)

    local targetString = core.readString(target)
    local isUserPath = targetString:find(":") or targetString:find("~")

    if (targetString == "maps\\*.map" or targetString == "mapsExtreme\\*.map") and DISABLE_GAME_DIR_MAPS then
        return CURRENT_ITERATION_SESSION:nextExtra(struct)
    elseif targetString:sub(-4) == ".map" and isUserPath ~= nil and DISABLE_GAME_DIR_USER_MAPS then
        --Trying to detect the request for user maps.
        --TODO: fully test this pattern for all languages
        return CURRENT_ITERATION_SESSION:nextExtra( struct)
    elseif targetString:sub(-4) == ".sav" and isUserPath ~= nil and DISABLE_GAME_DIR_USER_SAVS then
        --Trying to detect the request for user savs.
        --TODO: fully test this pattern for all languages
        return CURRENT_ITERATION_SESSION:nextExtra( struct)
    end

    return CURRENT_ITERATION_SESSION:first( target, struct)
end

local function FindNextFileA_hook(handle, struct)
    if CURRENT_ITERATION_SESSION:next(handle, struct) == -1 then
        return FALSE
    else
        return TRUE
    end
end


local MAP_SUFFIX = ".map"

local function registerOverridesForDirectory(dir)

  for k, path in ipairs(table.pack(ucp.internal.listFiles(dir))) do
    if path:sub(-MAP_SUFFIX:len()) == MAP_SUFFIX then

      local mapName = path:lower():match("([^/\\]+)[.]map$")

      modules.files.overrideFileWith("maps\\" .. mapName .. ".map", path)
    end
  end

end

local function registerExtraDir(target, dir)
    log(INFO, "Registering extra directory: " .. tostring(dir))

    local addr = core.allocate(dir:len() + 1)
    core.writeString(addr, dir)
    core.writeByte(addr + dir:len(), 0)
    EXTRA_DIRS[target] = {[1] = addr}

    registerOverridesForDirectory(dir)
end

return {
    enable = function(config)

        if config["disable-game-maps"] then
            DISABLE_GAME_DIR_MAPS = true
        end

        if config["disable-user-maps"] then
            DISABLE_GAME_DIR_USER_MAPS = true
        end

        if config["disable-user-savs"] then
            DISABLE_GAME_DIR_USER_SAVS = true
        end

        if config["extra-map-directory"] then

          local dir = config["extra-map-directory"]
          if dir:sub(-1) == "\\" then
              dir = dir .. "*.map"
          end
          if dir:sub(-6) ~= "\\*.map" then
              dir = dir .. "\\*.map"
          end

          log(INFO, "Extra map directory found in the config: " .. tostring(dir))

          registerExtraDir("maps\\*.map", dir)
          registerExtraDir("mapsExtreme\\*.map", dir)
        else
          log(INFO, "No extra map directory found in the config")
        end

        if config["extra-sav-directory"] then
            --TODO: how to know the target? We don't know the user username and the documents path?
            --registerExtraDir("maps\\*.map", config["extra-sav-directory"])
            print("WARNING: not implemented: 'extra-sav-directory'")
        end

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
    end

}