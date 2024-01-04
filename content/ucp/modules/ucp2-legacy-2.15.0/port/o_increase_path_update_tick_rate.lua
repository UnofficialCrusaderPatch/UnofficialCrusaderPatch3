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

--____NEW CHANGE: o_increase_path_update_tick_rate
return {

    init = function(self, config)
        -- 499605
        self.o_increase_path_update_tick_rate_edit = AOBScan("3B C1 A3 ? ? ? ? 7E 0A 5E 33 C0 5B 8B E5 5D C2 04 00 C7 05 ? ? ? ? C8 00 00 00 39 4E 6C")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_increase_path_update_tick_rate")
        local code = {
            0x32, 
        }
        writeCode(self.o_increase_path_update_tick_rate_edit + 0 + 25, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
