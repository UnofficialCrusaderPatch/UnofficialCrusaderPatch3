-- imports
local AOBScan = core.AOBScan
local readInteger = core.readInteger
local readSmallInteger = core.readSmallInteger
local writeInteger = core.writeInteger
local hookCode = core.hookCode

-- exports
local exports = {}

local assignSelectionToKey_address = AOBScan("83 EC 14 53 8B 5C 24 20 69 DB ? ? ? ?") -- 0x459c10
local arraySize = readInteger(assignSelectionToKey_address + 0x83)


local assignUnitToKey
local deleteUnitFromKey
local shiftRemainingArrayElements

local assignSelectionToKey_hook = function(numberKeyArrays, number, _) -- last arg = tribeID, doesn't get used
    local shc = modules.shcLibrary.getLibrary()
    local unitsTotal = readInteger(shc.DAT_UnitProcessorClass_UnitCountPlusOne) - 1
    if unitsTotal < 1 then return end
    
    local pos = 0
    for unitID = 1, unitsTotal do
        local unit_offset   = shc.SEC_Units + (unitID * 0x490)
        local logicalState  = readSmallInteger(unit_offset + 0x8c)
        local dying         = readSmallInteger(unit_offset + 0x2a0)
        local playerID      = readSmallInteger(unit_offset + 0x96)
        local isSelected    = readSmallInteger(unit_offset + 0x34)

        if
            logicalState == 2 and
            dying        == 0 and
            playerID     == readInteger(shc.SEC_CurrentPlayerSlotID) and
            isSelected   == 1
        then
            local array = numberKeyArrays + (number * arraySize * 8)
            local unitIDSelfRef = readInteger(unit_offset + 0x98)
            assignUnitToKey(array, pos, unitID, unitIDSelfRef)

            for otherNumber = 0, 9 do
                if otherNumber ~= number then
                    local otherArray = numberKeyArrays + (otherNumber * arraySize * 8)
                    deleteUnitFromKey(otherArray, arraySize, unitID)
                end
            end
            
            pos = pos + 8
        end
    end
end

assignUnitToKey = function(keyArray, pos, unitID, unitIDSelfRef)
    writeInteger(keyArray + pos, unitID)
    writeInteger(keyArray + pos + 4, unitIDSelfRef)
end

deleteUnitFromKey = function(keyArray, arraySize, unitID)
    for pos = 0, arraySize * 8, 8 do
        local otherUnitID = readInteger(keyArray + pos)
        if otherUnitID == -1 then break end
        if unitID == otherUnitID then
            shiftRemainingArrayElements(keyArray, arraySize, pos)
            break
        end
    end
end

shiftRemainingArrayElements = function(keyArray, arraySize, pos)
    while pos < (arraySize * 8) - 8 do
        local unitID = readInteger(keyArray + pos + 8)
        local unitIDSelfRef = readInteger(keyArray + pos + 4 + 8)
        assignUnitToKey(keyArray, pos, unitID, unitIDSelfRef)
        if unitID == -1 then break end
        pos = pos + 8
    end
    assignUnitToKey(keyArray, pos, -1, -1)
end


exports.enable = function()
    hookCode(assignSelectionToKey_hook, assignSelectionToKey_address, 3, 1, 8)
end

return exports
