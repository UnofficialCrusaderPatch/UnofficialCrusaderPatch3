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

--____NEW CHANGE: o_default_multiplayer_speed
return {

    init = function(self, config)
        self.value = config.sliderValue or 40
        
        -- 878FB
        self.o_default_multiplayer_speed_edit = AOBScan("C7 87 ? ? ? ? 64 00 00 00 C7 87 ? ? ? ? 28 00 00 00 C7 87 ? ? ? ? 03 00 00 00")
        self.o_default_multiplayer_speed_reset_edit = AOBScan("C7 86 ? ? ? 00 28 00 00 00 89 AE ? ? ? 00")
    end,

    enable = function(self, config)
        
        -- new SliderHeader("o_default_multiplayer_speed", true, 20, 90, 1, 40, 50)
        local code = {
            (self.value) & 0xFF, 
        }
        writeCode(self.o_default_multiplayer_speed_edit + 0 + 16, code)
        local code = {
            (self.value) & 0xFF, 
        }
        writeCode(self.o_default_multiplayer_speed_reset_edit + 0 + 6, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}