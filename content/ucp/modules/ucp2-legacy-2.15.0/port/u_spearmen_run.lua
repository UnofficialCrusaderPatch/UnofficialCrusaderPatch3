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

--____NEW CHANGE: u_spearmen_run
return {

    init = function(self, config)
        -- 0055E07E
        self.u_spearmen_run_edit = AOBScan("74 13 C7 86 ? ? ? ?  81 00 00 00 66 89 86 ? ? ? ? EB 0D 89 86 ? ? ? ? 66 89 BE")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_spearmen_run")
        local code = {
            0x90, 0x90,  -- remove je
        }
        writeCode(self.u_spearmen_run_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
