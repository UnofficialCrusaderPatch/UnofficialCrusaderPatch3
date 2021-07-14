
local scanForAOB = core.scanForAOB
local readInteger = core.readInteger
local isHost = data.common.isHost
local SCANS = data.common.SCANS
local numberOfAIsInLobby = data.common.numberOfAIsInLobby
local numberOfPlayersInLobby = data.common.numberOfPlayersInLobby
local writeInteger = core.writeInteger
local queueCommand = data.common.queueCommand
local readByte = core.readByte
local writeByte = core.writeByte
local playSFXAtLocation = data.common.playSFXAtLocation
local exposeCode = core.exposeCode
local detourCode = core.detourCode
local writeCode = core.writeCode
local allocate = core.allocate
local getCurrentGameMode = data.common.getCurrentGameMode
local copyMemory = core.copyMemory
local createLuaFunctionWrapper = core.createLuaFunctionWrapper
local SOUND_EFFECT = data.common.SOUND_EFFECT

local menu = {}
local currentPlayerSlot = 1


local roundTableAOB = scanForAOB("74 ? 8B C7 B9 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A2 ? ? ? ? E8")
local roundTableHandle = readInteger(roundTableAOB+5)
local refreshRoundTableFn = roundTableAOB+25+readInteger(roundTableAOB+25)+4

menu.randomSkirmishMap = function (registers)
	if isHost() then
		local numberOfPlayers = numberOfAIsInLobby() + numberOfPlayersInLobby()
		local maxTries = 100
		local mapAvailableArrayPointer = SCANS["MAP_AVAILABLE_ARRAY_POINTER"]
		local mapSelectionPreloadMapIndexMappingPointer = SCANS["MAP_SELECTION_PRELOAD_MAP_INDEX_MAPPING_POINTER"]
		local i
		local offset
		local relativeOffset
		
		if numberOfPlayers > 1 then
			for i = 0,maxTries,1 do
				relativeOffset = math.floor(math.random()*8)
				offset = math.floor(math.random()*(readInteger(SCANS["MAP_SELECTION_SCROLL_MAX_OFFSET"])-8))
				
				if readInteger(mapAvailableArrayPointer+(4*readInteger(mapSelectionPreloadMapIndexMappingPointer+(4*(relativeOffset+offset))))) == 1 then
					writeInteger(SCANS["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"], relativeOffset)
					writeInteger(SCANS["MAP_SELECTION_SCROLL_OFFSET"], offset)
					queueCommand(0x2F)
					break
				end
			end
		else
			writeInteger(SCANS["MAP_SELECTION_SCROLL_RELATIVE_OFFSET"], math.floor(math.random()*8))
			writeInteger(SCANS["MAP_SELECTION_SCROLL_OFFSET"], math.floor(math.random()*(readInteger(SCANS["MAP_SELECTION_SCROLL_MAX_OFFSET"])-8)))
			queueCommand(0x2F)
		end
	end
	
	return registers
end

menu.randomTeams = function (registers)
	if isHost then
		local numberOfPlayers = numberOfAIsInLobby() + numberOfPlayersInLobby()
		local i
		local j
		local positionArrayRef = SCANS["LOBBY_GROUP_ARRAY"]-9
		
		if numberOfPlayers > 1 then
			for i = 0, 8, 1 do
				if readByte(SCANS["LOBBY_GROUP_ARRAY"]+i) ~= 255 then
					writeByte(SCANS["LOBBY_GROUP_ARRAY"]+i, math.min(math.floor(math.random()*numberOfPlayers), 4))
				end
			end
			
			menu.reorderRoundTable(roundTableHandle)
			playSFXAtLocation(0,0,SOUND_EFFECT["SWORD_CLASH"])
		end
	end
	
	return registers
end

-- Changes slot of the player
menu.playerSlotChange = function (registers)
	if isHost() then
		local originalSlot = currentPlayerSlot
		currentPlayerSlot = currentPlayerSlot + 1
		
		if currentPlayerSlot > 8 then
			currentPlayerSlot = 1
		end
		
		menu.menuSkirmishChoiceClick(2)
	end
	
	return registers
end

menu.forcePlayerIntoSlotInSkirmish = function (registers)
	-- if skirmish
	if modules.ui.getCurrentMenuID() == 20 and getCurrentGameMode() == 0x63 then
		registers.EDI = currentPlayerSlot
	end
	return registers
end

menu.onShow = function ()
	
end

menu.onInit = function ()
--math.randomseed(os.time())
	exposeCode("menuSkirmishChoiceClick", SCANS["MENU_SKIRMISH_CHOICE_CLICK_CALLBACK"], 1, 0, menu)
	exposeCode("reorderRoundTable", refreshRoundTableFn, 1, 1, menu)
	-- Find some nasty code
	detourCode(menu.forcePlayerIntoSlotInSkirmish, scanForAOB("83 3D ? ? ? ? 63 75 ? 57 EB ? 8B 0D ? ? ? ? 51"), 7)
	writeCode(scanForAOB("83 FE FF 74 ? 3B F3 74 ? 83 C0 01"), {0x39, 0xD8, 0x90})

	local skirmishMenuUIElementArrayPointer = allocate(8192)
	local skirmishMenuUIHandle = readInteger(SCANS["SKIRMISH_MENU_UI_ELEMENT_ARRAY"]+76)

	-- Add map randomizer
	writeInteger(skirmishMenuUIElementArrayPointer+0, 0x00000003) -- type
	writeInteger(skirmishMenuUIElementArrayPointer+4, 0x00000240) -- x
	writeInteger(skirmishMenuUIElementArrayPointer+8, 0x00000220) -- y
	writeInteger(skirmishMenuUIElementArrayPointer+12, 0x000000B4) -- width (auto calculated)
	writeInteger(skirmishMenuUIElementArrayPointer+16, 0x000000B4) -- height (auto calculated)
	writeInteger(skirmishMenuUIElementArrayPointer+20, createLuaFunctionWrapper("randomSkirmishMap", menu)) -- click function reference
	writeInteger(skirmishMenuUIElementArrayPointer+24, 0x00000002) -- fn parameter
	writeInteger(skirmishMenuUIElementArrayPointer+28, 0x0042AE90) -- menu item render function
	writeInteger(skirmishMenuUIElementArrayPointer+32, 0x40000202) -- (2bytes) unknown 1 -- (2bytes) button graphic
	writeInteger(skirmishMenuUIElementArrayPointer+36, 0x00000003) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+40, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+44, 0x00000000) -- (2bytes) hover label text index -- (2bytes) unknown
	writeInteger(skirmishMenuUIElementArrayPointer+48, 0x0000FFF0) -- (2bytes) is hovering -- (2bytes) unknown
	writeInteger(skirmishMenuUIElementArrayPointer+52, 0x00000000) -- is clicked
	writeInteger(skirmishMenuUIElementArrayPointer+56, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+60, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+64, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+68, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+72, 0x00000045) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+76, skirmishMenuUIHandle) -- menu pointer

	-- Add slot change
	writeInteger(skirmishMenuUIElementArrayPointer+80, 0x00000003) -- type
	writeInteger(skirmishMenuUIElementArrayPointer+84, 0x00000010) -- x
	writeInteger(skirmishMenuUIElementArrayPointer+88, 0x000001A0) -- y
	writeInteger(skirmishMenuUIElementArrayPointer+92, 0x000000B4) -- width (auto calculated)
	writeInteger(skirmishMenuUIElementArrayPointer+96, 0x000000B4) -- height (auto calculated)
	writeInteger(skirmishMenuUIElementArrayPointer+100, createLuaFunctionWrapper("playerSlotChange", menu)) -- click function reference
	writeInteger(skirmishMenuUIElementArrayPointer+104, 0x00000002) -- fn parameter
	writeInteger(skirmishMenuUIElementArrayPointer+108, 0x0042AE90) -- menu item render function
	writeInteger(skirmishMenuUIElementArrayPointer+112, 0x4000023F) -- (2bytes) unknown 1 -- (2bytes) button graphic
	writeInteger(skirmishMenuUIElementArrayPointer+116, 0x00000003) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+120, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+124, 0x00000000) -- (2bytes) hover label text index -- (2bytes) unknown
	writeInteger(skirmishMenuUIElementArrayPointer+128, 0x0000FFF0) -- (2bytes) is hovering -- (2bytes) unknown
	writeInteger(skirmishMenuUIElementArrayPointer+132, 0x00000000) -- is clicked
	writeInteger(skirmishMenuUIElementArrayPointer+136, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+140, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+144, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+148, 0x00000000) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+152, 0x00000045) -- unknown
	writeInteger(skirmishMenuUIElementArrayPointer+156, skirmishMenuUIHandle) -- menu pointer
	--writeInteger(skirmishMenuUIElementArrayPointer+156, 0x00B97478) -- menu pointer

	copyMemory(skirmishMenuUIElementArrayPointer+160, SCANS["SKIRMISH_MENU_UI_ELEMENT_ARRAY"], 7364)

	-- hijack skirmish menu's button array ref
	writeInteger(SCANS["SKIRMISH_MENU_UI_ELEMENT_ARRAY_REFERENCE"], skirmishMenuUIElementArrayPointer)
	---------------------------------------------------------------------------
	-------------------------------ROUND TABLE---------------------------------
	---------------------------------------------------------------------------
	
	local roundTableUIElementArrayPointer = allocate(4096)
	local roundTableUIHandle = readInteger(SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY"]+76)

	-- Add map randomizer
	writeInteger(roundTableUIElementArrayPointer+0, 0x00000003) -- type
	writeInteger(roundTableUIElementArrayPointer+4, 0x00000020) -- x
	writeInteger(roundTableUIElementArrayPointer+8, 0x00000140) -- y
	writeInteger(roundTableUIElementArrayPointer+12, 0x000000B4) -- width (auto calculated)
	writeInteger(roundTableUIElementArrayPointer+16, 0x000000B4) -- height (auto calculated)
	writeInteger(roundTableUIElementArrayPointer+20, createLuaFunctionWrapper("randomTeams", menu)) -- click function reference
	writeInteger(roundTableUIElementArrayPointer+24, 0x00000002) -- fn parameter
	writeInteger(roundTableUIElementArrayPointer+28, 0x0042AE90) -- menu item render function
	writeInteger(roundTableUIElementArrayPointer+32, 0x40000202) -- (2bytes) unknown 1 -- (2bytes) button graphic
	writeInteger(roundTableUIElementArrayPointer+36, 0x00000003) -- unknown
	writeInteger(roundTableUIElementArrayPointer+40, 0x00000000) -- unknown
	writeInteger(roundTableUIElementArrayPointer+44, 0x00000000) -- (2bytes) hover label text index -- (2bytes) unknown
	writeInteger(roundTableUIElementArrayPointer+48, 0x0000FFF0) -- (2bytes) is hovering -- (2bytes) unknown
	writeInteger(roundTableUIElementArrayPointer+52, 0x00000000) -- is clicked
	writeInteger(roundTableUIElementArrayPointer+56, 0x00000000) -- unknown
	writeInteger(roundTableUIElementArrayPointer+60, 0x00000000) -- unknown
	writeInteger(roundTableUIElementArrayPointer+64, 0x00000000) -- unknown
	writeInteger(roundTableUIElementArrayPointer+68, 0x00000000) -- unknown
	writeInteger(roundTableUIElementArrayPointer+72, 0x00000045) -- unknown
	writeInteger(roundTableUIElementArrayPointer+76, roundTableUIHandle) -- menu pointer
	
	copyMemory(roundTableUIElementArrayPointer+80, SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY"], 1924)
	
	-- hijack round table's button array ref
  if SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] == 0 then
    SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] = readInteger(SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY"]+76)
  end
  if SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"] == 0 then
    error("AOB: ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE could not be found")
  end
	writeInteger(SCANS["ROUND_TABLE_UI_ELEMENT_ARRAY_REFERENCE"], roundTableUIElementArrayPointer)
  
  menu.initialized = true
end


return menu