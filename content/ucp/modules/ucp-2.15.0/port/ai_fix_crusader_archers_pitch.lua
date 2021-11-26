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

-- Fix AI crusader archers not lighting pitch
--____NEW CHANGE: ai_fix_crusader_archers_pitch
return {

    init = function(self, config)
        self.ai_fix_crusader_archers_pitch_fn_edit = AOBScan("51 83 3d ? ? ? ? 00 89 0C 24")
        self.ai_fix_crusader_archers_pitch_attr_edit = AOBScan("B8 22 00 00 00 66 89")
        self.ai_fix_crusader_archers_pitch_edit = AOBScan("8B 0D ? ? ? ? 74 3C 8B C1 69 C0 90 04 00 00 C6 80 ? ? ? ? 01 0F B7 80 ? ? ? ?")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_fix_crusader_archers_pitch")
        local CheckFunction = self.ai_fix_crusader_archers_pitch_fn_edit + 0
        local UnitAttributeOffset = readInteger(self.ai_fix_crusader_archers_pitch_attr_edit + 43)
        local CurrentTargetIndex = readInteger(self.ai_fix_crusader_archers_pitch_edit + 2)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x55,  -- push ebp
                    0x51,  -- push ecx
                    0xBE, 0x5B, 0x00, 0x00, 0x00,  -- mov esi,5B
                    0xE8, function(index) return itob(getRelativeAddress(index, CheckFunction, -4)) end, 
                    0xA1, itob(CurrentTargetIndex), 
                    0x69, 0xC0, 0x90, 0x04, 0x00, 0x00,  -- imul eax,eax,490
                    0x0F, 0xB7, 0x80, itob(UnitAttributeOffset), 
                    0xe9, relTo(self.ai_fix_crusader_archers_pitch_edit + 0 + 23 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.ai_fix_crusader_archers_pitch_edit + 0 + 23, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
