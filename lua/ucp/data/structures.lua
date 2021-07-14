local namespace = {}

namespace.GAME_VARIABLES = {
  gameSpeed = {
    fieldType = "int",
    address = 0x01fe7dd8
  }
}

namespace.GlobalVariableSet = {

  new = function(self, variables)
      local o = {
	      _variables = variables,
      }
      setmetatable(o, self)
      return o
    end,

  variables = function(self)
	  return self._variables
	end,
  
  get = function(self, key)
      assert(self._variables)
      assert(self._variables[key])
      def = self._variables[key]
      if def["fieldType"] == "int" then
        return core.readInteger(def["address"])
      elseif def["fieldType"] == "short" then
        return core.readSmallInteger(def["address"])
      elseif def["fieldType"] == "byte" then
        return core.readByte(def["address"])
      end
      return 0
    end,

  set = function(self, key, v)
  		assert(self._variables)
		assert(self._variables[key])
		def = self._variables[key]
		if def["fieldType"] == "int" then
			core.writeInteger(def["address"], v)
		elseif def["fieldType"] == "short" then
			core.writeSmallInteger(def["address"], v)
		elseif def["fieldType"] == "byte" then
			core.writeByte(def["address"], v)
		end
    end,

  __index = function(self, key)
      return getmetatable(self)[key] or self:get(key)
    end,

  __newindex = function(self, i, v)
      self:set(i, v)
    end,
}

namespace.GameVariables = namespace.GlobalVariableSet:new(namespace.GAME_VARIABLES)

namespace.STRUCTURE_DEFINITIONS = {
  PlayerData = {
    
  }
}

namespace.Structure = {

  new = function(self, struct_type, address)
      local o = {
	    _struct_type = struct_type,
        _address = address
      }
      setmetatable(o, self)
      return o
    end,

  struct_type = function(self)
	  return self._struct_type
	end,

  address = function(self)
      return self._address
    end,
  
  offset = function(self, key)
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type])
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type][key])
		def = namespace.STRUCTURE_DEFINITIONS[self._struct_type][key]
    return def["offset"]
  end,

  location = function(self, key)
  	assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type])
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type][key])
		def = namespace.STRUCTURE_DEFINITIONS[self._struct_type][key]
    return self._address + def["offset"]
  end,

  get = function(self, key)
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type])
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type][key])
		def = namespace.STRUCTURE_DEFINITIONS[self._struct_type][key]
		if def["fieldType"] == "int" then
			return core.readInteger(self._address+def["offset"])
		elseif def["fieldType"] == "short" then
			return core.readSmallInteger(self._address+def["offset"])
		elseif def["fieldType"] == "byte" then
			return core.readByte(self._address+def["offset"])
		end
		return 0
    end,

  set = function(self, key, v)
  		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type])
		assert(namespace.STRUCTURE_DEFINITIONS[self._struct_type][key])
		def = namespace.STRUCTURE_DEFINITIONS[self._struct_type][key]
		if def["fieldType"] == "int" then
			core.writeInteger(self._address+def["offset"], v)
		elseif def["fieldType"] == "short" then
			core.writeSmallInteger(self._address+def["offset"], v)
		elseif def["fieldType"] == "byte" then
			core.writeByte(self._address+def["offset"], v)
		end
    end,

  __index = function(self, key)
      return getmetatable(self)[key] or self:get(key)
    end,

  __newindex = function(self, i, v)
      self:set(i, v)
    end,
	
}

namespace.PlayerData = {
	new = function(self, address)
		return namespace.Structure:new("PlayerData", address)
	end

}

local PlayerDataArray_address = 0x0115bdf8
local PlayerData_size = 0x39f4

namespace.PlayerDataArray = {}
for i=0, 8 do
 namespace.PlayerDataArray[i]=namespace.PlayerData:new(PlayerDataArray_address+(PlayerData_size*i))
end

return namespace