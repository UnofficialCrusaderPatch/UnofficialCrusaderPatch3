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

-- Arab. Schwertkämpfer Angriffsanimation, ca. halbiert
-- 0xB59CD0
--____NEW CHANGE: u_arabwall
return {

    init = function(self, config)
        self.u_arabwall_edit = AOBScan("01 1C 1B 1A 19 19 1A 1B 1C 01 02 03 04 04 05 06 07 08 09 0A 0B 0B 0C 0D 0D 0E 0E 0F 10 11 12 12")
    end,

    enable = function(self, config)
        
        local code = {
            
            0x01, 0x02, 0x03, 0x04, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 
            0x10, 0x11, 0x12, 0x13, 0x14, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x00
        }
        writeBytes(self.u_arabwall_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
