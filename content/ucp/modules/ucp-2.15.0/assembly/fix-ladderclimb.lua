local scanForAOB = core.scanForAOB
local insertCode = core.insertCode
local allocate = core.allocate
local allocateCode = core.allocateCode

return {
    init = function(self, config)

        self.currentUnitMoved = allocate(4)
        self.savedUnitDestinationForClimbing = allocate(120000)

        -- 0x0053D3D0 + 9
        self.hook1Address = scanForAOB("83 EC 08 8B 44 24 0C 8B D0 69 D2 90 04 00 00") + 9

        -- 0x0053D688 + 12
        self.hook2Address = scanForAOB("50 52 B9 ? ? ? ? E8 ? ? ? ? 66 3B C3 66 89 86 BC 08 00 00 74") + 12
        -- 0x005790CB
        self.hook3Address = scanForAOB("66 89 8C 37 00 07 00 00 66 89 94 37 02 07 00 00")

        -- 0x0053D900
        self.hook4Address = scanForAOB("53 8B 5C 24 08 8B C3 55 69 C0")

        -- 0x0054C3E5
        self.hook5Address = scanForAOB("0F BF 96 02 07 00 00 0F BF 86 00 07 00 00 66 8B 8E 8A 09 00 00")

    end,
    enable = function(self, config)

        -- allocate 12 bytes and hook with 6 bytes at hook1Address
        self.hook1NewCodeAddress = insertCode(self.hook1Address, 6, {
            0x89, 0x15, self.currentUnitMoved, -- mov [currentUnitMoved],edx
            0x69, 0xD2, 0x90, 0x04, 0x00, 0x00
        })


        -- allocate 54 bytes and hook with 10 bytes at hook2Address
        self.hook2NewCodeAddress = insertCode(self.hook2Address, 10, {
            0x50, -- push eax
            0xA1, self.currentUnitMoved, -- mov eax,[currentUnitMoved]
            0x83, 0xF8, 0x00, -- cmp eax,00
            0x74, 0x20, -- je short 20
            0x48, -- dec eax
            0x6B, 0xC0, 0x0C, -- imul eax,eax,0C
            0x89, 0xA8, self.savedUnitDestinationForClimbing, -- mov [eax+savedUnitDestinationForClimbing],ebp
            0x83, 0xC0, 0x04, -- add eax,04
            0x89, 0xB8, self.savedUnitDestinationForClimbing, -- mov [eax+savedUnitDestinationForClimbing],edi
            0x83, 0xC0, 0x04, -- add eax,04
            0xC7, 0x80, self.savedUnitDestinationForClimbing, 0x01, 0x00, 0x00, 0x00, -- mov [eax+savedUnitDestinationForClimbing],01
            0x58, -- pop eax
            0x66, 0x39, 0xD8, -- cmp ax,bx
            0x66, 0x89, 0x86, 0xBC, 0x08, 0x00, 0x00, -- mov [esi+8BC],ax
        })


        -- allocate 52 bytes and hook with 16 bytes at hook3Address
        self.hook3NewCodeAddress = insertCode(self.hook3Address, 16, {
            0x50, -- push eax
            0x8B, 0xC3, -- mov eax,ebx
            0x48, -- dec eax
            0x6B, 0xC0, 0x0C, -- imul eax,eax,0C
            0x83, 0xC0, 0x08, -- add eax,08
            0x83, 0xB8, self.savedUnitDestinationForClimbing, 0x00, -- cmp dword ptr [eax+savedUnitDestinationForClimbing],00
            0x75, 0x13, -- jne short 0x13
            0x58, -- pop eax
            0x66, 0x89, 0x8C, 0x3E, 0x00, 0x07, 0x00, 0x00, -- mov [esi+edi+00000700],cx
            0x66, 0x89, 0x94, 0x3E, 0x02, 0x07, 0x00, 0x00, -- mov [esi+edi+00000702],dx
            0xEB, 0x0B, -- jmp short exit
            0xC7, 0x80, self.savedUnitDestinationForClimbing, 0x00, 0x00, 0x00, 0x00, -- mov [eax+savedUnitDestinationForClimbing],00000000
            0x58-- pop eax
        })


        -- allocate 26 bytes and hook with 5 bytes at hook4Address
        self.hook4NewCodeAddress = insertCode(self.hook4Address, 5, {
            0x50, -- push eax
            0x8B, 0xC3, -- mov eax,ebx
            0x48, -- dec eax
            0x6B, 0xC0, 0x0C, -- imul eax,eax,0C
            0x83, 0xC0, 0x08, -- add eax,08,
            0xC7, 0x80, self.savedUnitDestinationForClimbing, 0x01, 0x00, 0x00, 0x00, -- mov [eax+savedUnitDestinationForClimbing],00000000
            0x58, -- pop eax
            0x53, -- push ebx
            0x8B, 0x5C, 0x24, 0x08, -- mov ebx,[esp+08]
        })


        -- allocate 54 bytes and hook with 14 bytes at hook5Address
        self.hook5NewCodeAddress = insertCode(self.hook5Address, 14, {
            0x57, -- push edi
            0x31, 0xFF, -- xor edi,edi
            0x66, 0x8B, 0x7C, 0x24, 0x18, -- mov di,[esp+18]
            0x4F, -- dec edi
            0x6B, 0xFF, 0x0C, -- imul edi,edi,0C
            0x8B, 0x87, self.savedUnitDestinationForClimbing, -- mov eax,[edi+savedUnitDestinationForClimbing]
            0x83, 0xC7, 0x04, -- add edi,04
            0x8B, 0x97, self.savedUnitDestinationForClimbing, -- mov edx,[edi+savedUnitDestinationForClimbing]
            0x89, 0x86, 0x00, 0x07, 0x00, 0x00, -- mov [esi+00000700],eax
            0x89, 0x96, 0x02, 0x07, 0x00, 0x00, -- mov [esi+00000702],edx
            0x0F, 0xBF, 0x96, 0x02, 0x07, 0x00, 0x00, -- movsx edx,word ptr [esi+00000702]
            0x0F, 0xBF, 0x86, 0x00, 0x07, 0x00, 0x00, -- movsx edx,word ptr [esi+00000702]
            0x5F, -- pop edi
        })

    end,
    disable = function(self, config)
        error("not implemented")
    end,
}
