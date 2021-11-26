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
-- AI NO SLEEP
-- */
-- 004CBCD5
--____NEW CHANGE: ai_nosleep
return {

    init = function(self, config)
        self.ai_nosleep_edit = AOBScan("0F 94 C2 3B CB 0F 94 C1 39 5C 24 34 88 96 ? ? ? ? 0F 94 C2 3B FB 88 8E ? ? ? ? 0F 94 C1")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_nosleep")
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit, code)
        local code = {
            0x30, 0xC9, 0x90,  -- xor cl, cl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2, code)
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10, code)
        local code = {
            0x30, 0xC9, 0x90,  -- xor cl, cl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8, code)
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8, code)
        local code = {
            0x30, 0xC9, 0x90,  -- xor cl, cl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10, code)
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10 + 3 + 10, code)
        local code = {
            0x30, 0xC9, 0x90,  -- xor cl, cl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10 + 3 + 10 + 3 + 10, code)
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10, code)
        local code = {
            0x30, 0xC9, 0x90,  -- xor cl, cl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10, code)
        local code = {
            0x30, 0xD2, 0x90,  -- xor dl, dl
        }
        writeCode(self.ai_nosleep_edit + 3 + 2 + 3 + 10 + 3 + 8 + 3 + 8 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10 + 3 + 10, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
