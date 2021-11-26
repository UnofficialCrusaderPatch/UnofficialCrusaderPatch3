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

-- 4FA620
--____NEW CHANGE: fix_apple_orchard_build_size
return {

    init = function(self, config)
        self.fix_apple_orchard_build_size_edit = AOBScan("05 02 06 04 07 07 08 0D 0D 05 02 0D 0D 0D 09 09 08 0A")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("fix_apple_orchard_build_size")
        local code = {
            0x0A,  -- this is not the size, it is the ID in the switch case!
        }
        writeCode(self.fix_apple_orchard_build_size_edit + 0 + 16, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
