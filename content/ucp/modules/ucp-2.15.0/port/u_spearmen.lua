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

-- Lanzenträger hp: 10000
--____NEW CHANGE: u_spearmen
return {

    init = function(self, config)
        self.u_spearbow_edit = AOBScan("AC 0D 00 00 E8 03 00 00 E8 03 00 00 96 00 00 00 96 00 00 00 E8 03 00 00 D0 07 00 00 98 3A 00 00")
        -- B4EAA0 + 4 * 18   (vanilla = 3500)
        self.u_spearxbow_edit = AOBScan("98 3A 00 00 B8 0B 00 00 88 13 00 00 98 08 00 00 C4 09 00 00 C4 09 00 00 10 27 00 00 98 3A 00 00")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_spearmen")
        -- B4EAA0 + 4 * 18   (vanilla = 3500)
        local code = {
            itob(2000)
        }
        writeBytes(self.u_spearbow_edit, compile(code,self.u_spearbow_edit))
        -- B4EBE0 + 4 * 18   (vanilla = 15000)
        local code = {
            itob(9999)
        }
        writeBytes(self.u_spearxbow_edit, compile(code,self.u_spearxbow_edit))
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
