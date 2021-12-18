-- imports
local scanForAOB = core.scanForAOB
local readInteger = core.readInteger
local readSmallInteger = core.readSmallInteger
local writeInteger = core.writeInteger
local hookCode = core.hookCode

-- exports
local exports = {}

local assignSelectionToKey_address = scanForAOB("83 EC 14 53 8B 5C 24 20 69 DB ? ? ? ?") -- 0x459c10
local SEC_CurrentPlayerSlotID = readInteger(scanForAOB("8B 04 BD ? ? ? ? 8B 15 ? ? ? ? 83 C9 FF") + 9) -- 0x1a275dc
local DAT_UnitProcessorClass_UnitCountPlusOne = readInteger(scanForAOB("B9 ? ? ? ? E8 ? ? ? ? 69 F6 ? ? ? ? 0F BF B6 ? ? ? ?") + 1) -- 0x1387f38

local arraySize = readInteger(assignSelectionToKey_address + 0x83)
local SEC_Units = readInteger(assignSelectionToKey_address + 0x4e) - 0x8c
local logicalState_offset = 0x8c
local dying_offset = 0x2a0
local unitIDSelfRef_offset = 0x98
local playerID_offset = 0x96
local isSelected_offset = 0x34

local assignSelectionToKey_hook = function(numberKeyArrays, number, _) -- last arg = tribeID, doesn't get used
    local unitsTotal = readInteger(DAT_UnitProcessorClass_UnitCountPlusOne) - 1
    if unitsTotal < 1 then return end
    
    local array = numberKeyArrays + (number * arraySize * 8)
    local pos = 0
    for unitID = 1, unitsTotal do
        local unit_offset   = SEC_Units + (unitID * 0x490)
        local logicalState  = readSmallInteger( unit_offset + logicalState_offset  )
        local dying         = readSmallInteger( unit_offset + dying_offset         )
        local playerID      = readSmallInteger( unit_offset + playerID_offset      )
        local isSelected    = readSmallInteger( unit_offset + isSelected_offset    )

        if
            logicalState == 2 and
            dying        == 0 and
            playerID     == readInteger(SEC_CurrentPlayerSlotID) and
            isSelected   == 1
        then
            -- assign unit to key
            local unitIDSelfRef = readInteger(unit_offset + unitIDSelfRef_offset)
            writeInteger(array + pos, unitID)
            writeInteger(array + pos + 4, unitIDSelfRef)
            pos = pos + 8

            -- delete unit from other key array
            local otherArray
            local pos
            local otherUnitID
            for otherNumber = 0, 9 do
                if otherNumber ~= number then
                    pos = 0
                    otherArray = numberKeyArrays + (otherNumber * arraySize * 8)
                    repeat
                        otherUnitID = readInteger(otherArray + pos)
                        if otherUnitID == -1 then break end
                        if unitID == otherUnitID then
                            writeInteger(otherArray + pos, -1)
                            writeInteger(otherArray + pos + 4, -1)
                            break
                        end
                        pos = pos + 8
                    until pos == arraySize * 8
                    
                    -- shift remaining array elements
                    local nextUnitID
                    while pos < (arraySize * 8) - 8 do
                        nextUnitID = readInteger(otherArray + pos + 8)
                        writeInteger(otherArray + pos, nextUnitID)
                        writeInteger(otherArray + pos + 4, readInteger(otherArray + pos + 4 + 8))
                        if nextUnitID == -1 then break end
                        pos = pos + 8
                    end
                end
            end
        end

    end
end

exports.enable = function()
    hookCode(assignSelectionToKey_hook, assignSelectionToKey_address, 3, 1, 8)
end

return exports
