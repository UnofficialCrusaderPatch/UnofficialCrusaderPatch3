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

-- Fix baker disappear bug
--____NEW CHANGE: o_fix_baker_disappear
return {

    init = function(self, config)
        -- 5774A
        self.o_fix_baker_disappear_edit = AOBScan("5E 5D 5B C3 8B 0D ? ? ? ? 69 C9 90 04 00 00 5F 5E 5D 66 C7 81 ? ? ? ? 03 00 5B C3")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fix_baker_disappear")
        local code = {
            0x90, 0x90, 0x90, 
            0x90, 0x90, 0x90, 
            0x90, 0x90, 0x90, 
        }
        writeCode(self.o_fix_baker_disappear_edit + 0 + 19, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
