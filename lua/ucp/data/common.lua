core = require 'core'

local namespace = {}

-- All the AOBScans done on startup
namespace.SCANS = {
	["SWITCH_TO_MENU_FN"] = (function()
		local temp0 = core.scanForAOB("E8 ? ? ? ? 57 8B ? E8 ? ? ? ? 57")+1
		return temp0+core.readInteger(temp0)+4
	end)(),
	["SFX_ADDRESS_ARRAY"] = core.readInteger(core.scanForAOB("83 C6 3A 56 B9 ? ? ? ? E8 ? ? ? ? 5E 5F C2 08 00")+5),
	["PLAY_SFX"] = (function()
		local temp0 = core.scanForAOB("83 C6 3A 56 B9 ? ? ? ? E8 ? ? ? ? 5E 5F C2 08 00")+10
		return temp0+core.readInteger(temp0)+4
	end)(),
	["PLAY_SFX_AT_LOCATION"] = (function()
		local temp0 = core.scanForAOB("6A 40 50 51 B9 ? ? ? ? 66 89 ? ? ? ? 00 E8 ? ? ? ? 5F 5E 5D 5B")+17
		return temp0+core.readInteger(temp0)+4
	end)(),
	["SKIRMISH_MENU_UI_ELEMENT_ARRAY_REFERENCE"] = core.readInteger(core.scanForAOB("89 1D ? ? ? ? E8 ? ? ? ? 68 CA 08 00 00 53")+2)-12,
	["SKIRMISH_MENU_UI_ELEMENT_ARRAY"] = core.scanForAOB("03 00 00 00 87 00 00 00 C0 00 00 00 2C 01 00 00 1E 00 00 00")-80,
	["ROUND_TABLE_UI_ELEMENT_ARRAY"] = core.scanForAOB("03 00 00 02 BC 02 00 00 7C 01")-80,
	["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] = 0,
	["MAP_AVAILABLE_ARRAY_POINTER"] = core.readInteger(core.scanForAOB("39 2C 95 ? ? ? ? 7F ? 89")+3),
	["MAP_SELECTION_PRELOAD_MAP_INDEX_MAPPING_POINTER"] = core.readInteger(core.scanForAOB("8B 04 95 ? ? ? ? 50 B9 ? ? ? ?")+3),
	["MAP_SELECTION_SCROLL_OFFSET"] = core.readInteger(core.scanForAOB("8B 15 ? ? ? ? 03 D1 8B 04")+2),
	["MAP_SELECTION_SCROLL_MAX_OFFSET"] = 0,
	["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"] = 0,
	["LOBBY_AI_ARRAY"] = core.readInteger(core.scanForAOB("3B 0C 95 ? ? ? ? 75 ? 8B 08 3B CE")+3)+4,
	["LOBBY_PLAYER_ARRAY"] = 0,
	["LOBBY_IS_HOST"] = 0,
	["MENU_SKIRMISH_CHOICE_CLICK_CALLBACK"] = core.scanForAOB("8B 44 24 04 83 F8 FF 75 ? 6A"),
	["CURRENT_GAME_MODE"] = core.readInteger(core.scanForAOB("39 3D ? ? ? ? 0F 85 ? ? ? ? 3B C7")+2),
	["LOBBY_GROUP_ARRAY"] = core.readInteger(core.scanForAOB("8A 88 ? ? ? ? 84 C9 0F BE F9 89 3C 85 ? ? ? ?")+2)+1
}

-- Don't want to aobscan these, these are fixed offsets from an existing aobscan
namespace.SCANS["MAP_SELECTION_SCROLL_MAX_OFFSET"] = namespace.SCANS["MAP_SELECTION_SCROLL_OFFSET"]+4
namespace.SCANS["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"] = namespace.SCANS["MAP_SELECTION_SCROLL_OFFSET"]+8
namespace.SCANS["LOBBY_PLAYER_ARRAY"] = namespace.SCANS["LOBBY_AI_ARRAY"]-108
namespace.SCANS["LOBBY_IS_HOST"] = namespace.SCANS["LOBBY_AI_ARRAY"]+120
namespace.SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] = core.readInteger(namespace.SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY"]+76)



-- Plays an SFX by id.
function namespace.playSFX(soundID)
	namespace.playSFX_internal(namespace.SCANS["SFX_ADDRESS_ARRAY"], soundID)
end

-- Plays an SFX by id.
function namespace.playSFXAtLocation(x, y, soundID)
	namespace.playSFXAtLocation_internal(namespace.SCANS["SFX_ADDRESS_ARRAY"], x, y, soundID)
end

-- Returns current game mode
function namespace.getCurrentGameMode()
	return core.readInteger(namespace.SCANS["CURRENT_GAME_MODE"])
end

-- Determines the number of AIs in the lobby
function namespace.numberOfAIsInLobby()
	local i
	local result = 0
	local arrayPointer = namespace.SCANS["LOBBY_AI_ARRAY"]
	
	for i = 0,7,1 do
		if core.readInteger(arrayPointer+i*4) > 0 then
			result = result+1
		end
	end
	
	return result
end

-- Determines the number of players in the lobby
function namespace.numberOfPlayersInLobby()
	local i
	local result = 0
	local arrayPointer = namespace.SCANS["LOBBY_PLAYER_ARRAY"]
	
	for i = 0,7,1 do
		if core.readInteger(arrayPointer+i*4) >= 0 then
			result = result+1
		end
	end
	
	return result
end


-- Determines whether we are the host
function namespace.isHost()
	return core.readInteger(namespace.SCANS["LOBBY_IS_HOST"]) == 1
end

-- Queues command
function namespace.queueCommand(command)
	namespace.queueCommand_hooked(core.readInteger(core.scanForAOB("B9 ? ? ? ? E8 ? ? ? ? 83 F8 01 75 ? 66 89 87 ? ? ? ?")+1), command)
end

function namespace.queueCommand_hooked(this, commandType)
	
	-- hook into queue command here!
	-- do not write your code here, load custom logic from file!
	-- assert(loadfile("ucp/lua/src/..."))()
	
  return namespace.queueCommand_original(this, commandType)
end

namespace.queueCommand_original = core.hookCode(namespace.queueCommand_hooked, (function()
	local temp0 = core.scanForAOB("E8 ? ? ? ? 5E C3 83 F8 01 75 ? 6A 2E")+1
	return temp0+core.readInteger(temp0)+4
end)(), 2, 1, 10)



namespace.SOUND_EFFECT = {
    ["WOOD_CHOP"] = "0x2",
    ["WOOD_SAW"] = "0x3",
    ["STOCKS"] = "0x4",
    ["ARROW_SHOOT"] = "0x5",
    ["ARROW_KILL"] = "0x6",
    ["UNKNOWN_0x07"] = "0x7",
    ["ARROW_SPLASH_IN_WATER"] = "0x8",
    ["WATER_SPLASH"] = "0x9",
    ["UNKNOWN_0x0A"] = "0xa",
    ["MILL"] = "0xb",
    ["INN"] = "0xc",
    ["QUARRY_STONE_CHIP"] = "0xd",
    ["QUARRY_STONE_BREAK"] = "0xe",
    ["QUARRY_STONE_LIFT_01"] = "0xf",
    ["QUARRY_STONE_LIFT_02"] = "0x10",
    ["QUARRY_STONE_SLIDE"] = "0x11",
    ["QUARRY_STONE_PLACE"] = "0x12",
    ["QUARRY_STONE_LOWERED"] = "0x13",
    ["WARCRY"] = "0x14",
    ["QUARRY_WORKER_GRUNT"] = "0x15",
    ["DRAWBRIDGE_LOWERING"] = "0x16",
    ["DRAWBRIDGE_LOWERED"] = "0x17",
    ["DRAWBRIDGE_RAISING"] = "0x18",
    ["DRAWBRIDGE_RAISED"] = "0x19",
    ["DRAWBRIDGE_CONTROL"] = "0x1a",
    ["IRON_DUMP"] = "0x1b",
    ["IRON_LITTLE_DUMP"] = "0x1c",
    ["IRON_BOIL"] = "0x1d",
    ["IRON_POUR"] = "0x1e",
    ["IRON_PULL"] = "0x1f",
    ["IRON_WORKER_GRUNT"] = "0x20",
    ["FOOD_DEPOSIT"] = "0x21",
    ["ALE_DEPOSIT"] = "0x22",
    ["FLOUR_DEPOSIT"] = "0x23",
    ["IRON_DEPOSIT"] = "0x24",
    ["PITCH_DEPOSIT"] = "0x25",
    ["STONE_DEPOSIT"] = "0x26",
    ["SWORD_DEPOSIT"] = "0x27",
    ["WHEAT_DEPOSIT"] = "0x28",
    ["WOOD_DEPOSIT"] = "0x29",
    ["TREE_FALL"] = "0x2a",
    ["TREE_BREAK"] = "0x2b",
    ["BLACKSMITH_ANVIL"] = "0x2c",
    ["BLACKSMITH_BELLOW"] = "0x2d",
    ["BLACKSMITH_COOLING"] = "0x2e",
    ["UNKNOWN_0x2F"] = "0x2f",
    ["UNKNOWN_0x30"] = "0x30",
    ["BLACKSMITH_FILE"] = "0x31",
    ["BAKE_BIG"] = "0x32",
    ["BAKE_SMALL"] = "0x33",
    ["UNKNOWN_0x34"] = "0x34",
    ["PITCH_RIG_WATERLAP"] = "0x35",
    ["PITCH_RIG_SCOOP"] = "0x36",
    ["PITCH_RIG_POUR"] = "0x37",
    ["TANNER_LITTLE_CUT"] = "0x38",
    ["TANNER_BRUSH_UP"] = "0x39",
    ["TANNER_BRUSH_DOWN"] = "0x3a",
    ["FLETCHER_FLETCH"] = "0x3b",
    ["GHOST"] = "0x3c",
    ["UNKNOWN_0x3D"] = "0x3d",
    ["STIR"] = "0x3e",
    ["FIREPLACE"] = "0x3f",
    ["ARROW_BOUNCE"] = "0x40",
    ["SWORD_CLASH"] = "0x41",
    ["ENTER_TUNNEL"] = "0x9f",
    ["BABY_CRY"] = "0xa2",
    ["SWORD_HIT_WALL"] = "0xa3",
    ["SWORD_HIT_WOODEN_BUILDING"] = "0xa4",
    ["STONE_HIT_UNIT"] = "0xa5",
    ["COW_SPLASH_ON_GROUND"] = "0xa6",
    ["DEER_HERD_RUN_AWAY"] = "0xa7",
    ["BALLISTA_RELOAD"] = "0xa8",
    ["BALLISTA_SHOOT"] = "0xa9",
    ["BUILDING_DESTROYED"] = "0xaa",
    ["UNKNOWN_0xAB"] = "0xab",
    ["FIRE_ARROW_SHOOT"] = "0xac",
    ["SWORDSMAN_WALK"] = "0xad",
    ["SEVERAL_SWORDSMEN_WALK"] = "0xae",
    ["LOTS_SWORDSMEN_WALK"] = "0xaf",
    ["STONE_SPLASH_IN_WATER"] = "0xb0",
    ["UNKNOWN_0xB1"] = "0xb1",
    ["UNKNOWN_0xB2"] = "0xb2",
    ["SWORD_SHEATH_OUT_01"] = "0xb3",
    ["SWORD_SHEATH_OUT_02"] = "0xb4",
    ["BUTTON_CLICK_01"] = "0xb5",
    ["WOMAN_SCREAM_01"] = "0xb6",
    ["WOMAN_SCREAM_02"] = "0xb7",
    ["UNKNOWN_0xB8"] = "0xb8",
    ["MACE_KILL"] = "0xb9",
    ["PIKE_KILL"] = "0xba",
    ["SPEAR_KILL"] = "0xbb",
    ["SWORD_KILL"] = "0xbc",
    ["FLIES"] = "0xbd",
    ["HARVEST"] = "0xbe",
    ["PLOW"] = "0xbf",
    ["HOWL"] = "0xc0",
    ["DOG_RELEASE"] = "0xc1",
    ["COW_DEATH"] = "0xc2",
    ["UNKNOWN_0xC3"] = "0xc3",
    ["UNKNOWN_0xC4"] = "0xc4",
    ["JESTER_DEATH"] = "0xc5",
    ["PLAYER_LORD_DEATH"] = "0xc6",
    ["AI_LORD_DEATH"] = "0xc7",
    ["CROW"] = "0xc8",
    ["SEAGULL"] = "0xc9",
    ["UNKNOWN_0xCA"] = "0xca",
    ["FLAG_SMALL"] = "0xcb",
    ["FLAG_BIG"] = "0xcc",
    ["UKNOWN_0xCD"] = "0xcd",
    ["UKNOWN_0xCE"] = "0xce",
    ["CHAPEL_BELL"] = "0xcf",
    ["CHURCH_BELL"] = "0xd0",
    ["CATHEDRAL_BELL"] = "0xd1",
    ["STRETCHING_RACK"] = "0xd2",
    ["GALLOWS"] = "0xd3",
    ["DUNGEON"] = "0xd4",
    ["DUNKING_STOOL"] = "0xd5",
    ["DUNKING_STOOL_2"] = "0xd6",
    ["DUNKING_STOOL_3"] = "0xd7",
    ["DUNKING_STOOL_4"] = "0xd8",
    ["DUNKING_STOOL_5"] = "0xd9",
    ["DUNKING_STOOL_6"] = "0xda",
    ["UNKNOWN_0xDB"] = "0xdb",
    ["FIRE_OUT"] = "0xdc",
    ["SLAVE_FIRE"] = "0xdd",
    ["UNKNOWN_0xDE"] = "0xde",
    ["UNKNOWN_0xDF"] = "0xdf",
    ["GIRLY_SCREAM"] = "0xe0",
    ["LION_ROAR"] = "0xe1",
    ["UNKNOWN_0xE2"] = "0xe2",
    ["ASSASSIN_HOOK_HIT"] = "0xe3",
    ["UNKNOWN_0xE4"] = "0xe4",
    ["UNKNOWN_0xE5"] = "0xe5",
    ["UNKNOWN_0xE6"] = "0xe6",
    ["SLINGER_THROW"] = "0xe7",
    ["SLAVE_ATTACK"] = "0xe8",
    ["LORD_ATTACK"] = "0xe9",
    ["UNKNOWN_0xEA"] = "0xea",
    ["UNKNOWN_0xEB"] = "0xeb",
    ["UNKNOWN_0xEC"] = "0xec",
    ["FIRE_THROW"] = "0xed",
    ["SLING_DEATH"] = "0xee",
    ["SLING_HIT"] = "0xef"
}

namespace.playSFX_internal = core.exposeCode(namespace.SCANS["PLAY_SFX"], 2, 1)
namespace.playSFXAtLocation_internal = core.exposeCode(namespace.SCANS["PLAY_SFX_AT_LOCATION"], 4, 1)

return namespace