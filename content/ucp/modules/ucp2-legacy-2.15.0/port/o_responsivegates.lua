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
-- GATES
-- */ 
--____NEW CHANGE: o_responsivegates
return {

    init = function(self, config)
        -- 0x422ACC + 2
        self.o_gatedistance_edit = AOBScan("C8 00 00 00 7C 61 8B 4C 24 28 8B 44 24 2C 83 C6 01 83 C0 02 83 C5 04 3B F1 89 44 24 2C 7C 83 66")
        -- 0x422B35 + 7 (ushort)
        self.o_gatetime_edit = AOBScan("B0 04 80 BF ? ? ? ? 00 75 CE 6A 00 C6 87 ? ? ? ? 0A 66 C7 87 ? ? ? ? 0A 00 6A 00 EB")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_responsivegates")
        -- Gates closing distance to enemy = 200
        local code = {
            itob(140)
        }
        writeCode(self.o_gatedistance_edit, code)
        -- Gates closing time after enemy leaves = 1200
        local code = {
            smallIntegerToBytes(100)
        }
        writeCode(self.o_gatetime_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
