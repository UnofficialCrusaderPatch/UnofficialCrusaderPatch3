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
-- NO ASSAULT SWITCHES
-- */
--____NEW CHANGE: ai_assaultswitch
return {

    init = function(self, config)
        -- 4D3B41
        self.ai_recruitinterval_edit = AOBScan("8B 84 AA 64 01 00 00 8B E8 F7 DD 1B ED 83 C5 02 84 C9 89 6C 24 1C 74 07 83 C5 01 89 6C 24 1C 8B")
        -- 004D477B
        self.ai_assaultswitch_edit = AOBScan("8B 44 24 1C 8B 4C 24 20 8B 96 D0 FC FF FF 50 8B 86 CC FC FF FF 51 52 50 B9 ? ? ? ? E8")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_assaultswitch")
        local code = {
         -- 4d3c1a
        }
        local order = readInteger(self.ai_recruitinterval_edit + 0xD9 + 2)
        local target = readInteger(self.ai_assaultswitch_edit + 0x15E)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xBB,  -- cmp [ebx+order], 3
                    itob(order), 
                    0x03, 0x7C, 0x12, 0x39, 0xBB,  -- jl, cmp [ebx+target], edi
                    itob(target), 
                    0x75, 0x0A, 
                    0x5F, 0x5E, 0x5D, 0x5B, 0x83, 0xC4, 0x20, 0xC2, 0x04, 0x00,  -- ret
                    0x8B, 0x44, 0x24, 0x1C, 0x8B, 0x4C, 0x24, 0x20,  -- ori code
                    0xe9, relTo(self.ai_assaultswitch_edit + 8, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90
        }
        writeCode(self.ai_assaultswitch_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
