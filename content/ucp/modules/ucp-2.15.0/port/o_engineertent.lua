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
-- SIEGE EQUIPMENT BUILDING
-- */
-- 0044612B
-- nop out: mov [selection], ebp = 0
--____NEW CHANGE: o_engineertent
return {

    init = function(self, config)
        self.o_engineertent_edit = AOBScan("89 2D ? ? ? ? 5D 5B 83 C4 08 C3 57 55 B9 ? ? ? ? C7 05 ? ? ? ? 02 00 00 00 E8")
    end,

    enable = function(self, config)
        
        local code = {
            0x90, 0x90, 0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_engineertent_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
