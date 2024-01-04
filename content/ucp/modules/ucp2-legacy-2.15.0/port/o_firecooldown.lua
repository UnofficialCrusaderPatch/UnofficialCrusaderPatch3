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
-- FIRE COOLDOWN
-- */
-- 0x00410A30 + 8 ushort default = 2000
--____NEW CHANGE: o_firecooldown
return {

    init = function(self, config)
        self.value = config.sliderValue or 2000
        
        self.o_firecooldown_edit = AOBScan("66 C7 84 30 D8 02 00 00 D0 07 0F B7 80 ? ? ? ? 66 3D 1E 00 89 4C 24 18 75 05 8D 5F 09 EB 25")
    end,

    enable = function(self, config)
        
        -- new SliderHeader("o_firecooldown", true, 0, 20000, 500, 2000, 4000)
        local code = {
            self.value & 0xFF, (self.value >> 8) & 0xFF, -- short value
        }
        writeCode(self.o_firecooldown_edit + 0 + 8, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}