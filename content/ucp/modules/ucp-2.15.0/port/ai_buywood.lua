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
-- IMPROVE WOOD BUYING
-- */ 
-- 00457DF4
--____NEW CHANGE: ai_buywood
return {

    init = function(self, config)
        self.ai_buywood_edit = AOBScan("3B 9E ? ? ? ? 7E 58 8B 44 24 10 5F 89 9E ? ? ? ? 5E 5D 5B 83 C4 18 C2 0C 00")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_buywood")
        local offset = readInteger(self.ai_buywood_edit + 2)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xC3, 0x2,  -- add ebx, 2
                    0x3B, 0x9E, itob(offset),  -- ori code, cmp ebx, [esi+offset]
                    0xe9, relTo(self.ai_buywood_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.ai_buywood_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
