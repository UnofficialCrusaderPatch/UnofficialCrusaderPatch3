return {
    init = function(self, config)
        self.ai_defense_group = core.AOBScan("55 E8 ? ? ? ? 8B CE 69 C9 7D 0E 00 00 03 C8 83 3C 8D ? ? ? ? 00 66 C7 83 ? ? ? ? 01")
        self.groupVar = core.readInteger(self.ai_defense_group + 0x1B)
        self.ai_defense_reset = core.AOBScan("B8 ? ? ? ? 8B FF 3B CA 89 90 78 05 00 00 89 10 89 90 7C 05 00 00 89 90 80 05 00 00 89 90 84 05 00 00 89 90 D0 0D")
        self.somevar = core.readInteger(self.ai_defense_reset + 1)
        self.defNum = core.allocate(9 * 4)
        self.ai_defense_count = core.AOBScan("69 FF F4 39 00 00 8D 8F ? ? ? ? BB 01 00 00 00 01 19 E9 6B 01 00 00 69 FF F4 39 00 00 8D 8F")
        self.ai_defense_check = core.AOBScan("8B 96 ? ? ? ? 3B 91 80 01 00 00 50 8B CF 7C 07 E8 ? ? ? ? EB 28 E8 ? ? ? ? EB 21 83")
    end,
    enable = function(self, config)
        self.hook1 = core.insertCode(self.ai_defense_reset, 5, {
            0x31, 0xC0, -- xor eax, eax
            0x89, 0x14, 0x85, self.defNum, -- mov [eax*4 + defNum],edx
            0x40, -- inc eax
            0x83, 0xF8, 0x08, -- cmp eax, 8
            0x7E, 0xF3, -- jle beneath xor

            -- original code
            0xB8, self.somevar,
        })

        self.hook2 = core.insertCode(self.ai_defense_count, 6, {
            0x8B, 0xCD, -- mov ecx, ebp
            0x69, 0xC9, 0x90, 0x04, 0x00, 0x00, -- imul ecx,ecx, 490
            0x0F, 0xB6, 0x89, self.groupVar, -- movzx ecx,byte ptr [ecx+01388976]

            -- check if it's a wall defense unit
            0x83, 0xF9, 0x01, -- cmp ecx,01
            0x75, 0x09, -- jne to ori code

            -- increase wall defense count for this AI
            0x8D, 0x0C, 0xBD, self.defNum, -- lea ecx,[edi*4 + ai_defNum]
            0xFF, 0x01, -- inc [ecx]

            -- ori code
            0x69, 0xFF, 0xF4, 0x39, 0x00, 0x00, -- imul edi, edi, 39F4
        })

        self.hook3 = core.insertCode(self.ai_defense_check, 6, {
            0x8B, 0x54, 0x24, 0x04, -- mov edx,[esp+04]
            0x8B, 0x14, 0x95, self.defNum, -- mov edx,[edx*4 + defNum]
        })
    end,
    disable = function(self, config)
    end,

}