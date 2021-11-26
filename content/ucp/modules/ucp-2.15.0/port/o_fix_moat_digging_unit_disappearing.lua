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

-- Fix moat digging unit disappearing
--____NEW CHANGE: o_fix_moat_digging_unit_disappearing
return {

    init = function(self, config)
        self.o_fix_moat_digging_unit_disappearing_edit = AOBScan("66 83 bc 30 a8 06 00 00 01")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fix_moat_digging_unit_disappearing")
        local skip = readInteger(self.o_fix_moat_digging_unit_disappearing_edit + 11)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xBC, 0x30, 0xD4, 0x08, 0x00, 0x00, 0x7D,  -- cmp dword ptr [eax+esi+8D4],7D
                    0x74, 0x09,  -- je short 9
                    0x66, 0x83, 0xBC, 0x30, 0xA8, 0x06, 0x00, 0x00, 0x01, 
                    0xe9, relTo(self.o_fix_moat_digging_unit_disappearing_edit + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_fix_moat_digging_unit_disappearing_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
