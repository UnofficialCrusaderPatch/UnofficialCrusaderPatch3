
---These functions are only used by the game for .map and .sav loading.
local FindFirstFileA, FindNextFileA, FindFirstFileA_stub, FindNextFileA_stub

local map_names_exclusive = true
local MAP_NAMES_INCLUDE = {["Close Encounters.map"]=true, ["Green Haven.map"]=true}
local CURRENT_TARGET

local function nextMapHit(this, handle, struct)
    local f = core.readString(struct + 44)
    if MAP_NAMES_INCLUDE[f] ==  true then
        return handle
    else
        while FindNextFileA(this, handle, struct) == TRUE do
            f = core.readString(struct + 44)
            if MAP_NAMES_INCLUDE[f] == true then
                print("browsing the map: including: " .. f)
                return true
            end
        end
        CURRENT_TARGET = nil
    end
    return false
end

local function FindFirstFileA_hook(this, target, struct)
    CURRENT_TARGET = core.readString(target)
    local handle = FindFirstFileA(this, target, struct)
    if handle ~= -1 then
        local f = core.readString(struct + 44)
        print("Found first file: " .. f)
        if CURRENT_TARGET:sub(-4) == ".map" then
            if map_names_exclusive == true then
                local result = nextMapHit(this, handle, struct)
                if result then
                    return handle
                else
                    return -1
                end
            end
        end
    else
        CURRENT_TARGET = nil
    end
    return handle
end

local function FindNextFileA_hook(this, handle, struct)
    local found = FindNextFileA(this, handle, struct)
    --local fileName = core.readString(handle + 44)

    if CURRENT_TARGET:sub(-4) == ".map" and map_names_exclusive == true then
        if found == TRUE then
            local result = nextMapHit(this, handle, struct)
            if result then
                return TRUE
            else
                return FALSE
            end
        end
        -- Overwrite:
        -- core.writeBytes(handle + 44, {0x00} * 260)
        -- core.writeString(handle + 44, string)
    else
        return found
    end
end

return {
    enable = function(config)

        FindFirstFileA = core.exposeCode(core.readInteger(0x0059e078), 3, 1) -- actually stdcall, so 2 args
        FindNextFileA = core.exposeCode(core.readInteger(0x0059e070), 3, 1) -- actually stdcall

        FindFirstFileA_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, 0x08, 0x00}) --nops and return 08
        core.hookCode(FindFirstFileA_hook, FindFirstFileA_stub, 3, 1, 5)
        core.writeCode(0x0059e078, {FindFirstFileA_stub})

        FindNextFileA_stub = core.allocateCode({0x90, 0x90, 0x90, 0x90, 0xC2, 0x08, 0x00}) --nops and return 08
        core.hookCode(FindNextFileA_hook, FindNextFileA_stub, 3, 1, 5)
        core.writeCode(0x0059e070, {FindNextFileA_stub})
    end

}