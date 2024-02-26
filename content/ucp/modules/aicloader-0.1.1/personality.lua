local FieldTypes = require("fieldtypes")

--[[ Constants ]]--

local INT_MIN = -(2^31)
local INT_MAX = 2^31 - 1
local UNSIGNED_INT_MIN = 0
local UNSIGNED_INT_MAX = 2^32 - 1


--[[ Validation Functions ]]--

local function throwMinMaxError(value, valueType, minValue, maxValue, extendError)
  local stringError = extendError and " " .. extendError or ""
  error(string.format("Received '%s'. Must be %s between %d and %d.%s", value,
      valueType, minValue, maxValue, stringError), 0)
end

local function isInteger(value)
  return type(value) == "number" and math.floor(value) == value
end

local function isIntegerValue(value, minValue, maxValue, extendError, valueType)
  if not isInteger(value) or value < minValue or value > maxValue then
    local valueTypeString = valueType or "an integer"
    throwMinMaxError(value, valueTypeString, minValue, maxValue, extendError)
  end
  return value
end

local function isUnsignedInteger(value, extendError)
  return isIntegerValue(value, UNSIGNED_INT_MIN, UNSIGNED_INT_MAX,
      extendError, "an unsigned integer")
end

local function is32BitInteger(value, extendError)
  return isIntegerValue(value, INT_MIN, INT_MAX, extendError)
end

local function isPositiveInteger(value, extendError)
  return isIntegerValue(value, 0, INT_MAX, extendError, "an positive integer")
end

local function isIntegerBetweenMinusOneAndMaxInt(value, extendError)
  return isIntegerValue(value, -1, INT_MAX, extendError)
end

local function isIntegerBetweenZeroAndTenThousand(value, extendError)
  return isIntegerValue(value, 0, 10000, extendError)
end

local function isIntegerBetweenZeroAndOneHundred(value, extendError)
  return isIntegerValue(value, 0, 100, extendError)
end

local function isIntegerBetweenZeroAndOneHundred(value, extendError)
  return isIntegerValue(value, 0, 100, extendError)
end

local function isIntegerBetweenZeroAndEleven(value, extendError)
  return isIntegerValue(value, 0, 11, extendError)
end

local function isRecruitPropDefaultValue(value)
  return isIntegerBetweenZeroAndOneHundred(value,
      "Values for RecruitProb<State>Default fields must add up to 100.")
end

local function isRecruitPropWeakValue(value)
  return isIntegerBetweenZeroAndOneHundred(value,
      "Values for RecruitProb<State>Weak fields must add up to 100.")
end

local function isRecruitPropStrongValue(value)
  return isIntegerBetweenZeroAndOneHundred(value,
      "Values for RecruitProb<State>Strong fields must add up to 100.")
end


local function isProperFieldValue(fieldEnum, value)
  if FieldTypes[fieldEnum] == nil then
    error(fieldEnum .. " is no valid field enum. This should not happen.", 0)
  end
  local result = FieldTypes[fieldEnum][value]
  if result == nil then
    error(string.format("'%s' is no valid value for '%s'.", value, fieldEnum), 0)
  end
  return result
end

local function isFarmBuildingValue(value)
  return isProperFieldValue("FarmBuildingEnum", value)
end

local function isBlacksmithValue(value)
  return isProperFieldValue("BlacksmithSettingEnum", value)
end

local function isFletcherValue(value)
  return isProperFieldValue("FletcherSettingEnum", value)
end

local function isPoleturnerValue(value)
  return isProperFieldValue("PoleturnerSettingEnum", value)
end

local function isResourceValue(value)
  return isProperFieldValue("ResourceEnum", value)
end

local function isUnitValue(value)
  return isProperFieldValue("UnitEnum", value)
end

local function isHarassingSiegeEngineValue(value)
  return isProperFieldValue("HarassingSiegeEngineEnum", value)
end

local function isSiegeEngineValue(value)
  return isProperFieldValue("SiegeEngineEnum", value)
end

local function isTargetValue(value)
  return isProperFieldValue("TargetingTypeEnum", value)
end


local function isBoolean(value)
    if type(value) == "boolean" then
        return value
    end

    if type(value) == "number" then
        if value ~= 1 and value ~= 0 then
            error("incomprehensible boolean value: " .. value, 0)
        else
            return value
        end
    end

    if type(value) == "string" then
        if value:lower() == "true" then
            value = 1
        elseif value:lower() == "false" then
            value = 0
        elseif value == "1" then
            value = 1
        elseif value == "0" then
            value = 0
        else
            error("incomprehensible boolean value: " .. value, 0)
        end
    end

    return value
end


--[[ Main Objects ]]--

local aiFieldFunction = {
  [0  ]   =   is32BitInteger,
  [1  ]   =   is32BitInteger,
  [2  ]   =   is32BitInteger,
  [3  ]   =   is32BitInteger,
  [4  ]   =   is32BitInteger,
  [5  ]   =   is32BitInteger,
  [6  ]   =   isIntegerBetweenZeroAndTenThousand,
  [7  ]   =   isIntegerBetweenZeroAndTenThousand,
  [8  ]   =   isIntegerBetweenZeroAndTenThousand,
  [9  ]   =   isIntegerBetweenZeroAndEleven,
  [10 ]   =   isIntegerBetweenZeroAndEleven,
  [11 ]   =   is32BitInteger,
  [12 ]   =   isFarmBuildingValue,
  [13 ]   =   isFarmBuildingValue,
  [14 ]   =   isFarmBuildingValue,
  [15 ]   =   isFarmBuildingValue,
  [16 ]   =   isFarmBuildingValue,
  [17 ]   =   isFarmBuildingValue,
  [18 ]   =   isFarmBuildingValue,
  [19 ]   =   isFarmBuildingValue,
  [20 ]   =   isPositiveInteger,
  [21 ]   =   isPositiveInteger,
  [22 ]   =   isPositiveInteger,
  [23 ]   =   isPositiveInteger,
  [24 ]   =   isPositiveInteger,
  [25 ]   =   isPositiveInteger,
  [26 ]   =   isPositiveInteger,
  [27 ]   =   isPositiveInteger,
  [28 ]   =   isPositiveInteger,
  [29 ]   =   isPositiveInteger,
  [30 ]   =   isPositiveInteger,
  [31 ]   =   isPositiveInteger,
  [32 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [33 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [34 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [35 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [36 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [37 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [38 ]   =   isPositiveInteger,
  [39 ]   =   isPositiveInteger,
  [40 ]   =   is32BitInteger,
  [41 ]   =   isPositiveInteger,
  [42 ]   =   isPositiveInteger,
  [43 ]   =   isPositiveInteger,
  [44 ]   =   isPositiveInteger,
  [45 ]   =   isPositiveInteger,
  [46 ]   =   isPositiveInteger,
  [47 ]   =   isPositiveInteger,
  [48 ]   =   isPositiveInteger,
  [49 ]   =   isPositiveInteger,
  [50 ]   =   isBlacksmithValue,
  [51 ]   =   isFletcherValue,
  [52 ]   =   isPoleturnerValue,
  [53 ]   =   isResourceValue,
  [54 ]   =   isResourceValue,
  [55 ]   =   isResourceValue,
  [56 ]   =   isResourceValue,
  [57 ]   =   isResourceValue,
  [58 ]   =   isResourceValue,
  [59 ]   =   isResourceValue,
  [60 ]   =   isResourceValue,
  [61 ]   =   isResourceValue,
  [62 ]   =   isResourceValue,
  [63 ]   =   isResourceValue,
  [64 ]   =   isResourceValue,
  [65 ]   =   isResourceValue,
  [66 ]   =   isResourceValue,
  [67 ]   =   isResourceValue,
  [68 ]   =   isPositiveInteger,
  [69 ]   =   isPositiveInteger,
  [70 ]   =   isIntegerBetweenMinusOneAndMaxInt,
  [71 ]   =   is32BitInteger,
  [72 ]   =   is32BitInteger,
  [73 ]   =   is32BitInteger,
  [74 ]   =   isRecruitPropDefaultValue,
  [75 ]   =   isRecruitPropWeakValue,
  [76 ]   =   isRecruitPropStrongValue,
  [77 ]   =   isRecruitPropDefaultValue,
  [78 ]   =   isRecruitPropWeakValue,
  [79 ]   =   isRecruitPropStrongValue,
  [80 ]   =   isRecruitPropDefaultValue,
  [81 ]   =   isRecruitPropWeakValue,
  [82 ]   =   isRecruitPropStrongValue,
  [83 ]   =   isPositiveInteger,
  [84 ]   =   isUnitValue,
  [85 ]   =   isPositiveInteger,
  [86 ]   =   isUnitValue,
  [87 ]   =   isPositiveInteger,
  [88 ]   =   isUnitValue,
  [89 ]   =   isPositiveInteger,
  [90 ]   =   isPositiveInteger,
  [91 ]   =   isPositiveInteger,
  [92 ]   =   isPositiveInteger,
  [93 ]   =   isPositiveInteger,
  [94 ]   =   isBoolean,
  [95 ]   =   isPositiveInteger,
  [96 ]   =   isPositiveInteger,
  [97 ]   =   isUnitValue,
  [98 ]   =   isUnitValue,
  [99 ]   =   isUnitValue,
  [100]   =   isUnitValue,
  [101]   =   isUnitValue,
  [102]   =   isUnitValue,
  [103]   =   isUnitValue,
  [104]   =   isUnitValue,
  [105]   =   isPositiveInteger,
  [106]   =   isPositiveInteger,
  [107]   =   isUnitValue,
  [108]   =   isUnitValue,
  [109]   =   isUnitValue,
  [110]   =   isUnitValue,
  [111]   =   isUnitValue,
  [112]   =   isUnitValue,
  [113]   =   isUnitValue,
  [114]   =   isUnitValue,
  [115]   =   isHarassingSiegeEngineValue,
  [116]   =   isHarassingSiegeEngineValue,
  [117]   =   isHarassingSiegeEngineValue,
  [118]   =   isHarassingSiegeEngineValue,
  [119]   =   isHarassingSiegeEngineValue,
  [120]   =   isHarassingSiegeEngineValue,
  [121]   =   isHarassingSiegeEngineValue,
  [122]   =   isHarassingSiegeEngineValue,
  [123]   =   isPositiveInteger,
  [124]   =   isPositiveInteger,
  [125]   =   isPositiveInteger,
  [126]   =   isPositiveInteger,
  [127]   =   isPositiveInteger,
  [128]   =   isPositiveInteger,
  [129]   =   is32BitInteger,
  [130]   =   isPositiveInteger,
  [131]   =   isPositiveInteger,
  [132]   =   is32BitInteger,
  [133]   =   isSiegeEngineValue,
  [134]   =   isSiegeEngineValue,
  [135]   =   isSiegeEngineValue,
  [136]   =   isSiegeEngineValue,
  [137]   =   isSiegeEngineValue,
  [138]   =   isSiegeEngineValue,
  [139]   =   isSiegeEngineValue,
  [140]   =   isSiegeEngineValue,
  [141]   =   isIntegerBetweenMinusOneAndMaxInt,
  [142]   =   is32BitInteger,
  [143]   =   isPositiveInteger,
  [144]   =   isUnitValue,
  [145]   =   isPositiveInteger,
  [146]   =   isUnitValue,
  [147]   =   isPositiveInteger,
  [148]   =   isPositiveInteger,
  [149]   =   isPositiveInteger,
  [150]   =   isPositiveInteger,
  [151]   =   isUnitValue,
  [152]   =   isPositiveInteger,
  [153]   =   isPositiveInteger,
  [154]   =   isUnitValue,
  [155]   =   isPositiveInteger,
  [156]   =   isPositiveInteger,
  [157]   =   isUnitValue,
  [158]   =   isPositiveInteger,
  [159]   =   isUnitValue,
  [160]   =   isPositiveInteger,
  [161]   =   isPositiveInteger,
  [162]   =   isUnitValue,
  [163]   =   isUnitValue,
  [164]   =   isUnitValue,
  [165]   =   isUnitValue,
  [166]   =   isPositiveInteger,
  [167]   =   isPositiveInteger,
  [168]   =   isTargetValue,
}

local aiFieldIndex = {
  WallDecoration                  = 0  ,
  Unknown000                      = 0  ,
  Unknown001                      = 1  ,
  Unknown002                      = 2  ,
  Unknown003                      = 3  ,
  Unknown004                      = 4  ,
  Unknown005                      = 5  ,
  CriticalPopularity              = 6  ,
  LowestPopularity                = 7  ,
  HighestPopularity               = 8  ,
  TaxesMin                        = 9  ,
  TaxesMax                        = 10 ,
  Unknown011                      = 11 ,
  Farm1                           = 12 ,
  Farm2                           = 13 ,
  Farm3                           = 14 ,
  Farm4                           = 15 ,
  Farm5                           = 16 ,
  Farm6                           = 17 ,
  Farm7                           = 18 ,
  Farm8                           = 19 ,
  PopulationPerFarm               = 20 ,
  PopulationPerWoodcutter         = 21 ,
  PopulationPerQuarry             = 22 ,
  PopulationPerIronmine           = 23 ,
  PopulationPerPitchrig           = 24 ,
  MaxQuarries                     = 25 ,
  MaxIronmines                    = 26 ,
  MaxWoodcutters                  = 27 ,
  MaxPitchrigs                    = 28 ,
  MaxFarms                        = 29 ,
  BuildInterval                   = 30 ,
  ResourceRebuildDelay            = 31 ,
  MaxFood                         = 32 ,
  MinimumApples                   = 33 ,
  MinimumCheese                   = 34 ,
  MinimumBread                    = 35 ,
  MinimumWheat                    = 36 ,
  MinimumHop                      = 37 ,
  TradeAmountFood                 = 38 ,
  TradeAmountEquipment            = 39 ,
  AIRequestDelay                  = 40 ,
  Unknown040                      = 40 ,
  MinimumGoodsRequiredAfterTrade  = 41 ,
  DoubleRationsFoodThreshold      = 42 ,
  MaxWood                         = 43 ,
  MaxStone                        = 44 ,
  MaxResourceOther                = 45 ,
  MaxEquipment                    = 46 ,
  MaxBeer                         = 47 ,
  MaxResourceVariance             = 48 ,
  RecruitGoldThreshold            = 49 ,
  BlacksmithSetting               = 50 ,
  FletcherSetting                 = 51 ,
  PoleturnerSetting               = 52 ,
  SellResource01                  = 53 ,
  SellResource02                  = 54 ,
  SellResource03                  = 55 ,
  SellResource04                  = 56 ,
  SellResource05                  = 57 ,
  SellResource06                  = 58 ,
  SellResource07                  = 59 ,
  SellResource08                  = 60 ,
  SellResource09                  = 61 ,
  SellResource10                  = 62 ,
  SellResource11                  = 63 ,
  SellResource12                  = 64 ,
  SellResource13                  = 65 ,
  SellResource14                  = 66 ,
  SellResource15                  = 67 ,
  DefWallPatrolRallyTime          = 68 ,
  DefWallPatrolGroups             = 69 ,
  DefSiegeEngineGoldThreshold     = 70 ,
  DefSiegeEngineBuildDelay        = 71 ,
  Unknown072                      = 72 ,
  Unknown073                      = 73 ,
  RecruitProbDefDefault           = 74 ,
  RecruitProbDefWeak              = 75 ,
  RecruitProbDefStrong            = 76 ,
  RecruitProbRaidDefault          = 77 ,
  RecruitProbRaidWeak             = 78 ,
  RecruitProbRaidStrong           = 79 ,
  RecruitProbAttackDefault        = 80 ,
  RecruitProbAttackWeak           = 81 ,
  RecruitProbAttackStrong         = 82 ,
  SortieUnitRangedMin             = 83 ,
  SortieUnitRanged                = 84 ,
  SortieUnitMeleeMin              = 85 ,
  SortieUnitMelee                 = 86 ,
  DefDiggingUnitMax               = 87 ,
  DefDiggingUnit                  = 88 ,
  RecruitInterval                 = 89 ,
  RecruitIntervalWeak             = 90 ,
  RecruitIntervalStrong           = 91 ,
  DefTotal                        = 92 ,
  OuterPatrolGroupsCount          = 93 ,
  OuterPatrolGroupsMove           = 94 ,
  OuterPatrolRallyDelay           = 95 ,
  DefWalls                        = 96 ,
  DefUnit1                        = 97 ,
  DefUnit2                        = 98 ,
  DefUnit3                        = 99 ,
  DefUnit4                        = 100,
  DefUnit5                        = 101,
  DefUnit6                        = 102,
  DefUnit7                        = 103,
  DefUnit8                        = 104,
  RaidUnitsBase                   = 105,
  RaidUnitsRandom                 = 106,
  RaidUnit1                       = 107,
  RaidUnit2                       = 108,
  RaidUnit3                       = 109,
  RaidUnit4                       = 110,
  RaidUnit5                       = 111,
  RaidUnit6                       = 112,
  RaidUnit7                       = 113,
  RaidUnit8                       = 114,
  HarassingSiegeEngine1           = 115,
  HarassingSiegeEngine2           = 116,
  HarassingSiegeEngine3           = 117,
  HarassingSiegeEngine4           = 118,
  HarassingSiegeEngine5           = 119,
  HarassingSiegeEngine6           = 120,
  HarassingSiegeEngine7           = 121,
  HarassingSiegeEngine8           = 122,
  HarassingSiegeEnginesMax        = 123,
  RaidRetargetDelay               = 124,
  Unknown124                      = 124,
  AttForceBase                    = 125,
  AttForceRandom                  = 126,
  AttForceSupportAllyThreshold    = 127,
  AttForceRallyPercentage         = 128,
  Unknown129                      = 129,
  AttAssaultDelay                 = 130,
  Unknown130                      = 130,
  AttUnitPatrolRecommandDelay     = 131,
  Unknown132                      = 132,
  SiegeEngine1                    = 133,
  SiegeEngine2                    = 134,
  SiegeEngine3                    = 135,
  SiegeEngine4                    = 136,
  SiegeEngine5                    = 137,
  SiegeEngine6                    = 138,
  SiegeEngine7                    = 139,
  SiegeEngine8                    = 140,
  CowThrowInterval                = 141,
  Unknown142                      = 142,
  AttMaxEngineers                 = 143,
  AttDiggingUnit                  = 144,
  AttDiggingUnitMax               = 145,
  AttUnitVanguard                 = 146,
  AttUnit2                        = 146,
  AttUnitVanguardMax              = 147,
  AttUnit2Max                     = 147,
  AttMaxAssassins                 = 148,
  AttMaxLaddermen                 = 149,
  AttMaxTunnelers                 = 150,
  AttUnitPatrol                   = 151,
  AttUnitPatrolMax                = 152,
  AttUnitPatrolGroupsCount        = 153,
  AttUnitBackup                   = 154,
  AttUnitBackupMax                = 155,
  AttUnitBackupGroupsCount        = 156,
  AttUnitEngage                   = 157,
  AttUnitEngageMax                = 158,
  AttUnitSiegeDef                 = 159,
  AttUnitSiegeDefMax              = 160,
  AttUnitSiegeDefGroupsCount      = 161,
  AttUnitMain1                    = 162,
  AttUnitMain2                    = 163,
  AttUnitMain3                    = 164,
  AttUnitMain4                    = 165,
  AttMaxDefault                   = 166,
  AttMainGroupsCount              = 167,
  TargetChoice                    = 168,
}

local function getAndValidateAicValue(aicField, aicValue)
  local valueIndex = aiFieldIndex[aicField]
  if valueIndex == nil then
    error("Unknown AIC field: " .. aicField, 0)
  end
  local valueFunction = aiFieldFunction[valueIndex]
  if valueFunction == nil then
    error("For some reason AIC index has no test function: " .. valueIndex, 0)
  end
  return valueIndex, valueFunction(aicValue)
end

return getAndValidateAicValue