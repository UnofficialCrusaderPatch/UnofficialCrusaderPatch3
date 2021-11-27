local ns = {}

local ECX = core.readInteger(core.AOBScan("83 c0 ff 69 c0 a4 02 00 00 83 7c 08 54 00 57 8d 3c 08 7e 50 6a 01 6a 03 52 b9 ? ? ? ? e8 ? ? ? ? 8b c8 85 c9 7f 1d b9 01 00 00 00") + 26)

-- playerID, buildingType, includeBool
local countBuildings_address = core.AOBScan("8b 51 08 33 c0 83 fa 01 7e 4f 53 8b 5c 24 08 55 56 8b 74 24 18 57 8b 7c 24 18 81 c1 16 04 00 00 83 c2 ff")
ns.countBuildingsForPlayer = core.exposeCode(countBuildings_address, 4, 1) -- ECX: 0xf98520

-- playerID, buildingType
local findFirst_address = core.AOBScan("53 56 8b 71 08 b8 01 00 00 00 3b f0 57 7e 3c 8b 7c 24 14 8b 5c 24 10 81 c1 10 04 00 00 8d 49 00")
ns.findFirstBuildingIDForPlayerAndType = core.exposeCode(findFirst_address, 3, 1) -- ECX: 0x00f98520

-- playerID, buildingType, previous buildingID
local findNext_address = core.AOBScan("8b 44 24 0c 53 56 8b 71 08 83 c0 01 3b c6 57 7d 42 8b 7c 24 14 8b 5c 24 10 8b d0 69 d2 2c 03 00 00 8d 8c 0a e4 00 00 00")
ns.findNextBuildingForPlayerAndType = core.exposeCode(findNext_address, 4, 1) -- ECX: 0x00f98520

--local oxtetherLinkedQuarryID_address = core.readInteger(core.AOBScan("0f bf 0a 85 c9 74 25 69 c9 2c 03 00 00 66 83 b9 ? ? ? ? 04 75 10 0f bf 89 ? ? ? ? 3b ce 75 05 83 c3 01 eb 05") + 26)

local addrset1 = core.AOBScan("8b c5 69 c0 f4 39 00 00 3b f7 8d 80 ? ? ? ? 53 89 44 24 14 89 38 0f 84 bb 00 00 00")
local highestLoadQuarryID_address = core.readInteger(addrset1+12)
local quarryStockPileID_address = core.readInteger(addrset1+41)
local stoneInStock_address = core.readInteger(addrset1+41+12)
local quarryLinkedOxtethersArray_address = core.readInteger(addrset1+41+12+8)
local otBuildingType_address = core.readInteger(addrset1+41+12+8+23)
local oxtetherLinkedQuarryID_address = core.readInteger(addrset1+41+12+8+23+10)

ns.oxTetherParameters = {
    -- total max ox tethers for a player
    maxOxTethers = 100,
    -- total max ox tethers will be quarryCount * value
    dynamicMaxOxTethers = 3,
    -- min ox tethers to build. This does not work, because the AI will place minOxTethers right when it built the first quarry
    --minOxTethers = 10,
    -- min ox tethers per quarry
    minimalOxTethersPerQuarry = 1,
    -- max ox tethers per quarry
    maximumOxTethersPerQuarry = 6,
    -- decision value for building an extra ox tether if a quarry needs it: stoneCount / tetherCount
    -- A full pile is 48 stones.
    tresholdStoneLoad = 20,
}

local function countLinkedOxTethers(playerID, quarryID)
    local oxTetherID = ns.findFirstBuildingIDForPlayerAndType(ECX, playerID, 0x04)

    if oxTetherID == 0 then
        return 0
    end

    local count = 0

    while oxTetherID ~= 0 do

        local oxtetherLinkedQuarryID = core.readSmallInteger(oxtetherLinkedQuarryID_address + (0x32c * oxTetherID))
        if oxtetherLinkedQuarryID == quarryID then
            count = count + 1
        end

        oxTetherID = ns.findNextBuildingForPlayerAndType(ECX, playerID, 0x04, oxTetherID)
    end

    return count
end

local function newAiRequiresExtraOxTethers(playerID)
    local quarryCount = ns.countBuildingsForPlayer(ECX, playerID, 0x14, 0)
    local oxtetherCount = ns.countBuildingsForPlayer(ECX, playerID, 0x4, 0)

    print("Player #" .. playerID .. ": quarries = " .. quarryCount .. " ox tethers = " .. oxtetherCount)

    if quarryCount == 0 then
        print("Player #" .. playerID .. ": no ox tethers required")
        return 0
    end
    if oxtetherCount >= ns.oxTetherParameters.maxOxTethers then
        print("Player #" .. playerID .. ": over or at the ox tether limit")
        return 0
    end
    if oxtetherCount >= (quarryCount * ns.oxTetherParameters.dynamicMaxOxTethers) then
        print("Player #" .. playerID .. ": over or at the dynamic ox tethers limit: " .. (quarryCount * ns.oxTetherParameters.dynamicMaxOxTethers))
        return 0
    end

    -- set highest loaded quarry to 0
    core.writeInteger(highestLoadQuarryID_address + (0x39f4 * playerID), 0)

    local lowestOxTetherCountQuarryID = 0
    local lowestOxTetherCount = ns.oxTetherParameters.maxOxTethers

    local highestLoadQuarryID = 0
    local highestLoad = 0

    local quarryID = ns.findFirstBuildingIDForPlayerAndType(ECX, playerID, 0x14)

    if quarryID == 0 then
        return 0
    end

    while quarryID ~= 0 do

        local quarryStockPileID = core.readSmallInteger(quarryStockPileID_address + (0x32c * quarryID))
        local stoneInStock = core.readInteger(stoneInStock_address + (0x32c * quarryStockPileID))

        local linkedTetherCount = countLinkedOxTethers(playerID, quarryID)

        -- Although this part is not required anymore for counting tethers, it is still required to clean up tether linking. Until we know what that is used for throughout the game, let's keep it.
        local quarryLinkedOxtethersArray = quarryLinkedOxtethersArray_address + (0x32c * quarryID)
        for i = 0, 2, 1 do
            local oxTetherID = core.readSmallInteger(quarryLinkedOxtethersArray + (2 * i))
            if oxTetherID ~= 0 then
                local otBuildingType = core.readSmallInteger(otBuildingType_address + (0x32c * oxTetherID))
                local oxtetherLinkedQuarryID = core.readSmallInteger(oxtetherLinkedQuarryID_address + (0x32c * oxTetherID))

                if otBuildingType == 0x4 and oxtetherLinkedQuarryID == quarryID then
                    -- linkedTetherCount = linkedTetherCount + 1
                else
                    core.writeSmallInteger(quarryLinkedOxtethersArray + (2 * i), 0)
                end

            end

        end

        local overMax = false

        if linkedTetherCount >= ns.oxTetherParameters.maximumOxTethersPerQuarry then
            print("Player #" .. playerID .. ": has too many ox tethers (" .. linkedTetherCount .. ") for quarry #" .. quarryID)
            overMax = true
        end

        if linkedTetherCount < ns.oxTetherParameters.minimalOxTethersPerQuarry then
            print("Player #" .. playerID .. ": has too few ox tethers (" .. linkedTetherCount .. ") for quarry #" .. quarryID)
            core.writeInteger(highestLoadQuarryID_address + (0x39f4 * playerID), quarryID)
            return 1
        end

        if linkedTetherCount < lowestOxTetherCount then
            lowestOxTetherCount = linkedTetherCount
            lowestOxTetherCountQuarryID = quarryID
        end

        local stoneLoad = 0
        if linkedTetherCount > 0 then
            stoneLoad = stoneInStock / linkedTetherCount
        else
            stoneLoad = stoneInStock -- divide by 0 is not an issue this way
        end

        if stoneLoad > highestLoad and not overMax then
            highestLoad = stoneLoad
            highestLoadQuarryID = quarryID
        end

        quarryID = ns.findNextBuildingForPlayerAndType(ECX, playerID, 0x14, quarryID)
    end

    print("Player #" .. playerID .. " heaviest loaded quarry is #" .. highestLoadQuarryID .. " (" .. highestLoad .. ")")

    if highestLoad > ns.oxTetherParameters.tresholdStoneLoad then
        print("Player #" .. playerID .. ": has too heavy loaded quarry #" .. highestLoadQuarryID)
        core.writeInteger(highestLoadQuarryID_address + (0x39f4 * playerID), highestLoadQuarryID)
        return 1
    end

    print("Player #" .. playerID .. " is fine with the ox tethers")
    return 0
end

ns.aiRequiresExtraOxtethers_hooked = function(this, playerID)
    return newAiRequiresExtraOxTethers(playerID)
end

ns.enable = function(self, config)
    self.config = config

    -- 0x004cb3a0
    self.hookAddress = core.AOBScan("83 ec 08 55 8b 6c 24 10 56 57 6a 14 55 b9 ? ? ? ? e8 ? ? ? ? 6a 01 6a 04 33 ff 55 b9 ? ? ? ?")
    
    ns.aiRequiresExtraOxtethers_original = core.hookCode(ns.aiRequiresExtraOxtethers_hooked, self.hookAddress, 2, 1, 8)
    ns.oxTetherParameters = config.oxTetherParameters
end

ns.disable = function(self)

end

return ns
