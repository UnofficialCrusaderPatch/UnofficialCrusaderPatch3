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

-- BinInt32.Change("laddermadness", ChangeType.Troops, 1),
-- Armbrust dmg table: 0xB4ED20
-- Bogen dmg table: 0xB4EAA0
-- Sling dmg table: 0xB4EBE0
-- Schutz von Leiternträgern gegen Fernkämpfer
--____NEW CHANGE: u_laddermen
return {

    init = function(self, config)
        self.u_ladderarmor_bow_edit = AOBScan("E8 03 00 00 D0 07 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00")
        -- B4EAA0 + 4 * 1D   (vanilla = 1000)
        self.u_ladderarmor_sling_edit = AOBScan("C4 09 00 00 D0 07 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00")
        -- B4EBE0 + 4 * 1D   (vanilla = 2500)
        self.u_ladderarmor_xbow_edit = AOBScan("C4 09 00 00 10 27 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00")
        -- 0052EC37 + 2
        self.u_laddergold_edit = AOBScan("E7 EB 52 83 F8 25 75 05 8D 68 E5 EB 48 83 F8 46 75 05 8D 68 05 EB 3E 83 F8 47 75 05 8D 68 BE EB")
        -- F5C91
        self.ui_fix_laddermen_cost_display_in_engineers_guild_edit = AOBScan("BB 04 00 00 00 EB")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_laddermen")
        -- B4EAA0 + 4 * 1D   (vanilla = 1000)
        local code = {
            itob(420)
        }
        writeBytes(self.u_ladderarmor_bow_edit, compile(code,self.u_ladderarmor_bow_edit))
        -- B4EBE0 + 4 * 1D   (vanilla = 2500)
        local code = {
            itob(1000)
        }
        writeBytes(self.u_ladderarmor_sling_edit, compile(code,self.u_ladderarmor_sling_edit))
        -- B4ED20 + 4 * 1D   (vanilla = 2500)
        local code = {
            itob(1000)
        }
        writeBytes(self.u_ladderarmor_xbow_edit, compile(code,self.u_ladderarmor_xbow_edit))
        -- B4ED20 + 4 * 1D   (vanilla = 2500)
        -- 1D - 9 = 14h            (vanilla: 1D - 19 = 4)
        local code = {
            0xF7
        }
        writeCode(self.u_laddergold_edit, code)
        -- 1D - 9 = 14h            (vanilla: 1D - 19 = 4)
        local code = {
            0xBB, 0x14, 
        }
        writeCode(self.ui_fix_laddermen_cost_display_in_engineers_guild_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
