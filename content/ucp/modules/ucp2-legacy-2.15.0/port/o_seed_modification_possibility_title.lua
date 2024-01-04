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

--____NEW CHANGE: o_seed_modification_possibility_title
return {

    init = function(self, config)
        if config.choice == 'o_seed_modification_possibility_only_set' then
                self.o_seed_modification_possibility_only_set_enabled = true
        elseif config.choice == 'o_seed_modification_possibility' then
                self.o_seed_modification_possibility_enabled = true
        end
        -- 004964AB
        self.o_seed_modification_possibility_fn1_edit = AOBScan("E8 ? ? ? ? 8B F0 83 C4 08 85 F6 0F 84 ? ? ? ? 6A 0F 6A 05")
        -- 00592CA6
        self.o_seed_modification_possibility_fn2_edit = AOBScan("6A 0A 6A 10 81 C7 80 00 00 00 57 53 E8 ? ? ? ? 83 C4 10 33 C0 40 EB 02")
        -- 0046C381
        self.o_seed_modification_possibility_fn3_edit = AOBScan("57 56 8D 44 24 14 6A 01 50 E8 ? ? ? ? 83 C4 10 33 C0 85 F6 C6 44 34 0C 00 7E ? 8D 49 00")
        -- 00588FF2
        self.o_seed_modification_possibility_fn4_edit = AOBScan("56 E8 ? ? ? ? 59 69 C0 10 0E 00 00 89 45 E4 8A 06 3C 2B 74 08 3C 30 7C 15 3C 39 7F 11")
        -- 00588E4B
        self.o_seed_modification_possibility_fn5_edit = AOBScan("56 E8 ? ? ? ? 40 50 E8 ? ? ? ? 59 59 A3 ? ? ? ? 3B C3 0F 84 ? ? ? ? 56 56 E8 ? ? ? ? 59 40 50")
        -- 0046A764
        self.o_seed_modification_possibility_edit = AOBScan("53 56 8B F1 8B 46 04 57 50 E8 ? ? ? ? 83 C4 04 33 C0 89 86 48 9C 00 00")
    end,

    enable = function(self, config)
        
        if self.o_seed_modification_possibility_only_set_enabled then

                -- new DefaultHeader("o_seed_modification_possibility_only_set", true)
                local _fopen = self.o_seed_modification_possibility_fn1_edit + 1 + 4 + readInteger(self.o_seed_modification_possibility_fn1_edit + 1)
                local _fclose = self.o_seed_modification_possibility_fn1_edit + 972 + 4 + readInteger(self.o_seed_modification_possibility_fn1_edit + 972)
                local _internalFileRead = self.o_seed_modification_possibility_fn3_edit + 10 + 4 + readInteger(self.o_seed_modification_possibility_fn3_edit + 10)
                local _atol = self.o_seed_modification_possibility_fn4_edit + 2 + 4 + readInteger(self.o_seed_modification_possibility_fn4_edit + 2)
                local code = {
                        0x00, 
                }
                local isInited = allocate(calculateCodeSize(code))
                writeBytes(isInited, compile(code,isInited))

                -- TODO: make this seed folder location setable 
                local code = {
                        0x67, 0x61, 0x6D, 0x65, 0x73, 0x65, 0x65, 0x64, 0x73, 0x2F, 
                        0x6C, 0x69, 0x76, 0x65, 0x00, 
                }
                local liveSeedFile = allocate(calculateCodeSize(code))
                writeBytes(liveSeedFile, compile(code,liveSeedFile))
                local code = {
                        0x72, 0x00, 
                }
                local readTextFlag = allocate(calculateCodeSize(code))
                writeBytes(readTextFlag, compile(code,readTextFlag))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                }
                local readSeedString = allocate(calculateCodeSize(code))
                writeBytes(readSeedString, compile(code,readSeedString))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 
                }
                local loadedSeed = allocate(calculateCodeSize(code))
                writeBytes(loadedSeed, compile(code,loadedSeed))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 
                }
                local cachedSeed = allocate(calculateCodeSize(code))
                writeBytes(cachedSeed, compile(code,cachedSeed))
                local code = {
                -- -- end of alloc
                }
                writeCode(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0, code)
                -- skip 4
                local code = {
                0xE9, function(address, index, labels)
                        local hook = {
                        0x60,  -- pushad
                        0x83, 0x3D, itob(isInited), 00,  -- cmp [isInited],00
                        0x75, 0x0C,  -- jne short 0C
                        0xC7, 0x05, itob(isInited), 0x01, 0x00, 0x00, 0x00,  -- mov [isInited],01
                        0xEB, 0x6A,  -- jmp short 6A
                        0x8B, 0x4E, 0x04,  -- mov ecx,[esi+04]
                        0x89, 0x0D, itob(cachedSeed),  -- mov [cachedSeed],ecx
                        0x31, 0xC9,  -- xor ecx,ecx
                        -- -- loop
                        0xC7, 0x81, itob(readSeedString), 0x00, 0x00, 0x00, 0x00,  -- mov [readSeedString+ecx],00
                        0x41,  -- inc ecx
                        0x81, 0xF9, 0x0A, 0x00, 0x00, 0x00,  -- cmp ecx,0A
                        0x75, 0xED,  -- jne short ED (backwards)
                        0x68, itob(readTextFlag),  -- push readTextFlag
                        0x68, itob(liveSeedFile),  -- push liveSeedFile
                        0xE8, function(index) return itob(getRelativeAddress(index, _fopen, -4)) end,  -- call _fopen
                        0x8B, 0xF0,  -- mov esi,eax
                        0x81, 0xC4, 0x08, 0x00, 0x00, 0x00,  -- add esp,08
                        0x83, 0xFE, 0x00,  -- cmp esi,00
                        0x74, 0x43,  -- je short 46
                        0x56,  -- push esi
                        0x68, 0x01, 0x00, 0x00, 0x00,  -- push 01
                        0x68, 0x0A, 0x00, 0x00, 0x00,  -- push 0A
                        0x68, itob(readSeedString),  -- push readSeedString
                        0xE8, function(index) return itob(getRelativeAddress(index, _internalFileRead, -4)) end,  -- call _internalFileRead
                        0x68, itob(readSeedString),  -- push readSeedString
                        0xE8, function(index) return itob(getRelativeAddress(index, _atol, -4)) end,  -- call _atol
                        0xA3, itob(loadedSeed),  -- mov [loadedSeed],eax
                        0x56,  -- push esi
                        0xE8, function(index) return itob(getRelativeAddress(index, _fclose, -4)) end,  -- call _fclose
                        0x81, 0xC4, 0x18, 0x00, 0x00, 0x00,  -- add esp,18
                        0x61,  -- popad
                        0x53,  -- push ebx
                        0x8B, 0x1D, itob(loadedSeed),  -- mov ebx,[loadedSeed]
                        0x89, 0x5E, 0x04,  -- mov [esi+04],ebx
                        0x5B,  -- pop ebx
                        0x8B, 0x46, 0x04,  -- mov eax,[esi+04]
                        0x57,  -- push edi
                        0x50,  -- push eax
                        0xEB, 0x06,  -- jmp end
                        -- -- end of Read Set Seed
                        0x61,  -- popad
                        0x8B, 0x46, 0x04,  -- mov eax,[esi+04]
                        0x57,  -- push edi
                        0x50,  -- push eax
                        0xe9, relTo(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 4 + 5, -4)
                        }
                        local hookSize = calculateCodeSize(hook)
                        local hookAddress = allocateCode(hookSize)
                        writeCode(hookAddress, hook)
                        return itob(getRelativeAddress(address, hookAddress, -4))
                end,
                }
                writeCode(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 4, code)
        end

        if self.o_seed_modification_possibility then
                -- new DefaultHeader("o_seed_modification_possibility", false)
                local _fopen = self.o_seed_modification_possibility_fn1_edit + 1 + 4 + readInteger(self.o_seed_modification_possibility_fn1_edit + 1)
                local _fwrite = self.o_seed_modification_possibility_fn1_edit + 59 + 4 + readInteger(self.o_seed_modification_possibility_fn1_edit + 59)
                local _fclose = self.o_seed_modification_possibility_fn1_edit + 972 + 4 + readInteger(self.o_seed_modification_possibility_fn1_edit + 972)
                local _itoa = self.o_seed_modification_possibility_fn2_edit + 13 + 4 + readInteger(self.o_seed_modification_possibility_fn2_edit + 13)
                local _internalFileRead = self.o_seed_modification_possibility_fn3_edit + 10 + 4 + readInteger(self.o_seed_modification_possibility_fn3_edit + 10)
                local _atol = self.o_seed_modification_possibility_fn4_edit + 2 + 4 + readInteger(self.o_seed_modification_possibility_fn4_edit + 2)
                local _strlen = self.o_seed_modification_possibility_fn5_edit + 2 + 4 + readInteger(self.o_seed_modification_possibility_fn5_edit + 2)
                local code = {
                        0x00, 
                }
                local isInited = allocate(calculateCodeSize(code))
                writeBytes(isInited, compile(code,isInited))
                local code = {
                        0x01, 
                }
                local needSeedSave = allocate(calculateCodeSize(code))
                writeBytes(needSeedSave, compile(code,needSeedSave))
                local code = {
                        0x67, 0x61, 0x6D, 0x65, 0x73, 0x65, 0x65, 0x64, 0x73, 0x2F, 0x00, 
                }
                local seedFolder = allocate(calculateCodeSize(code))
                writeBytes(seedFolder, compile(code,seedFolder))
                local code = {
                        0x67, 0x61, 0x6D, 0x65, 0x73, 0x65, 0x65, 0x64, 0x73, 0x2F, 
                        0x6C, 0x69, 0x76, 0x65, 0x00, 
                }
                local liveSeedFile = allocate(calculateCodeSize(code))
                writeBytes(liveSeedFile, compile(code,liveSeedFile))
                local code = {
                        0x72, 0x00, 
                }
                local readTextFlag = allocate(calculateCodeSize(code))
                writeBytes(readTextFlag, compile(code,readTextFlag))
                local code = {
                        0x77, 0x00, 
                }
                local writeTextFlag = allocate(calculateCodeSize(code))
                writeBytes(writeTextFlag, compile(code,writeTextFlag))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                }
                local readSeedString = allocate(calculateCodeSize(code))
                writeBytes(readSeedString, compile(code,readSeedString))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                }
                local saveSeedStringBuffer = allocate(calculateCodeSize(code))
                writeBytes(saveSeedStringBuffer, compile(code,saveSeedStringBuffer))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 
                }
                local loadedSeed = allocate(calculateCodeSize(code))
                writeBytes(loadedSeed, compile(code,loadedSeed))
                local code = {
                        0x00, 0x00, 0x00, 0x00, 
                }
                local cachedSeed = allocate(calculateCodeSize(code))
                writeBytes(cachedSeed, compile(code,cachedSeed))
                local code = {
                -- -- end of alloc
                }
                writeCode(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0, code)
                -- skip 4
                local code = {
                0xE9, function(address, index, labels)
                        local hook = {
                        0x60,  -- pushad
                        0x83, 0x3D, itob(isInited), 00,  -- cmp [isInited],00
                        0x75, 0x0C,  -- jne short 0C
                        0xC7, 0x05, itob(isInited), 0x01, 0x00, 0x00, 0x00,  -- mov [isInited],01
                        0xEB, 0x6A,  -- jmp short 6A
                        0x8B, 0x4E, 0x04,  -- mov ecx,[esi+04]
                        0x89, 0x0D, itob(cachedSeed),  -- mov [cachedSeed],ecx
                        0x31, 0xC9,  -- xor ecx,ecx
                        -- -- loop
                        0xC7, 0x81, itob(readSeedString), 0x00, 0x00, 0x00, 0x00,  -- mov [readSeedString+ecx],00
                        0x41,  -- inc ecx
                        0x81, 0xF9, 0x0A, 0x00, 0x00, 0x00,  -- cmp ecx,0A
                        0x75, 0xED,  -- jne short ED (backwards)
                        0x68, itob(readTextFlag),  -- push readTextFlag
                        0x68, itob(liveSeedFile),  -- push liveSeedFile
                        0xE8, function(index) return itob(getRelativeAddress(index, _fopen, -4)) end,  -- call _fopen
                        0x8B, 0xF0,  -- mov esi,eax
                        0x81, 0xC4, 0x08, 0x00, 0x00, 0x00,  -- add esp,08
                        0x83, 0xFE, 0x00,  -- cmp esi,00
                        0x74, 0x46,  -- je short 46
                        0x56,  -- push esi
                        0x68, 0x01, 0x00, 0x00, 0x00,  -- push 01
                        0x68, 0x0A, 0x00, 0x00, 0x00,  -- push 0A
                        0x68, itob(readSeedString),  -- push readSeedString
                        0xE8, function(index) return itob(getRelativeAddress(index, _internalFileRead, -4)) end,  -- call _internalFileRead
                        0x68, itob(readSeedString),  -- push readSeedString
                        0xE8, function(index) return itob(getRelativeAddress(index, _atol, -4)) end,  -- call _atol
                        0xA3, itob(loadedSeed),  -- mov [loadedSeed],eax
                        0x56,  -- push esi
                        0xE8, function(index) return itob(getRelativeAddress(index, _fclose, -4)) end,  -- call _fclose
                        0x81, 0xC4, 0x18, 0x00, 0x00, 0x00,  -- add esp,18
                        0x61,  -- popad
                        0x53,  -- push ebx
                        0x8B, 0x1D, itob(loadedSeed),  -- mov ebx,[loadedSeed]
                        0x89, 0x5E, 0x04,  -- mov [esi+04],ebx
                        0x5B,  -- pop ebx
                        0x8B, 0x46, 0x04,  -- mov eax,[esi+04]
                        0x57,  -- push edi
                        0x50,  -- push eax
                        0xE9, 0xAB, 0x00, 0x00, 0x00,  -- jmp end
                        -- -- end of Read Set Seed
                        0x61,  -- popad
                        0x80, 0x3D, itob(needSeedSave), 01,  -- cmp byte ptr[needSeedSave],01
                        0x0F, 0x85, 0x98, 0x00, 0x00, 0x00,  -- jne short 98
                        0x60,  -- pushad
                        0x31, 0xC9,  -- xor ecx,ecx
                        -- -- loop
                        0xC7, 0x81, itob(saveSeedStringBuffer), 0x00, 0x00, 0x00, 0x00,  -- mov [saveSeedStringBuffer+ecx],00
                        0x41,  -- inc ecx
                        0x81, 0xF9, 0x3D, 0x00, 0x00, 0x00,  -- ecx,3D
                        0x75, 0xED,  -- jne short ED (backwards)
                        0x31, 0xC9,  -- xor ecx,ecx
                        0x31, 0xDB,  -- xor ebx,ebx
                        -- -- loop
                        0x8A, 0x99, itob(seedFolder),  -- mov bl,byte ptr[seedFolder+ecx]
                        0x88, 0x99, itob(saveSeedStringBuffer),  -- mov [saveSeedStringBuffer+ecx],bl
                        0x41,  -- inc ecx
                        0x84, 0xDB,  -- test bl,bl
                        0x75, 0xEF,  -- jne short EF (backwards)
                        0x49,  -- dec ecx
                        0x8D, 0x81, itob(saveSeedStringBuffer),  -- lea eax,[saveSeedStringBuffer+ecx]
                        0x68, 0x0A, 0x00, 0x00, 0x00,  -- push 0A
                        0x68, 0x10, 0x00, 0x00, 0x00,  -- push 10
                        0x50,  -- push eax
                        0xFF, 0x35, itob(cachedSeed),  -- push [cachedSeed]
                        0xE8, function(index) return itob(getRelativeAddress(index, _itoa, -4)) end,  -- call _itoa
                        0x8B, 0x44, 0x24, 0x04,  -- mov eax,[esp+04]
                        0xA3, itob(loadedSeed),  -- mov [loadedSeed],eax
                        0x81, 0xC4, 0x10, 0x00, 0x00, 0x00,  -- add esp,10
                        0x68, itob(writeTextFlag),  -- push writeTextFlag
                        0x68, itob(saveSeedStringBuffer),  -- push saveSeedStringBuffer
                        0xE8, function(index) return itob(getRelativeAddress(index, _fopen, -4)) end,  -- call _fopen
                        0x8B, 0xF0,  -- mov esi,eax
                        0x81, 0xC4, 0x08, 0x00, 0x00, 0x00,  -- add esp,08
                        0xFF, 0x35, itob(loadedSeed),  -- push [loadedSeed]
                        0xE8, function(index) return itob(getRelativeAddress(index, _strlen, -4)) end,  -- call _strlen
                        0x56,  -- push esi
                        0x68, 0x01, 0x00, 0x00, 0x00,  -- push 01
                        0x50,  -- push eax
                        0xFF, 0x35, itob(loadedSeed),  -- push [loadedSeed]
                        0xE8, function(index) return itob(getRelativeAddress(index, _fwrite, -4)) end,  -- call _fwrite
                        0x56,  -- push esi
                        0xE8, function(index) return itob(getRelativeAddress(index, _fclose, -4)) end,  -- call _fclose
                        0x81, 0xC4, 0x18, 0x00, 0x00, 0x00,  -- add esp,18
                        0x61,  -- popad
                        0x8B, 0x46, 0x04,  -- mov eax,[esi+04]
                        0x57,  -- push edi
                        0x50,  -- push eax
                        0xe9, relTo(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 4 + 5, -4)
                        }
                        local hookSize = calculateCodeSize(hook)
                        local hookAddress = allocateCode(hookSize)
                        writeCode(hookAddress, hook)
                        return itob(getRelativeAddress(address, hookAddress, -4))
                end,
                }
                writeCode(self.o_seed_modification_possibility_edit + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 0 + 4, code)
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
