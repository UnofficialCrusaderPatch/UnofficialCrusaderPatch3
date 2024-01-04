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
-- Fletcher bugfix 
-- */
--____NEW CHANGE: o_fix_fletcher_bug
return {

    init = function(self, config)
        self.o_fix_fletcher_bug_edit = AOBScan("E8 ? ? ? ? 85 C0 74 19 A1 ? ? ? ? 69 C0 90 04 00 00 5F 5E 5D 66 C7 80 ? ? ? ? 03 00 5B C3")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fix_fletcher_bug")
        -- skip 30 bytes
        local code = {
            0x01,  -- set state to 1 instead of 3
        }
        writeCode(self.o_fix_fletcher_bug_edit + 0 + 0x1E, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
