local ns = {}

-- playerID, buildingType, includeBool
ns.countBuildingsForPlayer = core.exposeCode(0x0040a9b0, 4, 1) -- ECX: 0xf98520

-- playerID, buildingType
ns.findFirstBuildingIDForPlayerAndType = core.exposeCode(0x0040aad0, 3, 1) -- ECX: 0x00f98520

-- playerID, buildingType, previous buildingID
ns.findNextBuildingForPlayerAndType = core.exposeCode(0x0040ab30, 4, 1) -- ECX: 0x00f98520


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
    local oxTetherID = ns.findFirstBuildingIDForPlayerAndType(0x00f98520, playerID, 0x04)

    if oxTetherID == 0 then
        return 0
    end

    local count = 0

    while oxTetherID ~= 0 do

        local oxtetherLinkedQuarryID = core.readSmallInteger(0x00f98804 + (0x32c * oxTetherID))
        if oxtetherLinkedQuarryID == quarryID then
            count = count + 1
        end

        oxTetherID = ns.findNextBuildingForPlayerAndType(0x00f98520, playerID, 0x04, oxTetherID)
    end

    return count
end

local function newAiRequiresExtraOxTethers(playerID)
    local quarryCount = ns.countBuildingsForPlayer(0xf98520, playerID, 0x14, 0)
    local oxtetherCount = ns.countBuildingsForPlayer(0xf98520, playerID, 0x4, 0)

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
    core.writeInteger(0x0115e8cc + (0x39f4 * playerID), 0)

    local lowestOxTetherCountQuarryID = 0
    local lowestOxTetherCount = ns.oxTetherParameters.maxOxTethers

    local highestLoadQuarryID = 0
    local highestLoad = 0

    local quarryID = ns.findFirstBuildingIDForPlayerAndType(0x00f98520, playerID, 0x14)

    if quarryID == 0 then
        return 0
    end

    while quarryID ~= 0 do

        local quarryStockPileID = core.readSmallInteger(0x00f986c6 + (0x32c * quarryID))
        local stoneInStock = core.readInteger(0x00f98664 + (0x32c * quarryStockPileID))

        local linkedTetherCount = countLinkedOxTethers(playerID, quarryID)

        -- Although this part is not required anymore for counting tethers, it is still required to clean up tether linking. Until we know what that is used for throughout the game, let's keep it.
        local quarryLinkedOxtethersArray = 0x00f987fe + (0x32c * quarryID)
        for i = 0, 2, 1 do
            local oxTetherID = core.readSmallInteger(quarryLinkedOxtethersArray + (2 * i))
            if oxTetherID ~= 0 then
                local otBuildingType = core.readSmallInteger(0x00f98606 + (0x32c * oxTetherID))
                local oxtetherLinkedQuarryID = core.readSmallInteger(0x00f98804 + (0x32c * oxTetherID))

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
            core.writeInteger(0x0115e8cc + (0x39f4 * playerID), quarryID)
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

        quarryID = ns.findNextBuildingForPlayerAndType(0x00f98520, playerID, 0x14, quarryID)
    end

    print("Player #" .. playerID .. " heaviest loaded quarry is #" .. highestLoadQuarryID .. " (" .. highestLoad .. ")")

    if highestLoad > ns.oxTetherParameters.tresholdStoneLoad then
        print("Player #" .. playerID .. ": has too heavy loaded quarry #" .. highestLoadQuarryID)
        core.writeInteger(0x0115e8cc + (0x39f4 * playerID), highestLoadQuarryID)
        return 1
    end

    print("Player #" .. playerID .. " is fine with the ox tethers")
    return 0
end

ns.aiRequiresExtraOxtethers_hooked = function(this, playerID)
    return newAiRequiresExtraOxTethers(playerID)
end

ns.enable = function(self, config)
    ns.aiRequiresExtraOxtethers_original = core.hookCode(ns.aiRequiresExtraOxtethers_hooked, 0x004cb3a0, 2, 1, 8)
    ns.oxTetherParameters = config.oxTetherParameters
end

ns.disable = function(self)

end

return ns
