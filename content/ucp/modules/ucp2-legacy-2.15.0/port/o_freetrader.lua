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
-- FREE TRADER POST
-- */
-- trader post: runtime 01124EFC
-- 005C23D8
--____NEW CHANGE: o_freetrader
return {

    init = function(self, config)
        self.o_freetrader_edit = AOBScan("05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 1E 00 00 00 00 00 00 00 00 00 00 00 0A 00 00 00 00 00 00 00 64 00 00 00 0A 00 00 00")
    end,

    enable = function(self, config)
        
        local code = {
            0x00
        }
        writeCode(self.o_freetrader_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
