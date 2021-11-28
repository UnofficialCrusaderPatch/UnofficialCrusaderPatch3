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

-- /*
-- ONLY AI / SPECTATOR MODE
-- */
--____NEW CHANGE: o_onlyai
return {

    init = function(self, config)
        -- 0048F919
        self.o_onlyai_reset_edit = AOBScan("89 3D ? ? ? ? 89 3D ? ? ? ? E8 ? ? ? ? 8B 15 ? ? ? ? 83 C4 0C C7 04 95")
        -- 0048F96C => je to jmp to almost end
        self.o_onlyai_edit = AOBScan("0F 84 24 01 00 00 83 3D ? ? ? ? 63 75 03 57 EB 07 8B 0D ? ? ? ? 51 B9 ? ? ? ? E8")
        -- 004956FB
        self.o_onlyai_load1_edit = AOBScan("75 07 8B C5 A3 ? ? ? ? 89 2C 85 ? ? ? ? 83 3D ? ? ? ? 63 0F 85 BA 00 00 00 A1")
        -- 0x4334A6
        self.o_onlyai_face_edit = AOBScan("8B 8E ? ? ? ? B8 ? ? ? ? F7 E9 C1 FA 05 8B C2 C1 E8 1F 03 C2 B9 64 00 00 00 2B C8 B8 67")
        -- 004EA265
        self.o_onlyai_assassins_edit = AOBScan("74 ? 8B 8E ? ? ? ? 81 F9 A0 00 00 00 7E ? 0F B7 86 ? ? ? ? 66 3D 6A 00 74 ? 66 3D 6B")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_onlyai")
        -- reset player list
        local selfindex = readInteger(self.o_onlyai_reset_edit + 2)
        local selfai = readInteger(self.o_onlyai_reset_edit + 8)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x31, 0xC0,  -- xor eax, eax
                    0xA3, itob(selfindex), 
                    0x83, 0xE8, 0x1,  -- sub eax, 1
                    0xA3, itob(selfai), 
                    0xe9, relTo(self.o_onlyai_reset_edit + 12, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_onlyai_reset_edit, code)
        -- game start
        local code = {
            0xE9, 0x09, 0x01, 0x00, 0x00, 0x90
        }
        writeCode(self.o_onlyai_edit, code)
        -- loading
        local code = {
         -- => mov [selfindex], eax   to   mov [selfindex], ebx = 0
            0x90, 0x90, 0x90, 0x89, 0x1D, 
        }
        writeCode(self.o_onlyai_load1_edit, code)
        local code = {
            0x3C,  -- mov ..., ebp  => mov ..., edi
        }
        writeCode(self.o_onlyai_load1_edit + 5 + 5, code)
        -- missing in 1.3
        -- after loading, hide buildings menu
        -- 0046B3FA => mov ecx, [selfindex]   to   xor ecx, ecx
        -- BinBytes.CreateEdit("o_onlyai_load2", 0x31, 0xC9, 0x90, 0x90, 0x90, 0x90),
        -- happy face :)
        local code = {
            0xB9, 0xD3, 0x13, 0x00, 0x00, 0x90
        }
        writeCode(self.o_onlyai_face_edit, code)
        -- show assassins
        -- change je to jmp
        local code = {
            0xEB
        }
        writeCode(self.o_onlyai_assassins_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
