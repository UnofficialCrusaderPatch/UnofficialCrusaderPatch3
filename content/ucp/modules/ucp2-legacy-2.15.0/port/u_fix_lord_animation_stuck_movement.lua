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

--____NEW CHANGE: u_fix_lord_animation_stuck_movement
return {

    init = function(self, config)
        -- 56E139
        self.u_fix_lord_animation_stuck_movement_edit = AOBScan("E8 ? ? ? ? 85 C0 74 21 83 3D ? ? ? ? 00 C7 86 ? ? ? ? 00 00 00 00 75 07")
        -- 56D856
        self.u_fix_lord_animation_stuck_building_attack_edit = AOBScan("8B 15 ? ? ? ? 8B C2 69 C0 90 04 00 00 69 D2 90 04 00 00 5F 66 89 A8 ? ? ? ? 5E 89 AA ? ? ? ? 5D 5B 83 C4 14 C3")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("u_fix_lord_animation_stuck_movement")
        local originalCompareAddress = readInteger(self.u_fix_lord_animation_stuck_movement_edit + 11)
        local unitHandle = readInteger(self.u_fix_lord_animation_stuck_movement_edit + 18)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x53,  -- push ebx
                    0xBB, itob(unitHandle),  -- mov ebx,unitHandle
                    0xC7, 0x04, 0x33, 0x00, 0x00, 0x00, 0x00,  -- mov [ebx+esi],00000000
                    0x81, 0xC3, 0x04, 0x00, 0x00, 0x00,  -- add ebx,00000004
                    0x0F, 0xB7, 0x0C, 0x33,  -- movzx ecx,word ptr [ebx+esi]
                    0x81, 0xEB, 0xA8, 0x02, 0x00, 0x00,  -- sub ebx,000002A8
                    0x81, 0xC1, 0x29, 0x00, 0x00, 0x00,  -- add ecx,00000029
                    0x81, 0x3C, 0x33, 0xCD, 0x00, 0x00, 0x00,  -- cmp [ebx+esi],000000CD
                    0x74, 0x06,  -- je short 0x06
                    0x81, 0xC1, 0x80, 0x00, 0x00, 0x00,  -- add ecx,00000080
                    0x81, 0xC3, 0x24, 0x00, 0x00, 0x00,  -- add ebx,00000024
                    0xC7, 0x04, 0x33, 0x00, 0x00, 0x00, 0x00,  -- mov [ebx+esi],00000000
                    0x81, 0xEB, 0x2C, 0x00, 0x00, 0x00,  -- sub ebx,0000002C
                    0x89, 0x0C, 0x33,  -- mov [ebx+esi],ecx
                    0x5B,  -- pop ebx
                 -- original compare
                    0x83, 0x3D, itob(originalCompareAddress), 0x00,  -- cmp dword ptr [0191DD80],00
                    0xe9, relTo(self.u_fix_lord_animation_stuck_movement_edit + 0 + 9 + 17, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.u_fix_lord_animation_stuck_movement_edit + 0 + 9, code)
        local unitVar = readInteger(self.u_fix_lord_animation_stuck_building_attack_edit + 24)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0xC7, 0x80, itob(unitVar), 0x65, 0x00, 0x00, 0x00,  -- mov [eax+unitVar],00000065
                    0xe9, relTo(self.u_fix_lord_animation_stuck_building_attack_edit + 0 + 21 + 7, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90
        }
        writeCode(self.u_fix_lord_animation_stuck_building_attack_edit + 0 + 21, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
