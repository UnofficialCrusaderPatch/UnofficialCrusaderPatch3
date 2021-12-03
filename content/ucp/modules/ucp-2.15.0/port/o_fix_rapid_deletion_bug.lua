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

--____NEW CHANGE: o_fix_rapid_deletion_bug
return {

    init = function(self, config)
        -- 0048201B
        self.o_fix_rapid_deletion_bug_edit = AOBScan("8B 86 ? ? F9 00 0F BF 8E ? ? F9 00 0F BF 96 ? ? F9 00 57 6A 00")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fix_rapid_deletion_bug")
        local label = self.o_fix_rapid_deletion_bug_edit + -4 + 4 + readInteger(self.o_fix_rapid_deletion_bug_edit + -4)
        local offset = readInteger(self.o_fix_rapid_deletion_bug_edit + 2)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0xBA, itob(offset),  -- mov edx, offset
                    0x8D, 0x52, 0xD8,  -- lea edx, [edx-28]
                    0x66, 0x8B, 0x14, 0x32,  -- mov dx, [esi+edx]
                    0x66, 0x83, 0xFA, 0x03,  -- cmp dx, 3
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, label, -4)) end,  -- je label
                 -- originalcode
                    0x8B, 0x86, itob(offset),  -- mov eax, [esi+offset]
                    0xe9, relTo(self.o_fix_rapid_deletion_bug_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.o_fix_rapid_deletion_bug_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
