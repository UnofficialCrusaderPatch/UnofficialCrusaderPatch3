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

--____NEW CHANGE: o_shfy
return {

    init = function(self, config)
        if config.o_shfy_beer.enabled == true then
            self.o_shfy_beer = true
        end
        if config.o_shfy_religion.enabled == true then
            self.o_shfy_religion = true
        end

        if config.o_shfy_peasantspawnrate.enabled == true then
            self.o_shfy_peasantspawnrate = true
        end

        if config.o_shfy_resourcequantity.enabled == true then
            self.o_shfy_resourcequantity = true
        end

        -- fixes beer popularity bonus
        self.o_shfy_beerpopularity_edit = AOBScan("83 F8 19 89 84 3E ? ? ? ? 7D")
        self.o_shfy_beerpopularitytab_edit = AOBScan("83 F8 19 7D 04")
        self.o_shfy_beertab_edit = AOBScan("83 FE 19 7D 04")
        -- fixes religion popularity bonus
        self.o_shfy_religionpopularity_edit = AOBScan("83 BE ? ? ? ? 00 74 03 83 C1 19")
        self.o_shfy_religionpopularitytab_edit = AOBScan("83 B9 ? ? ? ? 00 74 03 83 C6 19")
        self.o_shfy_religiontab_edit = AOBScan("74 39 83 B8 ? ? ? ? 00 74")
        -- fixes peasant spawnrate
        self.o_shfy_peasantspawnrate_edit = AOBScan("39 9E ? ? ? ? 74 0E 39 1D")
        -- fixes resource quantity
        self.o_shfy_resourcequantity_edit = AOBScan("83 C0 32 8B 7C 24 10")
    end,

    enable = function(self, config)
        
        if self.o_shfy_beer then
            -- new DefaultHeader("o_shfy_beer", false)
            local code = {
                0xB8, 0x19, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beerpopularity_edit + 0 + 21, code)
            local code = {
                0xB8, 0x32, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beerpopularity_edit + 0 + 21 + 5 + 7, code)
            local code = {
                0x83, 0xE2, 0x9C, 0x83, 0xC2, 0x64, 0x90, 0x90, 0x90, 
            }
            writeCode(self.o_shfy_beerpopularity_edit + 0 + 21 + 5 + 7 + 5 + 13, code)
            local code = {
                0xBE, 0x19, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beerpopularitytab_edit + 0 + 14, code)
            local code = {
                0xBE, 0x32, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beerpopularitytab_edit + 0 + 14 + 5 + 7, code)
            local code = {
                0x83, 0xE1, 0xE7, 0x83, 0xC1, 0x64, 0x90, 0x90, 0x90, 
            }
            writeCode(self.o_shfy_beerpopularitytab_edit + 0 + 14 + 5 + 7 + 5 + 13, code)
            local code = {
                0xB8, 0x19, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beertab_edit + 0 + 14, code)
            local code = {
                0xB8, 0x32, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_beertab_edit + 0 + 14 + 5 + 7, code)
            local code = {
                0x83, 0xE0, 0xE7, 0x83, 0xC0, 0x64, 0x90, 0x90, 
            }
            writeCode(self.o_shfy_beertab_edit + 0 + 14 + 5 + 7 + 5 + 13, code)
        end

        if self.o_shfy_religion then
            -- new DefaultHeader("o_shfy_religion", false)
            local code = {
                0x83, 0xC1, 0x00, 
            }
            writeCode(self.o_shfy_religionpopularity_edit + 0 + 9, code)
            local code = {
                0x83, 0xC1, 0x00, 
            }
            writeCode(self.o_shfy_religionpopularity_edit + 0 + 9 + 3 + 9, code)
            local code = {
                0x83, 0xC6, 0x00, 
            }
            writeCode(self.o_shfy_religionpopularitytab_edit + 0 + 9, code)
            local code = {
                0x83, 0xC6, 0x00, 
            }
            writeCode(self.o_shfy_religionpopularitytab_edit + 0 + 9 + 3 + 9, code)
            local code = {
                0xEB, 0x6d, 
            }
            writeCode(self.o_shfy_religiontab_edit, code)
            local code = {
                0xB9, 0x00, 0x00, 0x00, 0x00, 
            }
            writeCode(self.o_shfy_religiontab_edit + 2 + 132, code)
            local code = {
                0x83, 0xC1, 0x00, 
            }
            writeCode(self.o_shfy_religiontab_edit + 2 + 132 + 5 + 9, code)
        end
        
        if self.o_shfy_peasantspawnrate then
            -- new DefaultHeader("o_shfy_peasantspawnrate", false)
            local code = {
                0x83, 0xFB, 0x00, 0x90, 0x90, 0x90, 
            }
            writeCode(self.o_shfy_peasantspawnrate_edit + 0 + 8, code)
            local code = {
                0x83, 0xFB, 0x00, 0x90, 0x90, 0x90, 
            }
            writeCode(self.o_shfy_peasantspawnrate_edit + 0 + 8 + 6 + 8, code)
        end
        
        if self.o_shfy_resourcequantity then
            -- new DefaultHeader("o_shfy_resourcequantity", false)
            local code = {
                0x83, 0xC0, 0x00, 
            }
            writeCode(self.o_shfy_resourcequantity_edit, code)
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
