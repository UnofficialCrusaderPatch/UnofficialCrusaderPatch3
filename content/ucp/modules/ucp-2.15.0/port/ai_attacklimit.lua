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
-- AI RECRUIT ADDITIONAL ATTACK TROOPS 
-- */
-- 115EEE0 + (AI1 = 73E8) = stay home troops?
-- +8 attack troops
-- absolute limit at 0x4CDEF8 + 1 = 200
--____NEW CHANGE: ai_attacklimit
return {

    init = function(self, config)
        self.value = config.sliderValue
        if self.value == nil then 
          log(WARNING, "Missing value for ai_attacklimit")
          self.value = 200 
        else
          log(DEBUG, "Configuring ai_attacklimit to: " .. tostring(self.value))
        end
        
        self.ai_attacklimit_edit = AOBScan("C8 00 00 00 39 86 ? ? ? ? 7E 06 89 86 ? ? ? ? 5E 5D C2 04 00 53 57 8B 7C 24 0C 69 FF F4")
    end,

    enable = function(self, config)
        
        -- new SliderHeader("ai_attacklimit", true, 0, 3000, 50, 200, 500)
        local code = {
            itob(self.value), 
        }
        log(DEBUG, "Setting ai_attacklimit to: " .. tostring(self.value))
        writeCode(self.ai_attacklimit_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}