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
-- OX TETHER SPAM
-- */
-- 004EFF9A => jne to jmp
--____NEW CHANGE: ai_tethers
return {

    init = function(self, config)
        self.ai_tethers_edit = AOBScan("0F 85 B0 00 00 00 8B 86 ? ? ? ? 8B 8E ? ? ? ? 8B 15 ? ? ? ? 50 51 8B CE 89 54 24 18")
    end,

    enable = function(self, config)
        
        local code = {
            0x90, 0xE9
        }
        writeCode(self.ai_tethers_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
