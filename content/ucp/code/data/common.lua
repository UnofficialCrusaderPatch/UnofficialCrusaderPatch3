core = require 'core'

local namespace = {}

-- All the AOBScans done on startup
namespace.SCANS = {
    ["SWITCH_TO_MENU_FN"] = (function()
        local temp0 = core.scanForAOB("E8 ? ? ? ? 57 8B ? E8 ? ? ? ? 57") + 1
        return temp0 + core.readInteger(temp0) + 4
    end)(),
    ["SKIRMISH_MENU_UI_ELEMENT_ARRAY_REFERENCE"] = core.readInteger(core.scanForAOB("89 1D ? ? ? ? E8 ? ? ? ? 68 CA 08 00 00 53") + 2) - 12,
    ["SKIRMISH_MENU_UI_ELEMENT_ARRAY"] = core.scanForAOB("03 00 00 00 87 00 00 00 C0 00 00 00 2C 01 00 00 1E 00 00 00") - 80,
    ["ROUND_TABLE_UI_ELEMENT_ARRAY"] = core.scanForAOB("03 00 00 02 BC 02 00 00 7C 01") - 80,
    ["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] = 0,
    ["MAP_AVAILABLE_ARRAY_POINTER"] = core.readInteger(core.scanForAOB("39 2C 95 ? ? ? ? 7F ? 89") + 3),
    ["MAP_SELECTION_PRELOAD_MAP_INDEX_MAPPING_POINTER"] = core.readInteger(core.scanForAOB("8B 04 95 ? ? ? ? 50 B9 ? ? ? ?") + 3),
    ["MAP_SELECTION_SCROLL_OFFSET"] = core.readInteger(core.scanForAOB("8B 15 ? ? ? ? 03 D1 8B 04") + 2),
    ["MAP_SELECTION_SCROLL_MAX_OFFSET"] = 0,
    ["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"] = 0,
    ["LOBBY_AI_ARRAY"] = core.readInteger(core.scanForAOB("3B 0C 95 ? ? ? ? 75 ? 8B 08 3B CE") + 3) + 4,
    ["LOBBY_PLAYER_ARRAY"] = 0,
    ["LOBBY_IS_HOST"] = 0,
    ["MENU_SKIRMISH_CHOICE_CLICK_CALLBACK"] = core.scanForAOB("8B 44 24 04 83 F8 FF 75 ? 6A"),
    ["CURRENT_GAME_MODE"] = core.readInteger(core.scanForAOB("39 3D ? ? ? ? 0F 85 ? ? ? ? 3B C7") + 2),
    ["LOBBY_GROUP_ARRAY"] = core.readInteger(core.scanForAOB("8A 88 ? ? ? ? 84 C9 0F BE F9 89 3C 85 ? ? ? ?") + 2) + 1
}

-- Don't want to aobscan these, these are fixed offsets from an existing aobscan
namespace.SCANS["MAP_SELECTION_SCROLL_MAX_OFFSET"] = namespace.SCANS["MAP_SELECTION_SCROLL_OFFSET"] + 4
namespace.SCANS["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"] = namespace.SCANS["MAP_SELECTION_SCROLL_OFFSET"] + 8
namespace.SCANS["LOBBY_PLAYER_ARRAY"] = namespace.SCANS["LOBBY_AI_ARRAY"] - 108
namespace.SCANS["LOBBY_IS_HOST"] = namespace.SCANS["LOBBY_AI_ARRAY"] + 120
namespace.SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] = core.readInteger(namespace.SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY"] + 76)



-- Returns current game mode
function namespace.getCurrentGameMode()
    return core.readInteger(namespace.SCANS["CURRENT_GAME_MODE"])
end

-- Determines the number of AIs in the lobby
function namespace.numberOfAIsInLobby()
    local i
    local result = 0
    local arrayPointer = namespace.SCANS["LOBBY_AI_ARRAY"]

    for i = 0, 7, 1 do
        if core.readInteger(arrayPointer + i * 4) > 0 then
            result = result + 1
        end
    end

    return result
end

-- Determines the number of players in the lobby
function namespace.numberOfPlayersInLobby()
    local i
    local result = 0
    local arrayPointer = namespace.SCANS["LOBBY_PLAYER_ARRAY"]

    for i = 0, 7, 1 do
        if core.readInteger(arrayPointer + i * 4) >= 0 then
            result = result + 1
        end
    end

    return result
end


-- Determines whether we are the host
function namespace.isHost()
    return core.readInteger(namespace.SCANS["LOBBY_IS_HOST"]) == 1
end

local queueCommand_this = core.readInteger(core.scanForAOB("B9 ? ? ? ? E8 ? ? ? ? 83 F8 01 75 ? 66 89 87 ? ? ? ?") + 1)
-- Queues command
function namespace.queueCommand(command)
    namespace.queueCommand_hooked(queueCommand_this, command)
end

function namespace.queueCommand_hooked(this, commandType)

    -- hook into queue command here!
    -- do not write your code here, load custom logic from file!
    -- assert(loadfile("ucp/lua/src/..."))()

    return namespace.queueCommand_original(this, commandType)
end

namespace.queueCommand_original = core.hookCode(namespace.queueCommand_hooked, (function()
    local temp0 = core.scanForAOB("E8 ? ? ? ? 5E C3 83 F8 01 75 ? 6A 2E") + 1
    return temp0 + core.readInteger(temp0) + 4
end)(), 2, 1, 10)

return namespace