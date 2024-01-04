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
-- EXTREME
-- */
--____NEW CHANGE: o_xtreme
return {

    init = function(self, config)
        -- 0057CAC5 disable manabar rendering
        self.o_xtreme_bar1_edit = AOBScan("B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 53 B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 53 B9 ? ? ? ? E8 ? ? ? ? B9")
        -- 4DA3E0 disable manabar clicks
        self.o_xtreme_bar2_edit = AOBScan("A1 ? ? ? ? 85 C0 74 12 83 F8 63 74 0D 83 3D ? ? ? ? 00 0F 85 F2 00 00 00 A1")
        -- 486530 disable manabar network function
        self.o_xtreme_bar3_edit = AOBScan("51 a1 ? ? ? ? 83 F8 01 C7 05 ? ? ? ? 08 00 00 00 75 40")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_xtreme")
        local code = {
            0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_xtreme_bar1_edit, code)
        local code = {
            0xC3
        }
        writeCode(self.o_xtreme_bar2_edit, code)
        local code = {
            0xC3
        }
        writeCode(self.o_xtreme_bar3_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
