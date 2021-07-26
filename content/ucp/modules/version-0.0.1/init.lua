
local bytesToAOBString = function(b)
    local targetString = ""
    for k, v in ipairs(b) do
      if k > 0 then targetString = targetString .. " " end
      targetString = targetString .. string.format("%x", v)
    end
    return targetString
end

local scanForString = function(s)
    local targetBytes = table.pack(string.byte(s, 1, -1))
    local targetString = bytesToAOBString(targetBytes)
    return core.scanForAOB(targetString, 0x00400000, 0x00600000)
end

local computeVersionString = function()
  
  local function dumpTableToDeterministicString(o)
    local res = ""
    local keys = {}
    for k, v in pairs(o) do
      table.insert(keys, k)
    end
    table.sort(keys)
    
    for k, key in pairs(keys) do
      local v = o[key]
      res = res .. key
      if type(v) == "table" then
        res = res .. dumpTableToDeterministicString(v)
      elseif type(v) == "function" then
        error()
      else
        res = res .. string.format("%s", v)
      end
    end
    return res
  end
  
  local mset = {}
  for k, v in pairs(config.modules) do
    if v.active then
      mset[k] = v
    end
  end
  local s = dumpTableToDeterministicString(mset)
  
  -- an indicator that shows the user a digest of the config for easy verification for multiplayer.
  local digest = sha.sha1(s)
  
  
  return digest
end

return {
	enable = function(self, config)
    self.custom_menu_version_space = core.allocate(64)
    local d = table.pack(string.byte("V1.%d", 1, -1))
    table.insert(d, 0)
    core.writeBytes(self.custom_menu_version_space, d)
    
    local vf = scanForString("V1.%d")
    if vf == nil then error() end
    local push_vf = {0x68, table.unpack(utils.itob(vf))}
    if push_vf == nil then error() end
    self.push_vf_address = core.scanForAOB(bytesToAOBString(push_vf))
    if self.push_vf_address == nil then error() end
    local vnumber_address = core.scanForAOB("6A", self.push_vf_address - 20, self.push_vf_address)
    if vnumber_address == nil then error() end
    
    self.menu_version = {1, core.readByte(vnumber_address+1)}
    
    core.writeCode(self.push_vf_address, {0x68, table.unpack(utils.itob(self.custom_menu_version_space))})
    
    local digest = computeVersionString()
    self:setMenuVersion("V1.%d UCP " .. UCP_VERSION .. "(" .. digest:sub(1, 6) .. ")")
    
    registerHookCallback("afterInit", function()
      self.afterInited = true
    end)
    
    self.gameLanguage = core.readInteger(core.scanForAOB("83 c4 20 83 3d ? ? ? ? 04 be 10 00 00 00 ? ? be 11 00 00 00") + 5)
	end,
	
	disable = function(self, config)
	
	end,
  
  ---cr.tex is loaded later 
  getGameLanguage = function(self)
    if self.afterInited then
      local index = 1 + core.readInteger(self.gameLanguage)
      local langs = {"english", "american", "german", "french", "italian", "SPANISH", "polish"}
      return langs[index]
    else
      return nil
    end
  end,

  ---Checks if the .exe registers a custom font. Or uses gdi32.dll to get custom size of a font.
	isNonEnglish = function(self)
    local t1 = scanForString("CreateFontA")
		local t2 = scanForString("GetTextExtentPoint32W")

    return t1 ~= nil or t2 ~= nil
	end,
  
  assertEnglishVersion = function(self)
    if self:isNonEnglish() then error("This version is a non-English version") end
    if self:getGameLanguage() ~= "english" then error("This version is non english") end
    return true
  end,
  
  getMenuVersion = function(self)
    return self.menu_version
  end,
  
  setMenuVersion = function(self, fstring)
    if fstring == nil then error() end
    local d = table.pack(string.byte(fstring, 1, -1))
    table.insert(d, 0) -- null termination
    if #d > 64 then error("too long") end
    core.writeBytes(self.custom_menu_version_space, d)
  end,
}