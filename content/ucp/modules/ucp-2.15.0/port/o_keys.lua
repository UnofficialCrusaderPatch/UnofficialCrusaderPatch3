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

-- #endregion
-- /*
-- WASD
-- */
--____NEW CHANGE: o_keys
return {

    init = function(self, config)
        -- 495800
        self.o_keys_savefunc_edit = AOBScan("8B 44 24 04 F7 D8 1B C0 83 E0 0E 83 C0 20 6A 0E B9 ? ? ? ? A3 ? ? ? ? E8 ? ? ? ? C7")
        -- 004697C0
        self.o_keys_savename_edit = AOBScan("83 79 04 00 75 03 33 C0 C3 8B 01 69 C0 ? ? ? ? 8D 84 08 ? ? ? ? C3")
        -- 004B3B5C S key
        self.o_keys_s_edit = AOBScan("A1 ? ? ? ? 8B 0C 85 ? ? ? ? 3B CB 74 2B 8B C1 69 C0 2C 03 00 00 0F BF 88")
        -- 0046C2E0
        self.o_keys_loadname_edit = AOBScan("8B 44 24 04 3D F4 01 00 00 7C 05 33 C0 C2 04 00 69 C0 ? ? ? ? 8D 84 08 ? ? ? ? C2 04 00")
        -- 004B3DAE L key
        self.o_keys_l_edit = AOBScan("39 1D ? ? ? ? 75 63 8B 0D ? ? ? ? 8B C1 69 C0 F4 39 00 00 8B 80 ? ? ? ? 3B C3")
        self.o_keys_down_edit = AOBScan("10 11 12 28 13 28 14 15 16 28 28 17 18 19 28 1A 1B 28 1C 1D 28 1E 1F 20 28 21 28 28 28 28 28 22")
        -- 004B4C9F
        self.o_keys_up_edit = AOBScan("83 C0 DB 83 F8 03 0F 87 ? ? ? ? FF 24 85 ? ? ? ? 89 1D ? ? ? ? E9 ? ? ? ? 89 1D")
        self.o_keys_menu_edit = AOBScan("B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 85 C0 A1 ? ? ? ? 74 48 83 F8 FF 75 43 39 1D")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_keys")
        local theSelf = readInteger(self.o_keys_savefunc_edit + 17)
        local c1 = readInteger(self.o_keys_savefunc_edit + 22)
        local func = self.o_keys_savefunc_edit + 27 + 4 + readInteger(self.o_keys_savefunc_edit + 27)
        local savefunc = self.o_keys_savefunc_edit + 50 + 4 + readInteger(self.o_keys_savefunc_edit + 50)
        local code = {
         -- 0x20 == save, 0x1F == load
        }
        writeCode(self.o_keys_savefunc_edit, code)
        local code = {
                0x8B, 0x44, 0x24, 0x04,  -- mov eax, [esp+4]
                0xA3, itob(c1),  -- mov [c1], eax
                0xB9, itob(theSelf),  -- mov ecx, theSelf
                0x6A, 0x0E,  -- push E
                0xE8, function(index) return itob(getRelativeAddress(index, func, -4)) end,  -- call func
                0xE9, function(index) return itob(getRelativeAddress(index, savefunc, -4)) end,  -- jmp to save
        }
        local DoSave = allocateCode(calculateCodeSize(code))
        writeCode(DoSave, code)
        local namebool = allocate(1)
        local code = {
             -- "Quicksave\0"
                0x51, 0x75, 0x69, 0x63, 0x6b, 0x73, 0x61, 0x76, 0x65, 0x00, 
        }
        local name = allocate(calculateCodeSize(code))
        writeBytes(name, compile(code,name))
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0x3D, itob(namebool), 0x00,  -- cmp byte ptr [namebool], 0
                    0x74, 0x6,  -- je to ori code
                    0xB8, itob(name),  -- mov eax, quicksave
                    0xC3,  -- ret
                 -- ori code:
                    0x83, 0x79, 0x04, 0x00, 0x75, 0x03, 0x33, 0xC0, 0xC3, 
                    0xe9, relTo(self.o_keys_savename_edit + 0 + 0 + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_keys_savename_edit + 0 + 0, code)
        local ctrl = readInteger(self.o_keys_s_edit + 0x106) -- 4B3C60
        local code = {
            0x39, 0x1D, itob(ctrl),  -- cmp [ctrlpressed], ebx = 0
            0x0F, 0x84, 0xFA, 0xF3, 0xFF, 0xFF,  -- jmp to move if equal
            0xC6, 0x05, itob(namebool), 0x01, 
            0x6A, 0x20,  -- push 0x20
            0xE8, function(index) return itob(getRelativeAddress(index, DoSave, -4)) end,  -- call save func
            0xC6, 0x05, itob(namebool), 0x00, 
            0x58,  -- pop eax
            0xEB, 0x53,  -- jmp to default/end 4B3BD3
        }
        writeCode(self.o_keys_s_edit, code)
        local someoffset = readInteger(self.o_keys_loadname_edit + 25)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x80, 0x3D, itob(namebool), 0x00,  -- cmp byte ptr [namebool], 0
                    0x74, 0x8,  -- je to ori code
                    0xB8, itob(name),  -- mov eax, quicksave
                    0xC2, 0x04, 0x00,  -- ret
                 -- ori code:
                    0x8B, 0x44, 0x24, 0x04, 0x3D, 0xF4, 0x01, 0x00, 0x00, 
                    0xe9, relTo(self.o_keys_loadname_edit + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_keys_loadname_edit, code)
        local somevar = readInteger(self.o_keys_l_edit + 0x02)
        local default = self.o_keys_l_edit + 0x20 + 4 + readInteger(self.o_keys_l_edit + 0x20)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x39, 0x1D, itob(ctrl),  -- cmp [ctrlpressed], ebx = 0
                    0x74, 0x1b,  -- je to ori code
                    0xC6, 0x05, itob(namebool), 0x01, 
                    0x6A, 0x1F,  -- push 0x1F
                    0xE8, function(index) return itob(getRelativeAddress(index, DoSave, -4)) end,  -- call save func
                    0xC6, 0x05, itob(namebool), 0x00, 
                    0x58,  -- pop eax
                    0xE9, function(index) return itob(getRelativeAddress(index, default, -4)) end,  -- jump awayy
                 -- ori code
                    0x39, 0x1D, itob(somevar), 
                    0xe9, relTo(self.o_keys_l_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_keys_l_edit, code)
        -- WASD
        -- Arrow Keys: 4b4ee4 + 1D => 9, A, B, C
        -- WASD Keys: 4b4ee4 + 39, 4F, 3C, 4B
        local code = {
         -- 4b4ee4 + 39
            0x09, 
        }
        writeCode(self.o_keys_down_edit, code)
        local code = {
            0x0B, 
         -- new BinSkip(0x0E),
         -- new BinBytes(0x0C),
        }
        writeCode(self.o_keys_down_edit + 1 + 0x02, code)
        local code = {
            0x0A, 
        }
        writeCode(self.o_keys_down_edit + 1 + 0x02 + 1 + 0x03 + 0x0E + 1, code)
        -- WASD
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xC0, 0xDB,  -- add eax, -25
                 -- 1C left => 0
                 -- 32 top => 1
                 -- 1F right => 2
                 -- 2E down => 3
                    0x83, 0xF8, 0x1c,  -- cmp eax, 1C
                    0x75, 0x4,  -- jne to next
                    0x31, 0xC0,  -- xor eax, eax
                    0xEB, 0x1c,  -- jmp to end
                    0x83, 0xF8, 0x32,  -- cmp eax, 32
                    0x75, 0x5,  -- jne to next
                    0x8D, 0x40, 0xCF,  -- lea eax, [eax-31]
                    0xEB, 0x12,  -- jmp to end
                    0x83, 0xF8, 0x1f,  -- cmp eax, 1F
                    0x75, 0x5,  -- jne to next
                    0x8D, 0x40, 0xE3,  -- lea eax, [eax-1D]
                    0xEB, 0x8,  -- jmp to end
                    0x83, 0xF8, 0x2e,  -- cmp eax, 2E
                    0x75, 0x3,  -- jne to end 
                    0x8D, 0x40, 0xD5,  -- lea eax, [eax-2B]
                 -- end
                    0x83, 0xF8, 0x3,  -- cmp eax, 3
                    0xe9, relTo(self.o_keys_up_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_keys_up_edit, code)
        local callright = self.o_keys_menu_edit + 6 + 4 + readInteger(self.o_keys_menu_edit + 6)
        local callleft = self.o_keys_menu_edit + 0x93 + 4 + readInteger(self.o_keys_menu_edit + 0x93)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xFE, 0x44, 
                    0x74, 0x5, 
                    0xE8, function(index) return itob(getRelativeAddress(index, callright, -4)) end, 
                    0xe9, relTo(self.o_keys_menu_edit + 0 + 5 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_keys_menu_edit + 0 + 5, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xFE, 0x41, 
                    0x74, 0x5, 
                    0xE8, function(index) return itob(getRelativeAddress(index, callleft, -4)) end, 
                    0xe9, relTo(self.o_keys_menu_edit + 0 + 5 + 5 + 0x88 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_keys_menu_edit + 0 + 5 + 5 + 0x88, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
