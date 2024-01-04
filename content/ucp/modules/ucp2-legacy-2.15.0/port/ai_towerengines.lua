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
-- UNLIMITED SIEGE ENGINES ON TOWERS
-- */
-- 004D20A2
--____NEW CHANGE: ai_towerengines
return {

    init = function(self, config)
        self.ai_towerengines_edit = AOBScan("7E 0A C7 44 24 24 03 00 00 00 EB 12 3B FD 0F 8E 0B 03 00 00 EB 08 8D A4 24 00 00 00 00 90 8B 80")
    end,

    enable = function(self, config)
        
        local code = {
            0xEB
        }
        writeCode(self.ai_towerengines_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
