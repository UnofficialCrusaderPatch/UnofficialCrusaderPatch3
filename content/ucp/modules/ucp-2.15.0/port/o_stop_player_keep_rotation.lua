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

--____NEW CHANGE: o_stop_player_keep_rotation
return {

    init = function(self, config)
        -- 4ECF93
        self.o_stop_player_keep_rotation_get_preferred_relative_orientation_edit = AOBScan("51 89 56 28 8D 51 D5 89 4E 34 50 B9 ? ? ? ? 89 46 30 89 56 2C E8 ? ? ? ?")
        -- 441D3F
        self.o_stop_player_keep_rotation_edit = AOBScan("57 B9 01 00 00 00 50 89 0D ? ? ? ? 89 0D ? ? ? ? 56 B9 ? ? ? ? 89 53 A0 89 44 24 38 E8 ? ? ? ?")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_stop_player_keep_rotation")
        local getPreferredRelativeOrientationHandle = readInteger(self.o_stop_player_keep_rotation_get_preferred_relative_orientation_edit + 12)
        local getPreferredRelativeOrientation = self.o_stop_player_keep_rotation_get_preferred_relative_orientation_edit + 23 + 4 + readInteger(self.o_stop_player_keep_rotation_get_preferred_relative_orientation_edit + 23)
        local originalFun = self.o_stop_player_keep_rotation_edit + 0 + 32 + 1 + 4 + readInteger(self.o_stop_player_keep_rotation_edit + 0 + 32 + 1)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x57,  -- push edi
                    0x50,  -- push eax
                    0x51,  -- push ecx
                    0x68, 0xC8, 0x00, 0x00, 0x00,  -- push C8
                    0x68, 0xC8, 0x00, 0x00, 0x00,  -- push C8
                    0x57,  -- push edi
                    0x50,  -- push eax
                    0xB9, itob(getPreferredRelativeOrientationHandle),  -- mov ecx,getPreferredRelativeOrientationHandle
                    0xE8, function(index) return itob(getRelativeAddress(index, getPreferredRelativeOrientation, -4)) end,  -- call getPreferredRelativeOrientation
                    0xB8, itob(getPreferredRelativeOrientationHandle),  -- mov eax,getPreferredRelativeOrientationHandle
                    0x05, 0x10, 0x00, 0x00, 0x00,  -- add eax,10
                    0x8B, 0x00,  -- mov eax,[eax]
                    0x25, 0xFE, 0xFF, 0x00, 0x00,  -- and eax,0000FFFE
                    0x3D, 0x06, 0x00, 0x00, 0x00,  -- cmp eax,00000006
                    0x74, 0x09,  -- je short 9
                    0x3D, 0x02, 0x00, 0x00, 0x00,  -- cmp eax,02
                    0x74, 0x09,  -- je short 9
                    0xEB, 0x0C,  -- jmp short C
                    0xB8, 0x02, 0x00, 0x00, 0x00,  -- mov eax,02
                    0xEB, 0x05,  -- jmp short 5
                    0XB8, 0x06, 0x00, 0x00, 0x00,  -- mov eax,06
                    0x89, 0x44, 0x24, 0x20,  -- mov [esp+20],eax
                    0x59,  -- pop ecx
                    0x58,  -- pop eax
                    0x5F,  -- pop edi
                    0xE8, function(index) return itob(getRelativeAddress(index, originalFun, -4)) end,  -- call originalFun
                    0xe9, relTo(self.o_stop_player_keep_rotation_edit + 0 + 32 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.o_stop_player_keep_rotation_edit + 0 + 32, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
