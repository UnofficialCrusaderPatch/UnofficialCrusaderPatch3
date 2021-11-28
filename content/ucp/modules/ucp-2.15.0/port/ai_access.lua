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
-- DISABLE DEMOLISHING OF INACCESSIBLE BUILDINGS
-- */
-- 004242C3
--____NEW CHANGE: ai_access
return {

    init = function(self, config)
        self.ai_access_edit = AOBScan("75 07 66 C7 06 03 00 EB 12 83 F8 02 75 07 66 C7 06 03 00 EB 06 66 83 3E 03 75 14 0F BF 56 20 0F")
    end,

    enable = function(self, config)
        
        local code = {
            0xEB
        }
        writeCode(self.ai_access_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
