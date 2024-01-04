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
-- FIRE BALLISTAS ATTACK MONKS AND TUNNELERS
-- */
--____NEW CHANGE: u_fireballistafix
return {

    init = function(self, config)
        self.u_fireballistatunneler_edit = AOBScan("83 F8 25 75 4C")
        self.u_fireballistamonk_edit = AOBScan("04 04 02 02 02 04 04 04 04 04 04 04 04 04 04 04 04 04 03 04 04 02 02 02 02 04 04 04 04 04 04 04")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_fireballistafix")
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xF8, 0x5,  -- cmp eax,05
                    0x66, 0x9C,  -- pushf
                    0x83, 0xC0, 0xEA,  -- add eax,-0x16
                    0x66, 0x9D,  -- popf
                    0x75, 0x5,  -- jne short 5
                    0xB8, 0x05, 0x00, 0x00, 0x00,  -- mov eax,05
                    0x83, 0xF8, 0x37,  -- cmp eax,37
                    0xe9, relTo(self.u_fireballistatunneler_edit + 0 + 13 + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.u_fireballistatunneler_edit + 0 + 13, code)
        local code = {
            0x00, 
        }
        writeCode(self.u_fireballistamonk_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
