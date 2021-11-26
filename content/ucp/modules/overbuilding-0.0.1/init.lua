local scanForAOB = core.scanForAOB
local exposeCode = core.exposeCode
local detourCode = core.detourCode
local insertCode = core.insertCode
local allocateCode = core.allocateCode
local relTo = core.relTo
local rI = core.readInteger
local rSI = core.readSmallInteger
local rB = core.readByte

local exports = {}

local someClass = rI(scanForAOB("39 1D ? ? ? ? 89 1D ? ? ? ? 7E 52")+18) -- 0x191D768
local offset = rI(scanForAOB("8B 03 89 86 24 D8 02 00")+43) -- 0x109E70
local AOB1 = scanForAOB("0F BF 88 ? ? ? ? 0F BF 80 ? ? ? ? 8D 3C 49") -- 0057960B
local UnitProcessorClass = rI(AOB1+3) - 0x950 -- 0x1387F38

local initBuildingCmpA = scanForAOB("A1 ? ? ? ? 99 2B C2 D1 F8 8B CD")+48 -- 00445B7B
local initBuildingCmpB = scanForAOB("8B 44 24 2C 50 51 8B 4C 24 24")+15 -- 00516325
local initWallCmpA = scanForAOB("E8 ? ? ? ? 83 3D ? ? ? ? 00 75 46") -- 0043800B
local initWallCmpB = scanForAOB("E8 ? ? ? ? 83 BF ? ? ? ? 00 0F 85 ? ? ? ? 8B 44 24 3C") -- 00502F67
local allowOverbuildingWall = scanForAOB("74 1F F7 C1 00 01 00 00 75 17 0F BF C8 69 C9 90 04 00 00 66 83 B9 ? ? ? ? 3E")+19 -- 00502C17
local allowOverbuildingBuilding = scanForAOB("74 23 5F 5E 5D B8 01 00 00 00 5B 83 C4 0C C2 10 00 69 ED 90 04 00 00 66 83 BD ? ? ? ? 3E")+23 -- 004F9BEA
local buildFunctionExit = scanForAOB("83 FA 46 75 0A C7 86 ? ? ? ? 04 00 00 00 5F 5E 5D")+15 -- 004F9B47
local repositionOverbuiltUnit = scanForAOB("E8 ? ? ? ? F7 84 9E ? ? ? ? 00 40 00 40") -- 00516521
local positionUnitAddress = scanForAOB("53 8B 5C 24 0C 81 FB 8F 01 00 00 55 8B E9") -- 0053E900
local setPathAddress = scanForAOB("83 EC 08 8B 44 24 0C 8B D0") -- 0053D3D0


exports.enable = function(self)
    local wallArray = allocateCode({
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1E, 0x1F, 0x20, 0x21,
        0x22, 0x23, 0x24, 0x25, 0x26, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x34,
        0x35, 0x36, 0x37, 0x38, 0x39, 0x3C, 0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45,
        0x46, 0x47, 0x48, 0x49, 0x4B, 0x4C,
        0x00 -- delimiter
    })
    
    local towerArray = allocateCode({
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1E, 0x1F, 0x20, 0x21,
        0x22, 0x23, 0x24, 0x25, 0x26, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x34,
        0x35, 0x36, 0x37, 0x38, 0x39, 0x3C, 0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45,
        0x46, 0x47, 0x48, 0x49, 0x4B, 0x4C,
        0x00 -- delimiter
    })
    
    local buildingArray = allocateCode({
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x2F, 0x30, 0x31, 0x34,
        0x35, 0x36, 0x38, 0x39, 0x3E, 0x3F, 0x36, 0x38, 0x39, 0x3E, 0x3F, 0x40, 0x44, 0x45,
        0x00 -- delimiter
    })
    
    local towerIDArray = allocateCode({
        0x6E, 0x6F, 0x70, 0x71, 0x72, -- tower variations
        0x90, 0x91, -- small gate variations
        0x92, 0x93, -- big gate variations
        0x62, -- killing pit
        0x63, -- pitch
        0x00 -- delimiter
    })


    ----- implement comparison -----

    local cmpFlag = allocateCode({0x00})
    local playerToCompare = allocateCode({0x00, 0x00, 0x00, 0x00})
    local checkCanBuild = initBuildingCmpB + 5 + rI(initBuildingCmpB + 1)
    local wallFunc = initWallCmpA + 5 + rI(initWallCmpA + 1)

    insertCode(initBuildingCmpA, 6, {
        -- initialize
        0xC6, 0x05, cmpFlag, 0x01, -- mov byte ptr[cmpFlag],01
        0x50, -- push eax
        0xB8, someClass, -- mov eax,someClass
        0x83, 0xC0, 0x04, -- add eax,4
        0x8B, 0x80, offset, -- mov eax,[eax+offset]
        0xA3, playerToCompare, -- mov [playerToCompare],eax
        0x58, -- pop eax
        -- original code
        0x0F, 0x85, relTo(initBuildingCmpA, -4 + 187), -- jnz 0x445C36
    })

    insertCode(initBuildingCmpA + 231, 6, {
        -- deinitialize
        0xC6, 0x05, cmpFlag, 0x00, -- mov byte ptr[cmpFlag],00
        -- original code
        0x8D, 0x46, 0xCE, -- lea eax,[esi-32]
        0x83, 0xF8, 0x37 -- cmp eax,37
    })

    insertCode(initBuildingCmpB, 5, {
        -- initialize
        0xC6, 0x05, cmpFlag, 0x01, -- mov byte ptr[cmpFlag],01
        0x50, -- push eax
        0xB8, someClass, -- mov eax,someClass
        0x8B, 0x80, offset, -- mov eax,[eax+offset]
        0xA3, playerToCompare, -- mov [playerToCompare],eax
        0x58, -- pop eax
        -- original code
        0xE8, relTo(checkCanBuild, -4), -- call checkCanBuild
        -- deinitialize
        0xC6, 0x05, cmpFlag, 0x00 -- mov byte ptr[cmpFlag],00
    })

    insertCode(initWallCmpA, 5, {
        -- initialize compare
        0xC6, 0x05, cmpFlag, 0x01, -- mov byte ptr[cmpFlag],01
        0x50, -- push eax
        0xB8, someClass, -- mov eax,someClass
        0x83, 0xC0, 0x04, -- add eax,4
        0x8B, 0x80, offset, -- mov eax,[eax+offset]
        0xA3, playerToCompare, -- mov [playerToCompare],eax
        0x58, -- pop eax
        -- original code
        0xE8, relTo(wallFunc, -4), -- call wallFunc
        -- deinitialize compare
        0xC6, 0x05, cmpFlag, 0x00 -- mov byte ptr[cmpFlag],00
    })

    insertCode(initWallCmpB, 5, {
        -- initialize compare
        0xC6, 0x05, cmpFlag, 0x01, -- mov byte ptr[cmpFlag],01
        0x50, -- push eax
        0xB8, someClass, -- mov eax,someClass
        0x8B, 0x80, offset, -- mov eax,[eax+offset]
        0xA3, playerToCompare, -- mov [playerToCompare],eax
        0x58, -- pop eax
        -- original code
        0xE8, relTo(wallFunc, -4), -- call wallFunc
        -- deinitialize compare
        0xC6, 0x05, cmpFlag, 0x00 -- mov byte ptr[cmpFlag],00
    })


    ----- allow overbuilding -----

    local unitBaseAddress = rI(allowOverbuildingWall + 3)

    local inByteArray = allocateCode({
        --[[
        Searches a byte in a byte array and writes 1 if found in eax, otherwise 0.
        Custom end byte can be set.
        
        Parameters:
        - byte to search for
        - address where the byte array is found (end the bytearray with end byte)
        - end byte (such as 00)
        
        Return:
        - eax will contain 1 if found in array, otherwise 0.
        
        Example:
        push 00             -- end byte is 00
        push 025B0831       -- address set
        push cx             -- we search for this byte
        call inByteArray    -- call function
        cmp eax,01          -- check if we found it
        ]]

        0x53, -- push ebx
        0x51, -- push ecx
        0x52, -- push edx
        0x31, 0xC9, -- xor ecx,ecx
        0x31, 0xDB, -- xor ebx,ebx
        0x31, 0xD2, -- xor edx,edx
        0xB8, 0x00, 0x00, 0x00, 0x00, -- mov eax,00
        0x8B, 0x54, 0x24, 0x14, -- mov edx,[esp+14]
        0x8A, 0x1C, 0x11, -- mov bl,[ecx+edx]
        0x3A, 0x5C, 0x24, 0x18, -- cmp bl,[esp+18]
        0x0F, 0x84, 0x12, 0x00, 0x00, 0x00, -- je short 0x12
        0xB8, 0x01, 0x00, 0x00, 0x00, -- mov eax,01
        0x3B, 0x5C, 0x24, 0x10, -- cmp ebx,[esp+10]
        0x0F, 0x84, 0x03, 0x00, 0x00, 0x00, -- je short 0x03
        0x41, -- inc ecx
        0xEB, 0xD8, -- jmp short backwards
        0x5A, -- pop edx
        0x59, -- pop ecx
        0x5B, -- pop ebx
        0xC2, 0x0C, 0x00 -- ret 000C
    })

    insertCode(allowOverbuildingWall, 8, {
        0x50, -- push eax
        0x83, 0xC1, 0x08, -- add ecx,08
        0x0F, 0xB6, 0x81, unitBaseAddress, -- movzx eax, byte ptr[ecx+unitBaseAddress]
        0x83, 0xE9, 0x08, -- sub ecx,08
        -- Check owner
        0x80, 0x3D, cmpFlag, 0x00, -- cmp byte ptr[cmpFlag],00
        0x74, 0x2A, -- je short 2A
        0x83, 0xF8, 0x00, -- cmp eax,00  -- check for neutral
        0x74, 0x8, -- je short 0x8
        0x3B, 0x05, playerToCompare, -- cmp eax,[playerToCompare]
        0x75, 0x1D, -- jne short 0x1D
        0x0F, 0xB6, 0x81, unitBaseAddress, -- movzx eax, byte ptr[ecx+unitBaseAddress]
        0x6A, 0x00, -- push 00
        0x68, wallArray, -- push wallArray
        0x50, -- push eax
        0xE8, relTo(inByteArray, -4), -- call inByteArray
        0x83, 0xF8, 0x01, -- cmp eax,01
        0x0F, 0x84, 0x08, 0x00, 0x00, 0x00, -- je short 0x08
        0x66, 0x83, 0xB9, unitBaseAddress, 0x3E, -- cmp word ptr[ecx+unitBaseAddress],3E
        0x58, -- pop eax
    })
    
    insertCode(allowOverbuildingBuilding, 14, {
        0x50, -- push eax
        0x53, -- push ebx
        0x51, -- push ecx
        0x31, 0xDB, -- xor ebx,ebx
        0x31, 0xC9, -- xor ecx,ecx
        0x83, 0xC5, 0x08, -- add ebp,08
        0x0F, 0xB6, 0x85, unitBaseAddress, -- movzx eax, byte ptr[ebp+unitBaseAddress]
        0x83, 0xED, 0x08, -- sub ebp,08
        -- Check owner
        0x80, 0x3D, cmpFlag, 0x00, -- cmp byte ptr[cmpFlag],00
        0x74, 0x72, -- je short 0x72
        0x83, 0xF8, 0x00, -- cmp eax,00  -- check for neutral
        0x74, 0xC, -- je short 0xC
        0x3B, 0x05, playerToCompare, -- cmp eax,[playerToCompare]
        0x0F, 0x85, 0x61, 0x00, 0x00, 0x00, -- jne short 0x61
        0x0F, 0xB6, 0x44, 0x24, 0x34, 0x90, 0x90, -- movzx eax,byte ptr [esp+34]
        0x6A, 0x00, -- push 00
        0x68, towerIDArray, -- push towerIDArray
        0x50, -- push eax
        0xE8, relTo(inByteArray, -4), -- call inByteArray
        0x83, 0xF8, 0x01, -- cmp eax,01
        0x0F, 0x84, 0x05, 0x00, 0x00, 0x00, -- je short 0x05
        0xE9, 0x22, 0x00, 0x00, 0x00, -- jmp short 0x22
        -- Tower building
        0x0F, 0xB6, 0x85, unitBaseAddress, -- movzx eax, byte ptr [ebp+unitBaseAddress]
        0x6A, 0x00, -- push 00
        0x68, towerArray, -- push towerArray
        0x50, -- push eax
        0xE8, relTo(inByteArray, -4), -- call inByteArray
        0x83, 0xF8, 0x01, -- cmp eax,01
        0x0F, 0x84, 0x35, 0x00, 0x00, 0x00, -- je short 0x35
        0xE9, 0x1D, 0x00, 0x00, 0x00, -- jmp short 0x1D
        -- Not tower building
        0x0F, 0xB6, 0x85, unitBaseAddress, -- movzx eax, byte ptr [ebp+unitBaseAddress]
        0x6A, 0x00, -- push 00
        0x68, buildingArray, -- push buildingArray
        0x50, -- push eax
        0xE8, relTo(inByteArray, -4), -- call inByteArray
        0x83, 0xF8, 0x01, -- cmp eax,01
        0x0F, 0x84, 0x13, 0x00, 0x00, 0x00, -- je short 0x13
        0x66, 0x83, 0xBD, unitBaseAddress, 0x3E, -- cmp word ptr [ebp+unitBaseAddress],3E
        0x59, -- pop ecx
        0x5B, -- pop ebx
        0x58, -- pop eax
        0x0F, 0x85, relTo(buildFunctionExit, -4), -- jne buildFunctionExit
        0xEB, 0x03, -- jmp short 03
        0x59, -- pop ecx
        0x5B, -- pop ebx
        0x58, -- pop eax
    })


    ----- reposition workers -----
    
    local unitArray = UnitProcessorClass + 0x614
    local TileTranslationMatrixX = rI(AOB1 + 20)
    local TerrainHeightTileMap = rI(AOB1 + 28)
    
    local positionUnit = exposeCode(positionUnitAddress, 5, 1)
    local setPath = exposeCode(setPathAddress, 5, 1)

    local repositionUnit = function(registers)
        local this = registers.ECX
        local unitID = rI(registers.ESP + 8) -- esp value not correct!
        local unitArrayOffset = unitArray + (unitID * 0x490)
        local previousPosX = rSI(unitArrayOffset + 0xCC)
        local previousPosY = rSI(unitArrayOffset + 0xCE)
        local terrainHeight= rB(TerrainHeightTileMap + rI(TileTranslationMatrixX + (previousPosY * 12)) + previousPosX)
        local destinationY = rSI(unitArrayOffset + 0xCA)
        local destinationX = rSI(unitArrayOffset + 0xC8)

        positionUnit(this, unitID, previousPosX, previousPosY, terrainHeight)
        setPath(this, unitID, destinationX, destinationY, 0)

        return registers
    end

    local repositionUnitAddress = insertCode(repositionOverbuiltUnit, 5, {
        0x90, 0x90, 0x90, 0x90, 0x90, -- plan detour
        0x83, 0xC4, 0x04 -- add esp,4
    })
    detourCode(repositionUnit, repositionUnitAddress, 5)
end

exports.disable = function(self)
end

return exports