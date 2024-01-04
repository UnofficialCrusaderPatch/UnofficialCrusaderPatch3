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

-- AI Fix laddermen with enclosed keep
--____NEW CHANGE: ai_fix_laddermen_with_enclosed_keep
return {

    init = function(self, config)
        -- 5774A
        self.ai_fix_laddermen_with_enclosed_keep_edit = AOBScan("6A 00 51 0F BF D0")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_fix_laddermen_with_enclosed_keep")
        local code = {
            0x6A, 0x01, 
        }
        writeCode(self.ai_fix_laddermen_with_enclosed_keep_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
