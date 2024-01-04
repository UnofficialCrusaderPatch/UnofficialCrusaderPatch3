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

--____NEW CHANGE: o_change_siege_engine_spawn_position_catapult
return {

    init = function(self, config)
        -- 41F4A2
        self.o_change_siege_engine_spawn_position_catapult_edit = AOBScan("81 B8 ? ? ? ? 40 01 00 00 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 27 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
        -- 41F8AF
        self.o_change_siege_engine_spawn_position_trebutchet_edit = AOBScan("81 B8 ? ? ? ? 80 02 00 00 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 28 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
        -- 41FD7F
        self.o_change_siege_engine_spawn_position_tower_edit = AOBScan("81 B8 ? ? ? ? 00 05 00 00 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 3A 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
        -- 42020F
        self.o_change_siege_engine_spawn_position_ram_edit = AOBScan("81 B8 ? ? ? ? 80 02 00 00 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 3B 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
        -- 42069F
        self.o_change_siege_engine_spawn_position_shield_edit = AOBScan("83 B8 ? ? ? ? 78 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 3C 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
        -- 41E332
        self.o_change_siege_engine_spawn_position_fireballista_edit = AOBScan("81 B8 ? ? ? ? 40 01 00 00 0F 8E ? ? ? ? 0F BF 90 ? ? ? ? 0F BF 88 ? ? ? ? 6A 4D 52 0F BF 90 ? ? ? ? 0F BF 80 ? ? ? ?")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_change_siege_engine_spawn_position_catapult")
        local yPositionAddress = readInteger(self.o_change_siege_engine_spawn_position_catapult_edit + 43)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_catapult_edit + 0 + 40 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_catapult_edit + 0 + 40, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_trebutchet_edit + 0 + 40 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_trebutchet_edit + 0 + 40, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_tower_edit + 0 + 40 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_tower_edit + 0 + 40, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_ram_edit + 0 + 40 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_ram_edit + 0 + 40, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_shield_edit + 0 + 37 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_shield_edit + 0 + 37, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x0F, 0xBF, 0x80, itob(yPositionAddress), 
                    0x40,  -- inc eax
                    0x42,  -- inc edx
                    0xe9, relTo(self.o_change_siege_engine_spawn_position_fireballista_edit + 0 + 40 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.o_change_siege_engine_spawn_position_fireballista_edit + 0 + 40, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
