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

--____NEW CHANGE: o_fast_placing
return {

    init = function(self, config)
        -- 00445D8C
        self.o_fast_placing_edit = AOBScan("83 FE 63 0F 85 ? ? ? ? A1")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fast_placing_common", true)
        local code = {
         -- affected buildings
        }
        writeCode(self.o_fast_placing_edit, code)
        local code = {
                0x62, 0x00,  -- killing pit
                0x63, 0x00,  -- pitch ditch
                0x33, 0x00,  -- woodcutter
             -- bad things
                0xB0, 0x00, 
                0x2D, 0x01, 0x2E, 0x01, 0x2F, 0x01, 0x30, 0x01,  -- cesspit
                0xB1, 0x00, 
                0x31, 0x01, 
                0x33, 0x01, 
                0x34, 0x01, 
                0x32, 0x01, 
                0x36, 0x01, 
                0x37, 0x01, 
             -- good things
                0xAF, 0x00, 
                0x44, 0x01, 
                0xA0, 0x00, 0xA1, 0x00, 0xA2, 0x00, 0xA3, 0x00, 0xA4, 0x00, 0xA5, 0x00,  -- small garden
                0xA6, 0x00, 0xA7, 0x00, 0xA8, 0x00,  -- middle garden
                0xA9, 0x00, 0xAA, 0x00, 0xAB, 0x00,  -- big garden
                0x39, 0x01, 0x3A, 0x01, 0x3B, 0x01, 0x3C, 0x01, 0x3D, 0x01,  -- statue
                0x3E, 0x01, 0x3F, 0x01,  -- shrine
                0x4A, 0x00,  -- mill
                0x56, 0x01,  -- water pot
                0x4B, 0x00,  -- bakery
                0x36, 0x00,  -- hovel
                0x00, 0x00,  -- delimiter
        }
        local BuildingIDArray = allocate(calculateCodeSize(code))
        writeBytes(BuildingIDArray, compile(code,BuildingIDArray))
        local Skip = self.o_fast_placing_edit + 0 + 5 + 4 + readInteger(self.o_fast_placing_edit + 0 + 5)
        local Continue = self.o_fast_placing_edit + 0 + 9
        local code = {
         -- check building
            0xE9, function(address, index, labels)
                local hook = {
                    0x52,  -- push edx
                    0x51,  -- push ecx
                    0xBA, 0x00, 0x00, 0x00, 0x00,  -- mov edx,0
                    "Rotate", 
                    0x8D, 0x8A, itob(BuildingIDArray),  -- lea ecx,[BuildingIDArray + edx]
                    0x0F, 0xB7, 0x09,  -- movzx ecx, word ptr [ecx]
                    0x85, 0xC9,  -- test ecx, ecx
                    0x74, 0x0F,  -- jz short JMPSkip
                    0x39, 0xCE,  -- cmp esi,ecx
                    0x74, 0x04,  -- je short JMPContinue
                    0x42,  -- inc edx
                    0x42,  -- inc edx
                    0xEB, 0xEB,  -- jmp short Rotate
                 -- JMPContinue
                    0x59,  -- pop ecx
                    0x5A,  -- pop edx
                    0xE9, function(index) return itob(getRelativeAddress(index, Continue, -4)) end,  -- jmp Continue
                 -- JMPSkip
                    0x59,  -- pop ecx
                    0x5A,  -- pop edx
                    0xE9, function(index) return itob(getRelativeAddress(index, Skip, -4)) end,  -- jmp Skip
                    0xe9, relTo(self.o_fast_placing_edit + 0 + 9, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_fast_placing_edit + 0, code)
        local timeGetTime = readInteger(self.o_fast_placing_edit + 0 + 9 + 0 + 9 + 6)
        local SkipSpeedCap = self.o_fast_placing_edit + 0 + 9 + 0 + 9 + 10 + 22 + 1 + 20 + 0
        local code = {
         -- reverse assembler optimization
            0xE9, function(address, index, labels)
                local hook = {
                    0x83, 0xF8, 0x63,  -- cmp eax,0x63
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, SkipSpeedCap, -4)) end,  -- je SkipSpeedCap
                 -- original code
                    0x8B, 0x35, itob(timeGetTime),  -- mov esi,ds:timeGetTime
                    0xe9, relTo(self.o_fast_placing_edit + 0 + 9 + 0 + 9 + 10, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
            0x90, 0x90, 0x90, 0x90, 0x90
        }
        writeCode(self.o_fast_placing_edit + 0 + 9 + 0 + 9, code)
        local code = {
         -- reduce multiplayer speed cap
            0x64, 
        }
        writeCode(self.o_fast_placing_edit + 0 + 9 + 0 + 9 + 10 + 22, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
