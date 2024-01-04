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

-- Fix tanner going back to her hut without cow
-- Block starts: 559C49
--____NEW CHANGE: u_tanner_fix
return {

    init = function(self, config)
        self.u_tanner_fix_edit = AOBScan("85 C0 0F 84 A7 0B 00 00 0F BF 9E ? ? ? ? 3B DD 0F 84 E7 00 00 00 8B 8E ? ? ? ? 8B EB 69 ED 90 04 00 00 3B 8D ? ? ? ? 0F 85 CD 00 00 00 66 83 BD ? ? ? ? 00")
    end,

    enable = function(self, config)
        
        -- 559C7A
        -- new DefaultHeader("u_tanner_fix")
        local unitBaseAddress = readInteger(self.u_tanner_fix_edit + 52)
        -- 49
        local someCowData = readInteger(self.u_tanner_fix_edit + 0 + 37 + 2)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x81, 0xBD, itob(someCowData), 0x00, 0x00, 0x00, 0x00,  -- cmp [ebp+someCowData],00000000
                    0x75, 0x0E,  -- jne 0x0E
                    0x66, 0xC7, 0x86, itob(unitBaseAddress), 0x01, 0x00,  -- mov word ptr [esi+unitBaseAddress],0001
                    0x5F,  -- pop edi
                    0x5E,  -- pop esi
                    0x5D,  -- pop ebp
                    0x5B,  -- pop ebx
                    0xC3,  -- ret
                    0x3B, 0x8D, itob(someCowData),  -- cmp ecx,[ebp+someCowData]
                    0xe9, relTo(self.u_tanner_fix_edit + 0 + 37 + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.u_tanner_fix_edit + 0 + 37, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x66, 0x83, 0xBD, itob(unitBaseAddress), 0x00,  -- cmp word ptr [ebp+unitBaseAddress],00
                    0x74, 0x19,  -- je short 0x19
                    0x66, 0x81, 0xBE, itob(unitBaseAddress), 0x02, 0x00,  -- cmp word ptr [esi+unitBaseAddress],0002
                    0x75, 0x0E,  -- jne short 0x0E
                    0x66, 0xC7, 0x86, itob(unitBaseAddress), 0x01, 0x00,  -- mov word ptr [esi+unitBaseAddress],0001
                    0x5F,  -- pop edi
                    0x5E,  -- pop esi
                    0x5D,  -- pop ebp
                    0x5B,  -- pop ebx
                    0xC3,  -- ret
                    0xe9, relTo(self.u_tanner_fix_edit + 0 + 37 + 6 + 6 + 8, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90
        }
        writeCode(self.u_tanner_fix_edit + 0 + 37 + 6 + 6, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
