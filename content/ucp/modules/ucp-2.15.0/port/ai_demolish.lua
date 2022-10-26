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
-- ECONOMY DEMOLISHING
-- */
-- 004D0280
--____NEW CHANGE: ai_demolish
return {

    init = function(self, config)
        self.ai_demolish_eco_enabled = config.ai_demolish_eco.enabled
        self.ai_demolish_trapped_enabled = config.ai_demolish_trapped.enabled
        self.ai_demolish_walls_enabled = config.ai_demolish_walls.enabled

        -- 004D03F4  => jmp to end
        self.ai_demolish_walls_edit = AOBScan("0F B7 06 66 3D 2D 00 0F 84 DF 00 00 00 66 3D 2E 00 0F 84 D5 00 00 00 66 3D 31 00 0F 84 CB")
        -- 004F1988  => jne to jmp
        self.ai_demolish_trapped_edit = AOBScan("75 35 83 3C B5 ? ? ? ? 00 74 2B 83 7F 34 00 75 25 83 3F 00 75 20 66 83 BF AE 17 00 00 00 75")
        -- 004D0280  => retn 8
        self.ai_demolish_eco_edit = AOBScan("55 BD 01 00 00 00 39 2D ? ? ? ? 0F 8E 7F 02 00 00 53 8B 5C 24 0C 56 57 8B 7C 24 18 BE")
    end,

    enable = function(self, config)
        
        if self.ai_demolish_walls_enabled then
            -- new DefaultHeader("ai_demolish_walls", true)
            local code = {
                0xE9, 0x15, 0x01, 0x00, 0x00, 0x90, 0x90
            }
            writeCode(self.ai_demolish_walls_edit, code)
        end

        if self.ai_demolish_trapped_enabled then
            -- new DefaultHeader("ai_demolish_trapped", false)
            local code = {
                0xEB
            }
            writeCode(self.ai_demolish_trapped_edit, code)
        end

        if self.ai_demolish_eco_enabled then
            -- new DefaultHeader("ai_demolish_eco", false)
            local code = {
                0xC2, 0x08, 0x00, 0x90, 0x90, 0x90
            }
            writeCode(self.ai_demolish_eco_edit, code)
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
