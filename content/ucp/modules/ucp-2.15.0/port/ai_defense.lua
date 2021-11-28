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
-- REMANNING WALL DEFENSES
-- */
--____NEW CHANGE: ai_defense
return {

    init = function(self, config)
        -- 4D26AF
        self.ai_defense_group_edit = AOBScan("55 E8 ? ? ? ? 8B CE 69 C9 7D 0E 00 00 03 C8 83 3C 8D ? ? ? ? 00 66 C7 83 ? ? ? ? 01")
        -- 579879
        self.ai_defense_reset_edit = AOBScan("B8 ? ? ? ? 8B FF 3B CA 89 90 78 05 00 00 89 10 89 90 7C 05 00 00 89 90 80 05 00 00 89 90 84 05 00 00 89 90 D0 0D")
        -- 579A7C
        self.ai_defense_count_edit = AOBScan("69 FF F4 39 00 00 8D 8F ? ? ? ? BB 01 00 00 00 01 19 E9 6B 01 00 00 69 FF F4 39 00 00 8D 8F")
        -- 004D3E6F
        self.ai_defense_check_edit = AOBScan("8B 96 ? ? ? ? 3B 91 80 01 00 00 50 8B CF 7C 07 E8 ? ? ? ? EB 28 E8 ? ? ? ? EB 21 83")
    end,

    enable = function(self, config)
        
        -- Crusader does count defensive units on walls and patrols together
        -- this prevents the AI from reinforcing missing troops on walls, if
        -- there are still defensive patrols above a certain threshold.
        -- 
        -- Solution: Implement another counter only for defensive units on walls
        -- new DefaultHeader("ai_defense")
        local code = {
         -- offset for the group index of units
         -- 1 == defense, 4 == def patrols
        }
        local groupVar = readInteger(self.ai_defense_group_edit + 0x1B)
        local somevar = readInteger(self.ai_defense_reset_edit + 1)
        local defNum = allocate(9*4)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                    0x31, 0xC0,  -- xor eax,eax
                    0x89, 0x14, 0x85, itob(defNum),  -- mov [eax*4 + defNum],edx
                    0x40,  -- inc eax
                    0x83, 0xF8, 0x8,  -- cmp eax,08
                    0x7E, 0xF3,  -- jle beneath xor
                 -- ori code
                    0xB8, itob(somevar),  -- mov eax, somevar
                    0xe9, relTo(self.ai_defense_reset_edit + 0 + 5, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.ai_defense_reset_edit + 0, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                 -- get unit's group index
                    0x89, 0xE9,  -- mov ecx,ebp
                    0x69, 0xC9, 0x90, 0x04, 0x00, 0x00,  -- imul ecx,ecx, 490 
                    0x0F, 0xB6, 0x89, itob(groupVar),  -- movzx ecx,byte ptr [ecx+01388976]
                 -- check if it's a wall defense unit
                    0x83, 0xF9, 0x1,  -- cmp ecx,01 
                    0x75, 0x9,  -- jne to ori code
                 -- increase wall defense count for this AI
                    0x8D, 0x0C, 0xBD, itob(defNum),  -- lea ecx,[edi*4 + ai_defNum]
                    0xFF, 0x01,  -- inc [ecx]
                 -- ori code
                    0x69, 0xFF, 0xF4, 0x39, 0x00, 0x00,  -- imul edi, edi, 39F4
                    0xe9, relTo(self.ai_defense_count_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.ai_defense_count_edit, code)
        local code = {
            0xE9, function(address, index, labels)
                local hook = {
                 -- AI index
                    0x8B, 0x54, 0x24, 0x04,  -- mov edx,[esp+04]
                    0x8B, 0x14, 0x95, itob(defNum),  -- mov edx,[edx*4 + defNum]
                    0xe9, relTo(self.ai_defense_check_edit + 6, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90
        }
        writeCode(self.ai_defense_check_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
