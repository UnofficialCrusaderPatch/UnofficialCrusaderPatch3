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

-- Armbrustschaden gegen Arab. Schwertkämpfer, original: 8000
-- 0xB4EE4C = 0x4B*4 + 0xB4ED20
--____NEW CHANGE: u_arabxbow
return {

    init = function(self, config)
        self.u_arabxbow_edit = AOBScan("40 1F 00 00 40 1F 00 00 F4 01 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 00 00 02 00 00 00")
    end,

    enable = function(self, config)
        
        local code = {
            itob(3500)
        }
        writeCode(self.u_arabxbow_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
