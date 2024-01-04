local writeCode = core.writeCode
local scanForAOB = core.scanForAOB
local readInteger = core.readInteger
local allocateCode = core.allocateCode
local allocate = core.allocate
local calculateCodeSize = core.calculateCodeSize
local compile = core.compile
local insertCode = core.insertCode

local itob = utils.itob
local getRelativeAddress = core.getRelativeAddress

-- TODO: part 2

---[[

local random_block = "0F BF 05 ? ? ? ? 99 F7 FF B9 ? ? ? ? 8B FA E8 ? ? ? ? 8B 76 08 B8 01 00 00 00 3B F0 7E 3B 8B 6C 24 14 8B CB 8B 5C 24 18 90 0F B7 11 66 85 D2"
local random_address = scanForAOB(random_block)
local random_random = readInteger(random_address + 3)
local random_randomecx = readInteger(random_address + 0xB)
local random_randomcall = (random_address + 0x12 - 1) + readInteger(random_address + 0x12) + 5

local GetRandomShort_code = {
    0xB9, itob(random_randomecx), -- mov ecx, randomecx
    0xE8, function(index)
        return itob(getRelativeAddress(index, random_randomcall, -5 + 1))
    end, -- call refreshrandom
    0x0F, 0xBf, 0x05, itob(random_random), -- movsx eax,[random]
    0xC3 -- ret
}

local GetRandomShort = allocateCode(calculateCodeSize(GetRandomShort_code))
writeCode(GetRandomShort, compile(GetRandomShort_code, GetRandomShort))

local o_healer_plague_block = "83 EC 08 53 55 57 8B 7C 24 18 69 FF 90 04 00 00 8B 97 ? ? ? ? 0F BF 14 55 ? ? ? ? 33 C0"
local o_healer_plague_address = scanForAOB(o_healer_plague_block)
local pvar1 = readInteger(o_healer_plague_address + 0xFF)
local pvar2 = readInteger(o_healer_plague_address + 0x119)
local pvar3 = readInteger(o_healer_plague_address + 0x120)
local presult = readInteger(o_healer_plague_address + 0x133)

local o_healer_find_block = "83 EC 08 53 55 33 C0 8B E9 BB 01 00 00 00 39 5D 00 89 44 24 0C 89 44 24 08 0F 8E F9 00 00 00 56"

local o_healer_find_address = scanForAOB(o_healer_find_block)
local fvar2 = readInteger(o_healer_find_address + 0xBB)
local distfunc = (o_healer_find_address + 0xC0 - 1) + readInteger(o_healer_find_address + 0xC0) + 5

local healerbool_address = allocate(1)

local healer_find_code = {
    0x83, 0xEC, 0x08, --   - sub esp,08 { 8 }
    0x53, --   - push ebx
    0x55, --  - push ebp
    0x33, 0xC0, --  - xor eax,eax
    0x8B, 0xE9, --  - mov ebp,ecx
    0xBB, 0x01, 0x00, 0x00, 0x00, --  - mov ebx,00000001 { 1 }
    0x39, 0x5D, 0x00, --  - cmp [ebp+00],ebx
    0x89, 0x44, 0x24, 0x0C, --  - mov [esp+0C],eax
    0xC7, 0x44, 0x24, 0x08, 0xFF, 0xFF, 0xFF, 0x7F, --  - mov [esp+08],0x7FFFFFFF
    0x0F, 0x8E, 0xEB, 0x00, 0x00, 0x00, --  - jng end

    0x56, --  - push esi
    0x57, --  - push edi
    0x8D, 0xBD, 0x44, 0x0D, 0x00, 0x00, --  - lea edi,[ebp+00000D44]

    -- CHECK NPC
    0x66, 0x83, 0xBF, 0xEC, 0xFD, 0xFF, 0xFF, 0x02, -- - cmp word ptr [edi-00000214],02 { 2 }
    0x0F, 0x85, 0x9C, 0x00, 0x00, 0x00, -- - jne 0053467F


    -- CHECK ALIVE?
    0x66, 0x83, 0x3F, 0x00, -- - cmp word ptr [edi],00 { 0 }
    0x0F, 0x85, 0x92, 0x00, 0x00, 0x00, -- - jne 0053467F

    -- CHECK TEAM
    0x0F, 0xBF, 0x87, 0xF6, 0xFD, 0xFF, 0xFF, --  - movsx eax,word ptr [edi-0000020A]
    0x3B, 0x44, 0x24, 0x20, -- - cmp eax,[esp+20]
    0x0F, 0x85, 0x81, 0x00, 0x00, 0x00, -- - jne 0053467F

    -- CHECK HEALTH
    0x8B, 0x87, 0x28, 0x01, 0x00, 0x00, -- mov eax, [edi+128]
    0x3B, 0x87, 0x2C, 0x01, 0x00, 0x00, -- cmp eax, [edi+12C]
    0x7D, 0x73, -- jge end

    -- CHECK EXCLUDE
    0x8B, 0x44, 0x24, 0x1C, -- mov eax, [esp+1C]
    0x39, 0xC3, -- - cmp ebx,eax
    0x74, 0x6B, --  - je 0053467F

    -- CHECK DISTANCE
    0x69, 0xC0, 0x90, 0x04, 0x00, 0x00, --        - imul eax,eax,490
    0x0F, 0xBF, 0x80, itob(pvar1), -- movsx, eax, word ptr [eax+pvar1]
    0x85, 0xC0, -- test eax, eax
    0x74, 0x3B, -- je skip dist check

    -- self pos
    0x0F, 0xBF, 0x8F, 0x26, 0xFE, 0xFF, 0xFF, --  movsx ecx,word ptr [edi-000001DA]
    0x0F, 0xBF, 0x97, 0x24, 0xFE, 0xFF, 0xFF, -- movsx edx,word ptr [edi-000001DC]

    0x51, --                   - push ecx
    0x52, --                    - push edx

    0x69, 0xC0, 0x2C, 0x03, 0x00, 0x00, --        - imul eax,eax,0000032C { 812 }
    0x0F, 0xBF, 0x90, itob(pvar2), -- movsx edx,word ptr [eax+00F98624]
    0x0F, 0xBF, 0x80, itob(pvar3), -- - movsx eax,word ptr [eax+00F98622]
    0x52, --                    - push edx
    0x50, --                    - push eax
    0xB9, itob(fvar2), -- - mov ecx,00EE23BC { [00000000] }
    0xE8, function(index)
        return itob(getRelativeAddress(index, distfunc, -5 + 1))
    end, --  - call 0046CC80.
    0x8B, 0x35, itob(presult), -- mov esi, [presult]
    0x83, 0xFE, 0x28, -- cmp esi, 28
    0x7F, 0x1F, --                 - jg 0040184D -- too far away

    -- first time ? jump over
    0x83, 0x7C, 0x24, 0x2C, 0x00, --  - cmp dword ptr [esp+2C],00
    0x74, 0x0A, --  - je 00534671

    -- continued ? add some randomness
    0xE8, function(index)
        return itob(getRelativeAddress(index, GetRandomShort, -5 + 1))
    end, -- call getrandomshort.
    0xC1, 0xF8, 0x0C, -- sar eax, C
    0x01, 0xC6, -- add esi, eax


    0x3B, 0x74, 0x24, 0x10, --  - cmp esi,[esp+10]
    0x7D, 0x08, --  - jge 0053467F
    0x89, 0x74, 0x24, 0x10, --  - mov [esp+10],esi
    0x89, 0x5C, 0x24, 0x14, --  - mov [esp+14],ebx

    0x83, 0xC3, 0x01, --  - add ebx,01 { 1 }
    0x81, 0xC7, 0x90, 0x04, 0x00, 0x00, --  - add edi,00000490 { 1168 }
    0x3B, 0x5D, 0x00, --  - cmp ebx,[ebp+00]
    0x0F, 0x8C, 0x44, 0xFF, 0xFF, 0xFF, -- - jl 005345D0

    0x8B, 0x44, 0x24, 0x14, -- - mov eax,[esp+14]
    0x85, 0xC0, -- - test eax,eax
    0x5F, -- - pop edi
    0x5E, -- - pop esi
    0x74, 0x1D, -- - je 005346B8
    0x8B, 0x15, 0xA8, 0x7D, 0xFE, 0x01, -- - mov edx,[01FE7DA8] { [0000F19D] }
    0x8B, 0xC8, -- - mov ecx,eax
    0x69, 0xC9, 0x90, 0x04, 0x00, 0x00, -- - imul ecx,ecx,00000490 { 1168 }
    0x89, 0x94, 0x29, 0x44, 0x09, 0x00, 0x00, -- - mov [ecx+ebp+00000944],edx
    0x5D, -- - pop ebp
    0x5B, --- pop ebx
    0x83, 0xC4, 0x08, --- add esp,08 { 8 }
    0xC2, 0x18, 0x00, --- ret 0018 { 24 }
    0x5D, --- pop ebp
    0x33, 0xC0, -- - xor eax,eax
    0x5B, -- - pop ebx
    0x83, 0xC4, 0x08, -- - add esp,08 { 8 }
    0xC2, 0x18, 0x00, -- - ret 0018 { 24 }
}

local healer_find_address = allocateCode(calculateCodeSize(healer_find_code))
local c = compile(healer_find_code, healer_find_address)

writeCode(healer_find_address, c)

local hook_address = insertCode(o_healer_find_address, 5, {
    0x80, 0x3D, itob(healerbool_address), 0x01, -- cmp [healerbool], 1
    -- this relative jump is bullshit. `index` is not a proper memory address, while `healer_find_address` is.
    0x0F, 0x84, function(index)
        return itob(getRelativeAddress(index, healer_find_address, -6 + 2))
    end, -- je
    0x83, 0xEC, 0x08, -- sub esp, 0x8
    0x53, -- push ebx
    0x55, -- push ebp
})

--]]