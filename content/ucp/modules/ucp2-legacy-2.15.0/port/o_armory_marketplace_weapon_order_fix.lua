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

-- change je to jmp
-- Armory / Marketplace weapon order fix
--____NEW CHANGE: o_armory_marketplace_weapon_order_fix
return {

    init = function(self, config)
        -- 217F50
        self.o_armory_marketplace_weapon_order_fix1_edit = AOBScan("11 00 00 00 13 00 00 00 15 00 00 00 12 00 00 00 14 00 00 00 16 00 00 00 17 00 00 00 18 00 00 00")
        -- 6B90E8
        self.o_armory_marketplace_weapon_order_fix2_edit = AOBScan("13 00 00 00 11 00 00 00 15 00 00 00 12 00 00 00 14 00 00 00 16 00 00 00 17 00 00 00 18 00 00 00")
        -- 7343C0
        -- This one takes long to find
        self.o_armory_marketplace_weapon_order_fix3_edit = AOBScan("4C 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 4E 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 50 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 52 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 54 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 56 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 58 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E 00 00 00 5A 00 00 00")
        -- 218050
        self.o_armory_marketplace_weapon_order_fix4_edit = AOBScan("13 00 00 00 11 00 00 00 15 00 00 00 17 00 00 00 12 00 00 00 14 00 00 00 16 00 00 00 18 00 00 00")
        -- 1FD8B0
        self.o_armory_marketplace_weapon_order_fix5_edit = AOBScan("13 00 00 00 00 00 00 00 93 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 96 00 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 11 00 00 00 00 00 00 00 91 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 CC 00 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 15 00 00 00 00 00 00 00 95 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 04 01 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 17 00 00 00 00 00 00 00 97 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 34 01 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 12 00 00 00 00 00 00 00 92 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 66 01 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 14 00 00 00 00 00 00 00 94 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 9A 01 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 16 00 00 00 00 00 00 00 96 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 02 D0 01 00 00 FB 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 18 00 00 00 00 00 00 00 98 00 00 40 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 64 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_armory_marketplace_weapon_order_fix")
        local code = {
         -- Armory item ID order
            0x11, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 
         -- Armory item image ID
            0x4C, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0x58, 0x00, 0x00, 0x00, 0x4E, 0x00, 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x5A, 0x00, 0x00, 0x00, 0x56, 0x00, 0x00, 0x00, 
         -- Armory item image offset
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFC, 0xFF, 0xFF, 0xFF, 0x04, 0x00, 0x00, 0x00, 0xFE, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFC, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix1_edit, compile(code,self.o_armory_marketplace_weapon_order_fix1_edit))
        local code = {
         -- Marketplace item order
            0x11, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix2_edit, compile(code,self.o_armory_marketplace_weapon_order_fix2_edit))
        local code = {
         -- Marketplace image order
            0x50, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix3_edit, compile(code,self.o_armory_marketplace_weapon_order_fix3_edit))
        local code = {
            0x4C, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52, compile(code,self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52))
        local code = {
            0x5A, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52 + 4 + 80, compile(code,self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52 + 4 + 80))
        local code = {
            0x56, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52 + 4 + 80 + 4 + 52, compile(code,self.o_armory_marketplace_weapon_order_fix3_edit + 4 + 52 + 4 + 80 + 4 + 52))
        local code = {
         -- Swap marketplace trade weapons item count references
            0x11, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix4_edit, compile(code,self.o_armory_marketplace_weapon_order_fix4_edit))
        local code = {
         -- Fix marketplace item order
            0x11, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix5_edit, compile(code,self.o_armory_marketplace_weapon_order_fix5_edit))
        local code = {
            0x13, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76, compile(code,self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76))
        local code = {
            0x18, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76 + 4 + 396, compile(code,self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76 + 4 + 396))
        local code = {
            0x16, 0x00, 0x00, 0x00, 
        }
        writeBytes(self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76 + 4 + 396 + 4 + 76, compile(code,self.o_armory_marketplace_weapon_order_fix5_edit + 4 + 76 + 4 + 396 + 4 + 76))
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
