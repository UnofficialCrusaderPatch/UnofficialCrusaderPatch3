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

--____NEW CHANGE: ai_recruitstate_initialtimer
return {

    init = function(self, config)
        self.value = config.sliderValue or 6
        
        self.ai_recruitstate_initialtimer_edit = AOBScan("03 CB 03 CD 74 4D")
    end,

    enable = function(self, config)
        
        -- new SliderHeader("ai_recruitstate_initialtimervalue", true, 0, 30, 1, 6, 0)
        local code = {
            itob(self.value * 800), 
        }
        writeCode(self.ai_recruitstate_initialtimer_edit + 0 + 36, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}