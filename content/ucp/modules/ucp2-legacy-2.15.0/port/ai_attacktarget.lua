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
-- ALWAYS ATTACK NEAREST NEIGHBOR
-- */ 
-- 004D47B2
--____NEW CHANGE: ai_attacktarget
return {

    init = function(self, config)
        self.choice = config.choice or 'nearest'
        self.ai_attacktarget_edit = AOBScan("83 F8 04 75 33 83 3C BD ? ? ? ? FF 0F 84 82 00 00 00 A1 ? ? ? ? 3B 44 24 10 7F 77 89 44")
    end,

    enable = function(self, config)
        
        if self.choice == 'nearest' then
            -- new DefaultHeader("ai_attacktarget_nearest", true)
            local code = {
                0xEB, 0x11, 0x90
            }
            writeCode(self.ai_attacktarget_edit, code)
        elseif self.choice == 'richest' then
            -- new DefaultHeader("ai_attacktarget_richest", false)
            local code = {
                0xEB, 0x3F, 0x90
            }
            writeCode(self.ai_attacktarget_edit, code)
        elseif self.choice == 'weakest' then
            -- new DefaultHeader("ai_attacktarget_weakest", false)
            local code = {
                0xEB, 0x52, 0x90
            }
            writeCode(self.ai_attacktarget_edit, code)
        else
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
