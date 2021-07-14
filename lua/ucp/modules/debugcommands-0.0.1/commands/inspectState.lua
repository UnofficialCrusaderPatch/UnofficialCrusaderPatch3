
--[[

PTR_UpdateUnitFunctions_base = 0x00b4df60

ENABLED_UNITS = {
  Fletcher = true
}

PLAYER_FILTER = {
                  [1] = true
                }
                
UNIT_TYPES = {
  -- Woodcutter = 3,
  -- Fletcher = 4,
  -- Hunter = 6,
  -- QuarryMason = 7,
  -- QuarryWorker = 8,
  -- PitchMan = 0xa,
  -- WheatFarmer = 0xb,
  -- HopsFarmer = 0xc,
  -- AppleFarmer = 0xd,
  -- DairyFarmer = 0xe,
  -- Miller = 0xf,
  -- Baker = 0x10,
  -- Brewer = 0x11,
  -- PoleTurner = 0x12,
  -- Smith = 0x13,
  -- Armorer = 0x14,
  -- Tanner = 0x15,
  -- Priest = 0x21,
  -- Healer = 0x22,
  -- InnKeeper = 0x24
  Archer = 0x16,
  Crossbowman = 0x17,
  Spearman = 0x18,
  Pikeman = 0x19,
  Maceman = 0x1a,
  Swordsman = 0x1b,
  Knight = 0x1c,
  Ladderman = 0x1d,
  Engineer = 0x1e,
  Catapult = 0x27,
  SiegeTower = 0x3a,
  BatteringRam = 0x3b,
  Shield = 0x3c,
  
  ArabianArcher = 0x46,
  Slave = 0x47,
  Slinger = 0x48,
  Assassin = 0x49,
  HorseArcher = 0x4a,
  ArabianSwordsman = 0x4b,
  Firethrower = 0x4c,
  FireBallista = 0x4d,
}

function lookupUnitTypeNameForUnitTypeInt(i)
  for k, v in pairs(UNIT_TYPES) do
    if v == i then
      return k
    end
  end
end

UNIT_TYPE_HOOKSIZES = {
  Woodcutter = 10,
  Fletcher = 5,
  Hunter = 10,
  QuarryMason = 10,
  QuarryWorker = 9,
  PitchMan = 10,
  WheatFarmer = 10,
  HopsFarmer = 10,
  AppleFarmer = 10,
  DairyFarmer = 10,
  Miller = 10,
  Baker = 10,
  Brewer = 10,
  PoleTurner = 5,
  Smith = 9,
  Armorer = 10,
  Tanner = 5,
  Priest = 5,
  Healer = 5,
  InnKeeper = 9,
  
  Archer = 7,
  Crossbowman = 7,
  Spearman = 6,
  Pikeman = 7,
  Maceman = 7,
  Swordsman = 7,
  Knight = 7,
  Ladderman = 6,
  Engineer = 7,
  Catapult = 10,
  SiegeTower = 6,
  BatteringRam = 6,
  Shield = 9,
  
  ArabianArcher = 7,
  Slave = 6,
  Slinger = 7,
  Assassin = 6,
  HorseArcher = 7,
  ArabianSwordsman = 7,
  Firethrower = 7,
  FireBallista = 6,
}

DAT_MatchTime = 0x01fe7da8
DAT_CurrentUnitSlotID = 0x00ee0fc8
TRACKED_UNIT_IDS = {} -- we track a unit ID for every unit type
TRACKED_UNIT_STATES = {} -- we track a unit state for every unit ID
TRACKED_UNIT_STATE_TIME = {}

for k,v in pairs(UNIT_TYPES) do
  _G["Update" .. k .. "_hook"] = function() 
      unitID = readInteger(DAT_CurrentUnitSlotID)
      
      if inspectState_inspector ~= nil then
        if inspectState_inspector.unitID == unitID then
          -- call original game code
          ret = _G["Update" .. k]()
          
          inspectState_inspector:tick()

          return ret
        else
          return _G["Update" .. k]()
        end
      else
        return _G["Update" .. k]()
      end
    end
  
  hookCode("Update" .. k .. "_hook", "Update" .. k, readInteger(PTR_UpdateUnitFunctions_base + (v * 4)), 0, 0, UNIT_TYPE_HOOKSIZES[k])
end



UnitStateInspector = {
  new = function(self, unitID) 
      local data = {
        unitID = unitID,
        state = nil,
        stateBasedSpeed = nil,
        unitHandle = Structure:new("Unit", 0x0138854c + (0x490 * unitID))
      }
      setmetatable(data, self)
      self.__index = self
      
      if lookupUnitTypeNameForUnitTypeInt(data.unitHandle.unitType) == nil then
        displayChatText("inspectState: unsupported unit type: " .. data.unitHandle.unitType)
        return nil
      end
      
      return data
    end,
    
  getState = function(self)
      return self.unitHandle.state
    end,
    
  getStateBasedSpeed = function(self)
      return self.unitHandle.field_0x2be
    end,
    
  tick = function(self)
      if self:getState() ~= self.state or self:getStateBasedSpeed() ~= self.stateBasedSpeed then
        self.state = self:getState()
        self.stateBasedSpeed = self:getStateBasedSpeed()
        displayChatText("inspectState: " .. " state: " .. self.state .. " speed: " .. self.stateBasedSpeed)
      end
    end
}

inspectState_inspector = nil


function onInspectStateCallback(command)
  unitID = command:match("^/inspectState (-*[0-9]+)$")
  if unitID == nil then
    displayChatText("invalid command: " .. command .. " usage: ", "/inspectState [unitID]")
  else 
    unitID = unitID + 0
    if unitID == -1 or unitID == 0 then
      displayChatText("inspectState: stopping state inspection")
      inspectState_inspector = nil
    elseif unitID > 0 then
      inspectState_inspector = UnitStateInspector:new(unitID)
    else
      displayChatText("invalid command: " .. command .. " usage: ", "/inspectState [unitID]")
    end
  end
  
end

registerCommand("inspectState", onInspectStateCallback)



--]]
