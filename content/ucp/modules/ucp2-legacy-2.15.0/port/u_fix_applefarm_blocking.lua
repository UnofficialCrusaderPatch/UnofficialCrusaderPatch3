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

--____NEW CHANGE: u_fix_applefarm_blocking
return {

    init = function(self, config)
        -- 4F36B2
        self.u_fix_applefarm_blocking_edit = AOBScan("8B 4C 24 1C 85 C9 89 47 18 75 0D 83 47 14 FE 5F 5D 8B C2 5B 59 C2 0C 00")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_fix_applefarm_blocking")
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x81, 0x47, 0x14, 0x02, 0x00, 0x00, 0x00,  -- add [edi+14],00000002
                    0x81, 0x47, 0x18, 0x02, 0x00, 0x00, 0x00,  -- add [edi+18],00000002
                    0x5F,  -- pop edi
                    0xe9, relTo(self.u_fix_applefarm_blocking_edit + 0 + 11 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.u_fix_applefarm_blocking_edit + 0 + 11, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
