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

--____NEW CHANGE: o_disable_border_scrolling
return {

    init = function(self, config)
        -- 004681CF
        self.o_disable_border_scrolling_edit = AOBScan("7F 06 89 1D ? ? ? ? 8B 15 ? ? ? ?")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_disable_border_scrolling")
        local code = {
            0xEB, 0x38, 
        }
        writeCode(self.o_disable_border_scrolling_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
