local writeCode = core.writeCode
local writeBytes = core.writeBytes
local AOBScan = core.AOBScan
local compile = core.compile
local calculateCodeSize = core.calculateCodeSize
local allocate = core.allocate
local allocateCode = core.allocateCode
local getRelativeAddress = core.getRelativeAddress
local relTo = core.relTo
local relToLabel = core.relToLabel
local byteRelTo = core.byteRelTo
local readInteger = core.readInteger

local itob = utils.itob
local smallIntegerToBytes = utils.smallIntegerToBytes

local COLORS = {
    ['red'] = 1,
    ['orange'] = 2,
    ['yellow'] = 3,
    ['blue'] = 4,
    ['black'] = 5,
    ['purple'] = 6,
    ['lightblue'] = 7,
    ['green'] = 8,
}

-- /*
-- PLAYER 1 COLOR
-- */
--____NEW CHANGE: o_playercolor
return {

    init = function(self, config)
        self.choice = config.choice or 'red'
        self.value = COLORS[self.choice] or 1
    
        -- 004AF3D0
        self.o_playercolor_table_drag_edit = AOBScan("8D 85 22 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 85 DB 0F 85 A2 00 00 00 8B 04 AD")
        -- 004AEFE9, TODO: not found!
        self.o_playercolor_table_back_edit = AOBScan("8D 96 22 02 00 00 52 6A 2E B9 ? ? ? ? E8 ? ? ? ? 85 FF 0F 85 84 00 00 00 8B 04 B5 ? ? ? ? 85 C0 75 14 A1 ? ? ? ? 8B 0D ? ? ? ? 50 51 68 1B 02 00 00 EB 79 83 F8 01 75 14 8B 15 ? ? ? ? A1 ? ? ? ? 52 50 68 1C 02 00 00 EB 60 83 3C B5 ? ? ? ? 00 7E 62 8B 0D ? ? ? ? 8B 15 ? ? ? ? 51 52 68 1D 02 00 00 6A 2E B9 ? ? ? ? E8 ? ? ? ? A1 ? ? ? ? 8B 0D ? ? ? ? 83 C0 04 50 83 C1 04 51 8D 56 13 52 B9 ? ? ? ? E8 ? ? ? ? EB 20 A1 ? ? ? ? 8B 0D ? ? ? ? 50 51 81 C7 0A 02 00 00 57 6A 2E B9 ? ? ? ? E8 ? ? ? ? 39 1D ? ? ? ? 75 1F A1 ? ? ? ? 8B 0D ? ? ? ? 8D 50 47 52 8D 51 47 52 50 51 B9 ? ? ? ? E8 ? ? ? ? 83 3D ? ? ? ? 00 74 49 83 3D ? ? ? ? 00 75 2D A1 ? ? ? ? 8B 0D")
        -- 004AF15A
        self.o_playercolor_table1_edit = AOBScan("8B 14 B5 ? ? ? ? 69 F6 FA 00 00 00 8B 04 95 ? ? ? ? 8B 0D ? ? ? ? 8B 15")
        -- 4DE26D
        self.o_playercolor_trail_name_edit = AOBScan("8B 0C B5 ? ? ? ? 8B 14 8D ? ? ? ? 8B 44 24 1C 8B 7C 24 20 53 53 6A 12 53 52 8B D6 69 D2")
        -- 004AF1A9
        self.o_playercolor_table2_edit = AOBScan("8B 04 B5 ? ? ? ? 8B 0C 85 ? ? ? ? 8B 15 ? ? ? ? 8B 04 B5 ? ? ? ? 8B 3D")
        -- 004D60B1 end results scoreboard
        self.o_playercolor_endscore_edit = AOBScan("8B 04 B5 ? ? ? ? 8B 0C 85 ? ? ? ? 8B 6C 24 1C 6A 00 8B D6 6B D2 5A 6A 12 6A 00 51 8D BA")
        -- 004AFCBD game over
        self.o_playercolor_gameover_edit = AOBScan("8B 07 8B 0C 85 ? ? ? ? 6A 00 6A 00 6A 12 6A 00 51 6A 01 56 8D 55 B2 52 53 B9 ? ? ? ? E8 ? ? ? ? 8B 07 8B 0C 85 ? ? ? ? A1 ? ? ? ? 99 2B C2 6A 00 D1 F8 6A 00 8D 44 28 B8 6A 12 EB 41 8B 0F 8B 14 8D ? ? ? ? 6A 00 6A 00 6A 11 6A 00 52 6A 01 56 8D 45 E4 50 53 B9 ? ? ? ? E8 ? ? ? ? A1 ? ? ? ? 8B 0F 8B 0C 8D")
        -- 004AE562 mightiest lord
        self.o_playercolor_scorename_edit = AOBScan("8B 04 B5 ? ? ? ? 8B 0C 85 ? ? ? ? 8B 44 24 18 6A 00 6A 12 6A 00 51 8B CE 6B C9 5A 68 04")
        -- 0047FA16
        self.o_playercolor_chat_edit = AOBScan("8B 14 8D ? ? ? ? 8B 0C 95 ? ? ? ? 6A 13 6A 00 51 6A 00 53 57 8D 94 30 ? ? ? ? 52 B9")
        -- 0047FAEE
        self.o_playercolor_chat2_edit = AOBScan("8B 14 8D ? ? ? ? 69 C0 FA 00 00 00 8B 0C 95 ? ? ? ? 6A 00 6A 01 6A 13 6A 00 51 6A 00 53")
        -- 004D8B05
        self.o_playercolor_trail_portrait_edit = AOBScan("8D 83 22 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 85 ED 75 78 8B 04 9D ? ? ? ? 85 C0")
        -- 004DE2C9
        self.o_playercolor_trail_shield2_edit = AOBScan("81 C6 D5 01 00 00 56 6A 2E B9 ? ? ? ? E8 ? ? ? ? 83 C5 01 83 FD 09 0F 8C 88 FE FF FF 5D")
        -- 004DDA5F
        self.o_playercolor_trail_shield_edit = AOBScan("81 C2 D6 01 00 00 52 6A 2E B9 ? ? ? ? E8 ? ? ? ? 83 C6 01 83 FE 08 7C B6 A1")
        -- 00448C78
        self.o_playercolor_minilist1_edit = AOBScan("57 56 55 6A 2E B9 ? ? ? ? E8 ? ? ? ? 8D 4F 02 51 8D 56 02 52 8D 85 45 FD FF FF 50 B9")
        -- 00448CC3
        self.o_playercolor_minilist2_edit = AOBScan("57 56 55 6A 2E B9 ? ? ? ? E8 ? ? ? ? 8B 4C 24 10 8B 11 57 56 81 C2 BC 02 00 00 52 6A 2E")
        -- 00428421
        self.o_playercolor_mm_shield_hover_edit = AOBScan("81 C2 D4 00 00 00 52 68 9C 00 00 00 B9 ? ? ? ? E8 ? ? ? 00 E9 F0 FE FF FF 8B 04 F5")
        -- 00428360
        self.o_playercolor_mm_shield_drag_edit = AOBScan("05 D6 01 00 00 50 6A 2E B9 ? ? ? ? C7 05 ? ? ? ? 00 00 00 00 E8 ? ? ? ? 83 3D")
        -- 0042845B
        self.o_playercolor_mm_shields_edit = AOBScan("81 C1 D6 01 00 00 51 6A 2E B9 ? ? ? ? E8 ? ? ? ? E9 ? ? ? ? CC CC CC CC CC CC CC CC")
        -- 004283C1
        self.o_playercolor_mm_emblem1_edit = AOBScan("05 CF 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 0F BE 96 ? ? ? ? 8B 04 95")
        -- 004282DD
        self.o_playercolor_mm_emblem2_edit = AOBScan("05 CF 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 0F BE 8E ? ? ? ? 8D 55 02 52 8D 47 02")
        -- 004BE94F
        self.o_playercolor_ai_video_message_shield_edit = AOBScan("50 52 C7 41 04 01 00 00 00 E8")
        -- 004B7B2C
        self.o_playercolor_ai_video_message_shield_pre_edit = AOBScan("8B 86 D4 00 00 00 89 86")
        -- 004B660A
        self.o_playercolor_ai_video_message_shield_enemy_taunt_edit = AOBScan("52 05 D5 01 00 00 50 6A 2E")
        -- 004B7E7F
        self.o_playercolor_ai_video_message_emblem_edit = AOBScan("55 53 05 22 02 00 00 50 6A 2E")
        -- 004AC8A5
        self.o_playercolor_ai_allied_menu_emblem_edit = AOBScan("85 F5 00 00 00 A1 ? ? ED 00 8B 0D ? ? ED 00 50 51 8D 96 22 02 00 00")
        -- 004ACEED
        self.o_playercolor_ai_allied_menu_attack_emblem_edit = AOBScan("33 05 CE 02 00 00 50 6A 2E E8")
        -- 004AD556
        self.o_playercolor_ai_order_menu_emblem_edit = AOBScan("ED 00 8D 51 47 52 50 51 B9 ?  ?  ?  ?  E8 ?  ?  FC FF E9 64 01 00 00 8B 34 B5 ?  42 DF 00 33 FF 83 3C B5 ?  ?  ?  ?  FF 75 07 ?  ?  ?  ?  ?  ?  ?  A1 ?  ?  ED 00 8B 0D ?  ?  ED 00 50 51 8D 96 22 02 00 00 52 6A 2E B9 90")
        -- 004ACC84
        self.o_playercolor_ai_allied_menu_ally_name_edit = AOBScan("8B 04 95 ?  ?  61 00 8B 35 ?  ?  ED 00 8B 3D ?  ?  ED 00 6A 00 6A 11 6A 00 50 83 C6 18 6A 00")
        -- 004B6CC3
        self.o_playercolor_minimap_edit = AOBScan("83 C2 D9 83 FA 26 0F 87 B3 00 00 00 0F B6 92 ? ? ? ? FF 24 95 ? ? ? ? 8B 0C 8D")
        -- 004B05CC
        self.o_playercolor_emblem1_edit = AOBScan("05 22 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 85 DB 75 62 8B 0D ? ? ? ? 8B 04 8D")
        -- 004B06EB
        self.o_playercolor_emblem2_edit = AOBScan("05 22 02 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 85 ED 75 6B 8B 0D ? ? ? ? 8B 04 8D")
        -- 00427CC2
        self.o_playercolor_list_edit = AOBScan("8D 86 D5 01 00 00 50 6A 2E B9 ? ? ? ? E8 ? ? ? ? 83 3C B5 ? ? ? ? FF 89 1D")
        -- 0044FC15
        self.o_playercolor_ingame_edit = AOBScan("83 3D ? ? ? ? 01 75 0C C7 05 ? ? ? ? 04 00 00 00 EB 13 83 3D ? ? ? ? 04 75 0A C7 05")
        -- 00451E03
        self.o_playercolor_fade_edit = AOBScan("A1 ? ? ? ? 83 EC 1C 83 F8 01 53 56 57 8B F1 75 07 B8 04 00 00 00 EB 0A 83 F8 04 75 0A B8 01")
        -- 004E7E45
        self.o_playercolor_trebuchet_edit = AOBScan("50 8B 44 24 14 0F BF C9 2B DA 53 50 03 CF 51 55 B9 ? ? ? ? E8 ? ? ? ? 83 3D")
    end,

    enable = function(self, config)
        
        -- new ColorHeader("o_playercolor")
        -- #region Round Table
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x8B, 0xC5,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8D, 0x80, 0x22, 0x02, 0x00, 0x00,  -- lea eax, [EAX + 222]
                    0xe9, relTo(self.o_playercolor_table_drag_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_table_drag_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8D, 0x90, 0x22, 0x02, 0x00, 0x00,  -- lea edx, [EAX + 222]
                    0xe9, relTo(self.o_playercolor_table_back_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_table_back_edit, code)
        local namecolors = readInteger(self.o_playercolor_trail_name_edit + 3)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8B, 0x14, 0x85,  -- mov edx, [eax*4 + namecolors]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_table1_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_table1_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8B, 0x04, 0x85,  -- mov eax, [eax*4 + namecolors]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_table2_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_table2_edit, code)
        -- #endregion
        -- #region scoreboards
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8B, 0x04, 0x85,  -- mov eax, [eax*4 + namecolors]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_endscore_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_endscore_edit, code)
        local someoffset = readInteger(self.o_playercolor_gameover_edit + 5)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                
                                0x8B, 0xC7, -- mov eax, edi
                                0x2D, itob(namecolors), -- sub eax, namecolors
                                0x3C, 0x04, --cmp al, value
                                0x75, 0x04, --  JNE SHORT
                                0xB0, (self.value*4) & 0xFF, --  MOV AL, value
                                0xEB, 0x06, --  JMP SHORT
                                0x3C, (self.value*4) & 0xFF, --  CMP AL, value
                                0x75, 0x02, --  JNE SHORT
                                0xB0, 0x04, --  MOV AL, 1
                                0x8B, 0x80, -- mov eax, [eax + namecolors]
                                itob(namecolors),
                                0x8B, 0x0C, 0x85, -- mov ecx, [eax*4 + someoffset]
                                itob(someoffset),
                                    0xe9, relTo(self.o_playercolor_gameover_edit + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_gameover_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                
                                0x8B, 0xC7, -- mov eax, edi
                                0x2D, itob(namecolors), -- sub eax, namecolors
                                0x3C, 0x04, --cmp al, value
                                0x75, 0x04, --  JNE SHORT
                                0xB0, (self.value*4) & 0xFF, --  MOV AL, value
                                0xEB, 0x06, --  JMP SHORT
                                0x3C, (self.value*4) & 0xFF, --  CMP AL, value
                                0x75, 0x02, --  JNE SHORT
                                0xB0, 0x04, --  MOV AL, 1
                                0x8B, 0x80, -- mov eax, [eax + namecolors]
                                itob(namecolors),
                                0x8B, 0x0C, 0x85, -- mov ecx, [eax*4 + someoffset]
                                itob(someoffset),
                                    0xe9, relTo(self.o_playercolor_gameover_edit + 9 + 0x1B + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_gameover_edit + 9 + 0x1B, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                
                                0x8B, 0xC7, -- mov eax, edi
                                0x2D, itob(namecolors), -- sub eax, namecolors
                                0x3C, 0x04, --cmp al, value
                                0x75, 0x04, --  JNE SHORT
                                0xB0, (self.value*4) & 0xFF, --  MOV AL, value
                                0xEB, 0x06, --  JMP SHORT
                                0x3C, (self.value*4) & 0xFF, --  CMP AL, value
                                0x75, 0x02, --  JNE SHORT
                                0xB0, 0x04, --  MOV AL, 1
                                0x8B, 0x80, -- mov eax, [eax + namecolors]
                                itob(namecolors),
                                0x8B, 0x14, 0x85, -- mov edx, [eax*4 + someoffset]
                                itob(someoffset),
                                    0xe9, relTo(self.o_playercolor_gameover_edit + 9 + 0x1B + 9 + 0x16 + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_gameover_edit + 9 + 0x1B + 9 + 0x16, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                
                                0x8B, 0xC7, -- mov eax, edi
                                0x2D, itob(namecolors), -- sub eax, namecolors
                                0x3C, 0x04, --cmp al, value
                                0x75, 0x04, --  JNE SHORT
                                0xB0, (self.value*4) & 0xFF, --  MOV AL, value
                                0xEB, 0x06, --  JMP SHORT
                                0x3C, (self.value*4) & 0xFF, --  CMP AL, value
                                0x75, 0x02, --  JNE SHORT
                                0xB0, 0x04, --  MOV AL, 1
                                0x8B, 0x80, -- mov eax, [eax + namecolors]
                                itob(namecolors),
                                0x8B, 0x14, 0x85, -- mov edx, [eax*4 + someoffset]
                                itob(someoffset),
                                    0xe9, relTo(self.o_playercolor_gameover_edit + 9 + 0x1B + 9 + 0x16 + 9 + 0x20 + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_gameover_edit + 9 + 0x1B + 9 + 0x16 + 9 + 0x20, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL, 1
                    0x8B, 0x04, 0x85,  -- mov eax, [eax*4 + varscore]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_scorename_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_scorename_edit, code)
        -- #endregion
        -- #region Chat
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xF9, 0x01,  -- CMP CL, 1
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB1, self.value & 0xFF,  -- MOV CL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xF9, self.value & 0xFF,  -- CMP CL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB1, 0x01,  -- MOV CL, 1
                    0x8B, 0x14, 0x8D,  -- mov edx, [ecx*4 + varscore]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_chat_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_chat_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xF9, 0x01,  -- CMP CL, 1
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB1, self.value & 0xFF,  -- MOV CL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xF9, self.value & 0xFF,  -- CMP CL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB1, 0x01,  -- MOV CL, 1
                    0x8B, 0x14, 0x8D,  -- mov edx, [ecx*4 + varscore]
                    itob(namecolors), 
                    0xe9, relTo(self.o_playercolor_chat2_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_chat2_edit, code)
        -- #endregion
        -- #region Trail
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x8B, 0xC3,  -- mov eax, ebx
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x05, 0x22, 0x02, 0x00, 0x00,  -- ADD EAX, 222
                    0xe9, relTo(self.o_playercolor_trail_portrait_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_trail_portrait_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x8B, 0xC6,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL, 1
                    0x05, 0xD5, 0x01, 0x00, 0x00,  -- add eax, 1D5
                    0x50,  -- push eax
                    0xe9, relTo(self.o_playercolor_trail_shield2_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_trail_shield2_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xFA, 0x00,  -- CMP DL, 0
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB2, (self.value-1) & 0xFF,  -- MOV DL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xFA, (self.value-1) & 0xFF,  -- CMP DL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB2, 0x00,  -- MOV DL, 0
                    0x81, 0xC2, 0xD6, 0x01, 0x00, 0x00,  -- ori code, ADD EDX, 1D6
                    0xe9, relTo(self.o_playercolor_trail_shield_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_trail_shield_edit, code)
        -- 4DE26D
        local namelabel = self.o_playercolor_trail_name_edit + 7
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- mov eax, esi
                    0x3C, 0x01,  -- CMP AL,1
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x01,  -- MOV AL,1
                    0x8B, 0x0C, 0x85,  -- mov ecx, [esi*4 + varscore]
                    itob(namecolors), 
                    0xe9, relTo(namelabel, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_trail_name_edit, code)
        -- #endregion
        -- #region Lineup menu
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x57, 0x56,  -- push edi, esi
                    0x8D, 0x85, 0x31, 0xFD, 0xFF, 0xFF,  -- lea eax, [ebp - 2CF]
                    0x3C, 0x00,  -- CMP AL, 0
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, (self.value-1) & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, (self.value-1) & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x00,  -- MOV AL, 0
                    0x05, 0xCF, 0x02, 0x00, 0x00,  -- add eax, 2CF
                    0x50,  -- push eax
                    0x6A, 0x2E,  -- push 2E
                    0xe9, relTo(self.o_playercolor_minilist1_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_minilist1_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x57, 0x56,  -- push edi, esi
                    0x8D, 0x85, 0x31, 0xFD, 0xFF, 0xFF,  -- lea eax, [ebp - 2CF]
                    0x3C, 0x00,  -- CMP AL, 0
                    0x75, 0x04,  -- JNE SHORT
                    0xB0, (self.value-1) & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT
                    0x3C, (self.value-1) & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT
                    0xB0, 0x00,  -- MOV AL, 0
                    0x05, 0xCF, 0x02, 0x00, 0x00,  -- add eax, 2CF
                    0x50,  -- push eax
                    0x6A, 0x2E,  -- push 2E
                    0xe9, relTo(self.o_playercolor_minilist2_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_minilist2_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xFA, 0x00,  -- CMP DL, 0
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB2, (self.value-1) & 0xFF,  -- MOV DL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xFA, (self.value-1) & 0xFF,  -- CMP DL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB2, 0x00,  -- MOV DL, 0
                    0x81, 0xC2, 0xD4, 0x00, 0x00, 0x00,  -- ori code, ADD EDX, D4
                    0xe9, relTo(self.o_playercolor_mm_shield_hover_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_mm_shield_hover_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x3C, 0x00,  -- CMP AL, 0
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, (self.value-1) & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, (self.value-1) & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x00,  -- MOV AL, 0
                    0x05, 0xD6, 0x01, 0x00, 0x00,  -- ori code, ADD EAX, 1D6
                    0xe9, relTo(self.o_playercolor_mm_shield_drag_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_mm_shield_drag_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xF9, 0x00,  -- CMP CL, 0
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB1, (self.value-1) & 0xFF,  -- MOV CL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xF9, (self.value-1) & 0xFF,  -- CMP CL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB1, 0x00,  -- MOV CL, 0
                    0x81, 0xC1, 0xD6, 0x01, 0x00, 0x00,  -- ori code, add ecx, 1D6
                    0xe9, relTo(self.o_playercolor_mm_shields_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_mm_shields_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x3C, 0x00,  -- CMP AL, 0
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, (self.value-1) & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, (self.value-1) & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x00,  -- MOV AL, 0
                    0x05, 0xCF, 0x02, 0x00, 0x00,  -- ori code, ADD EAX, 2CF
                    0xe9, relTo(self.o_playercolor_mm_emblem1_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_mm_emblem1_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x3C, 0x00,  -- CMP AL, 0
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, (self.value-1) & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, (self.value-1) & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x00,  -- MOV AL, 0
                    0x05, 0xCF, 0x02, 0x00, 0x00,  -- ori code, ADD EAX, 2CF
                    0xe9, relTo(self.o_playercolor_mm_emblem2_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_mm_emblem2_edit, code)
        -- #endregion
        -- #region ingame
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xFB, self.value & 0xFF,  -- CMP EBX, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xBB, 0x01, 0x00, 0x00, 0x00,  -- MOV EBX, 1
                    0x50, 0x52, 0xC7, 0x41, 0x04, 0x01, 0x00, 0x00, 0x00,  -- original code
                    0xe9, relTo(self.o_playercolor_ai_video_message_shield_edit + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_ai_video_message_shield_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x8B, 0x86, 0xD4, 0x00, 0x00, 0x00,  -- MOV EAX, [esi+D4]
                    0x83, 0xF8, self.value & 0xFF,  -- CMP EAX, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xB8, 0x01, 0x00, 0x00, 0x00,  -- MOV EAX, 1
                    0xe9, relTo(self.o_playercolor_ai_video_message_shield_pre_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_ai_video_message_shield_pre_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xF8, self.value & 0xFF,  -- CMP EAX, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xB8, 0x01, 0x00, 0x00, 0x00,  -- MOV EAX, 1
                    0x52, 0x05, 0xD5, 0x01, 0x00, 0x00,  -- original code
                    0xe9, relTo(self.o_playercolor_ai_video_message_shield_enemy_taunt_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_ai_video_message_shield_enemy_taunt_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xF8, self.value & 0xFF,  -- CMP EAX, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xB8, 0x01, 0x00, 0x00, 0x00,  -- MOV EAX, 1
                    0x55, 0x53, 0x05, 0x22, 0x02, 0x00, 0x00,  -- original code
                    0xe9, relTo(self.o_playercolor_ai_video_message_emblem_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_ai_video_message_emblem_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xFE, self.value & 0xFF,  -- CMP ESI, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xBE, 0x01, 0x00, 0x00, 0x00,  -- MOV ESI, 1
                    0x50, 0x51, 0x8D, 0x96, 0x22, 0x02, 0x00, 0x00,  -- original code
                    0xe9, relTo(self.o_playercolor_ai_allied_menu_emblem_edit + 0 + 16 + 8, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90
        }
        writeCode(self.o_playercolor_ai_allied_menu_emblem_edit + 0 + 16, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xF8, self.value & 0xFF,  -- CMP EAX, value
                    0x0F, 0x85, 0x05, 0x00, 0x00, 0x00,  -- JNE SHORT 5
                    0xB8, 0x01, 0x00, 0x00, 0x00,  -- MOV EAX,1
                    0x05, 0xCE, 0x02, 0x00, 0x00,  -- ADD EAX,2CE
                    0xe9, relTo(self.o_playercolor_ai_allied_menu_attack_emblem_edit + 0 + 1 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_ai_allied_menu_attack_emblem_edit + 0 + 1, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xFE, self.value & 0xFF,  -- CMP ESI, value
                    0x0F, 0x85, 0x0B, 0x00, 0x00, 0x00,  -- JNE SHORT 11h
                    0x8D, 0x15, 0x23, 0x02, 0x00, 0x00,  -- LEA edx,[00000223]
                    0xEB, 0x09, 0x90, 0x90, 0x90,  -- JMP SHORT 9
                    0x8D, 0x96, 0x22, 0x02, 0x00, 0x00,  -- LEA edx,[00000223]
                    0xe9, relTo(self.o_playercolor_ai_order_menu_emblem_edit + 0 + 62 + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_ai_order_menu_emblem_edit + 0 + 62, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x51,  -- PUSH EAX
                    0xB9, self.value & 0xFF, 0x00, 0x00, 0x00,  -- MOV ECX, value
                    0x83, 0xF9, 0x01,  -- CMP ECX, 1
                    0x0F, 0x84, 0x97, 0x00, 0x00, 0x00,  -- JE SHORT 97h
                    0x83, 0xF9, 0x07,  -- CMP ECX, 7
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x07, 0x00, 0x00, 0x00,  -- MOV ECX, 7
                    0xE9, 0x72, 0x00, 0x00, 0x00,  -- JMP SHORT 72h
                    0x83, 0xF9, 0x08,  -- CMP ECX, 8
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x08, 0x00, 0x00, 0x00,  -- MOV ECX, 8
                    0xE9, 0x5F, 0x00, 0x00, 0x00,  -- JMP SHORT 5Fh
                    0x83, 0xF9, 0x06,  -- CMP ECX, 6
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x05, 0x00, 0x00, 0x00,  -- MOV ECX, 5
                    0xE9, 0x4C, 0x00, 0x00, 0x00,  -- JMP SHORT 4Ch
                    0x83, 0xF9, 0x02,  -- CMP ECX, 2
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x03, 0x00, 0x00, 0x00,  -- MOV ECX, 3
                    0xE9, 0x39, 0x00, 0x00, 0x00,  -- JMP SHORT 39h
                    0x83, 0xF9, 0x03,  -- CMP ECX, 3
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x04, 0x00, 0x00, 0x00,  -- MOV ECX, 4
                    0xE9, 0x26, 0x00, 0x00, 0x00,  -- JMP SHORT 26h
                    0x83, 0xF9, 0x04,  -- CMP ECX, 4
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x02, 0x00, 0x00, 0x00,  -- MOV ECX, 2
                    0xE9, 0x13, 0x00, 0x00, 0x00,  -- JMP SHORT 13h
                    0x83, 0xF9, 0x05,  -- CMP ECX, 5
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xB9, 0x06, 0x00, 0x00, 0x00,  -- MOV ECX, 6
                    0xE9, 0x00, 0x00, 0x00, 0x00,  -- JMP SHORT 0
                    0x39, 0xCA,  -- CMP EDX,ECX
                    0x0F, 0x85, 0x0A, 0x00, 0x00, 0x00,  -- JNE SHORT 0Ah
                    0xBA, 0x01, 0x00, 0x00, 0x00,  -- MOV EDX, 1
                    0xE9, 0x00, 0x00, 0x00, 0x00,  -- JMP SHORT 0
                    0x8B, 0x0D, 0x7C, 0x50, 0x61, 0x00,  -- MOV ECX,0061507C
                    0x83, 0xF9, 0x00,  -- CMP ECX,00
                    0x75, 0x0C,  -- JNE SHORT C
                    0x8B, 0x04, 0x95, 0x0C, 0x52, 0x61, 0x00,  -- extreme
                    0xE9, 0x07, 0x00, 0x00, 0x00,  -- JMP SHORT 7
                    0x8B, 0x04, 0x95, 0x7C, 0x50, 0x61, 0x00,  -- original
                    0x59,  -- POP ECX
                    0xe9, relTo(self.o_playercolor_ai_allied_menu_ally_name_edit + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_playercolor_ai_allied_menu_ally_name_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0xF9, 0x01,  -- CMP CL, 1
                    0x75, 0x04,  -- JNE SHORT 2. CMP
                    0xB1, self.value & 0xFF,  -- MOV CL, value
                    0xEB, 0x07,  -- JMP SHORT END
                    0x80, 0xF9, self.value & 0xFF,  -- CMP CL, value
                    0x75, 0x02,  -- JNE SHORT END
                    0xB1, 0x01,  -- MOV CL, 1
                    0x83, 0xC2, 0xD9, 0x83, 0xFA, 0x26,  -- ori code
                    0xe9, relTo(self.o_playercolor_minimap_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_minimap_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x05, 0x22, 0x02, 0x00, 0x00,  -- ADD EAX, 222
                    0xe9, relTo(self.o_playercolor_emblem1_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_emblem1_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x05, 0x22, 0x02, 0x00, 0x00,  -- ADD EAX, 222
                    0xe9, relTo(self.o_playercolor_emblem2_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_emblem2_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x89, 0xF0,  -- MOV EAX, ESI
                    0x3C, 0x01,  -- CMP AL, 1
                    0x75, 0x04,  -- JNE SHORT 00427CD2
                    0xB0, self.value & 0xFF,  -- MOV AL, value
                    0xEB, 0x06,  -- JMP SHORT 00427CD8
                    0x3C, self.value & 0xFF,  -- CMP AL, value
                    0x75, 0x02,  -- JNE SHORT 00427CD8
                    0xB0, 0x01,  -- MOV AL, 1
                    0x05, 0xD5, 0x01, 0x00, 0x00,  -- ADD EAX, 1D5
                    0xe9, relTo(self.o_playercolor_list_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_playercolor_list_edit, code)
        local var = readInteger(self.o_playercolor_ingame_edit + 2) -- [ED3158]
        local code = {
            0xA1,  -- mov eax, [var]
            itob(var), 
            0x3C, 0x01,  -- cmp al, 1
            0x75, 0x04,  -- jne to next cmp
            0xB0,  -- mov al, value
            self.value & 0xFF, 
            0xEB, 0x06,  -- jmp to end
            0x3C,  -- cmp al, value
            self.value & 0xFF, 
            0x75, 0x02,  -- jne to end
            0xB0, 0x01,  -- mov al, 1
         -- end
            0x3C, 0x01,  -- cmp al, 1
            0x75, 0x04,  -- jne to next cmp
            0xB0, 0x04,  -- mov al, 4
            0xEB, 0x06,  -- jmp to end
            0x3C, 0x04,  -- cmp al, 4
            0x75, 0x02,  -- jne to end
            0xB0, 0x01,  -- mov al, 1
         -- end
            0xA3,  -- mov [var], eax
            itob(var), 
            0x90, 0x90, 
        }
        writeCode(self.o_playercolor_ingame_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0xA1,  -- mov eax, [var]
                    itob(var), 
                    0x3C, 0x01,  -- cmp al, 1
                    0x75, 0x04,  -- jne to next cmp
                    0xB0,  -- mov al, value
                    self.value & 0xFF, 
                    0xEB, 0x06,  -- jmp to end
                    0x3C,  -- cmp al, value
                    self.value & 0xFF, 
                    0x75, 0x02,  -- jne to end
                    0xB0, 0x01,  -- mov al, 1
                 -- end
                    0xe9, relTo(self.o_playercolor_fade_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_fade_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x50,  -- ori code: push eax
                    0xA1,  -- mov eax, [var]
                    itob(var), 
                    0x3C, 0x01,  -- cmp al, 1
                    0x75, 0x04,  -- jne to next cmp
                    0xB0,  -- mov al, value
                    self.value & 0xFF, 
                    0xEB, 0x06,  -- jmp to end
                    0x3C,  -- cmp al, value
                    self.value & 0xFF, 
                    0x75, 0x02,  -- jne to end
                    0xB0, 0x01,  -- mov al, 1
                 -- end
                    0xA3,  -- mov [var], eax
                    itob(var), 
                 -- ori code
                    0x8B, 0x44, 0x24, 0x14,  -- mov eax, [esp+14]
                    0xe9, relTo(self.o_playercolor_trebuchet_edit + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_playercolor_trebuchet_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}