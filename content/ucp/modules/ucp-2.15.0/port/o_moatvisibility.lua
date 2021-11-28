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
-- MOAT VISIBILITY
-- */
--____NEW CHANGE: o_moatvisibility
return {

    init = function(self, config)
        -- 4EC86C
        self.o_moatvisibility_edit = AOBScan("8B CB C7 05 ? ? ? ? FF FF FF FF E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 5F 5E 89 2D ? ? ? ? 89 2D ? ? ? ? 5D 5B 83 C4 64 C3")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_moatvisibility")
        local code = {
            0x15,  -- mov [ ], edx = 1 instead of ebp = 0
        }
        writeCode(self.o_moatvisibility_edit + 0 + 0x24, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
