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
-- EXTENDED GAME SPEED 
-- */ 
--____NEW CHANGE: o_gamespeed
return {

    init = function(self, config)
        -- 4B4748
        self.o_gamespeed_up_edit = AOBScan("83 F8 5A 0F 8D ? ? ? ? 83 C0 05 83 F8 5A A3 ? ? ? ? 7E 0A C7 05 ? ? ? ? 5A 00 00 00")
        -- 004B47C2
        self.o_gamespeed_down_edit = AOBScan("0F 8E 0B F4 FF FF 83 E8 05 BF 14 00 00 00 3B C7 A3 ? ? ? ? 7D 8F 89 3D ? ? ? ? EB 87 3D")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_gamespeed")
        local label1 = self.o_gamespeed_up_edit + 23
        local code = {
            0x3D, 0x10, 0x27, 0x00, 0x00,  -- cmp eax, 10000
            0x7D, 0x19,  -- jge to end
            0x89, 0xC7,  -- mov edi, eax
            0x3d, 0xc8, 0x00, 0x00, 0x00,  -- cmp eax, 200
            0x0F, 0x8C, function(address, index, labels)
                local hook = { -- jl hook
                    0x83, 0xF8, 0x5a,  -- cmp eax, 90
                    0x7C, 0x3,  -- jl to end
                    0x83, 0xC7, 0x5,  -- add edi, 5
                    0xe9, relTo(label1, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x83, 0xC7, 0x5f,  -- add edi, 95
        }
        writeCode(self.o_gamespeed_up_edit, code)
        local code = {
            0x83, 0xC7, 0x5,  -- add edi, 5
            0xEB, 0x75,  -- jmp to gamespeed_down set value
            0x90, 0x90, 0x90, 0x90, 
        }
        writeCode(self.o_gamespeed_up_edit + 23, code)
        local label2 = self.o_gamespeed_down_edit + 18
        local code = {
            0x7E, 0x1b,  -- jle to end
            0x89, 0xC7,  -- mov edi, eax
            0x3d, 0xc8, 0x00, 0x00, 0x00,  -- cmp eax, 200
            0x0F, 0x8E, function(address, index, labels)
                local hook = { -- jle hook
                    0x83, 0xF8, 0x5a,  -- cmp eax, 90
                    0x7E, 0x3,  -- jle to end
                    0x83, 0xEF, 0x5,  -- sub edi, 5
                    0xe9, relTo(label2, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x83, 0xEF, 0x5f,  -- sub edi, 95
        }
        writeCode(self.o_gamespeed_down_edit, code)
        local code = {
            0x83, 0xEF, 0x5,  -- sub edi, 5
            0x90, 0x90, 
        }
        writeCode(self.o_gamespeed_down_edit + 18, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
