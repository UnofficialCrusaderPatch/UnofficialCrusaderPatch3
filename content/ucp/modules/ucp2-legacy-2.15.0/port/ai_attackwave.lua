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
-- IMPROVED ATTACKS
-- */ 
--____NEW CHANGE: ai_attackwave
return {

    init = function(self, config)
        -- 0x524633
        self.ai_attackwave_edit = AOBScan("E8 ? ? ? ? 85 C0 0F 84 70 01 00 00 81 7C 24 2C 14 04 00 00 8B 35 ? ? ? ? 8B 2D")
        -- 0051EF25
        self.ai_attackwave_wallcount_edit = AOBScan("8B 4C 24 18 55 E8 ? ? ? ? 85 C0 0F 85 3B 01 00 00 A1 ? ? ? ? 8D 0C C7 8B 04 8D")
        -- 4D31CD
        self.ai_attackwave_lord_edit = AOBScan("75 49 85 D2 74 45 3D BA 00 00 00 74 3E 8B C2 69 C0 90 04 00 00 0F BF 88 ? ? ? ? 0F BF 80")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_attackwave")
        local walls = self.ai_attackwave_edit + 1 + 4 + readInteger(self.ai_attackwave_edit + 1)
        local buildings = self.ai_attackwave_edit + 0x1C7 + 4 + readInteger(self.ai_attackwave_edit + 0x1C7)
        local towers = self.ai_attackwave_edit + 0x20F + 4 + readInteger(self.ai_attackwave_edit + 0x20F)
        local var_type = allocate(4)
        local back = self.ai_attackwave_edit + 0 + 5
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x8B, 0x1D,  -- mov ebx,[var]
                    itob(var_type), 
                    0x83, 0xFB, 0x4,  -- cmp ebx,04
                    0x7D, 0x7,  -- jge to next cmp
                    0xE8,  -- call find wall
                    function(index) return itob(getRelativeAddress(index, walls, -4)) end, 
                    0xEB, 0x11,  -- jmp to inc
                    0x83, 0xFB, 0x6,  -- cmp ebx,06
                    0x7D, 0x7,  -- jge to last call
                    0xE8,  -- call find fortifications
                    function(index) return itob(getRelativeAddress(index, towers, -4)) end, 
                    0xEB, 0x5,  -- jmp to inc
                    0xE8,  -- call find building
                    function(index) return itob(getRelativeAddress(index, buildings, -4)) end, 
                    0x43,  -- inc ebx
                    0x83, 0xFB, 0x7,  -- cmp ebx,7
                    0x7C, 0x2,  -- jl to mov
                    0x31, 0xDB,  -- xor ebx,ebx
                    0x89, 0x1D,  -- mov [var], ebx
                    itob(var_type), 
                    0xe9, relTo(back, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.ai_attackwave_edit + 0, code)
        local code = {
            0xEB, 0x10,  -- skip check if wallpart is taken
        }
        writeCode(self.ai_attackwave_wallcount_edit, code)
        local code = {
            0x90, 0x90, 0x90, 0x90, 0x90,  -- skip check if wallpart is broken
            0x90, 0x90, 0x90, 0x90, 0x90, 
            0x90, 0x90, 0x90, 
        }
        writeCode(self.ai_attackwave_wallcount_edit + 2 + 0x21, code)
        local code = {
            0x90, 0x90,  -- when a breach happens, send most troops to enemy lord
        }
        writeCode(self.ai_attackwave_lord_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
