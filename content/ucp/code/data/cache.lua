local namespace = {}

local AOB_CACHE_FILENAME = ".ucp-aob-cache"

local aobs = {}
namespace.AOB = {}
namespace.AOB.loadFromFile = function()
  log(DEBUG, "[cache]: loading cache from file")
  local handle, err = io.open(AOB_CACHE_FILENAME, "r")
  if not handle then
    log(WARNING, "[cache]: startup might be slower, no cache was found")
    return false
  end
  
  local fdata = handle:read("*all")
  handle:close()
  
  aobs = json:decode(fdata)
  
  return true
end

namespace.AOB.retrieve = function(aob)
  local addr = aobs[aob]
  
  if addr ~= nil then
    local checkaddr = core.scanForAOB(aob, addr)
    if checkaddr ~= addr then
      aobs = {} -- invalidate the cache
    else
      return addr
    end
  end
  
  aobs[aob] = core.scanForAOB(aob)
  if aobs[aob] == nil then
    error("AOB could not be found: " .. aob)
  end
  
  return aobs[aob]
end

namespace.AOB.dumpToFile = function()
  log(DEBUG, "[cache]: dumping cache to file")
  local handle, err = io.open(AOB_CACHE_FILENAME, "w")
  if not handle then
    log(WARNING, "[cache]: could not store cache")
    return false
  end  
    
  handle:write(json:encode(aobs))
  handle:close()
  
  return true
end


local ConfigCache = {

  new = function(self, filePath)
  
    return setmetatable({filePath = filePath, data = {}}, {__index = self})
  end,

  fileExists = function(self)
    local handle, err = io.open(self.filePath, "r")
    if not handle then return false end

    handle:close()

    return true
  end,

  generateCache = function(self, extensions)
    for k, ext in pairs(extensions) do
      self.data[ext.name .. "-" .. ext.version] = ext:defaults()
    end
  end,

  retrieve = function(self, ext) 
    local cacheHit = self.data[ext.name .. "-" .. ext.version]
    if cacheHit == nil then
      self.data[ext.name .. "-" .. ext.version] = ext:defaults()
    end
    return cacheHit or self.data[ext.name .. "-" .. ext.version]
  end,

  loadFromFile = function (self)
    log(DEBUG, "[cache]: loading defaults config cache from file")
    local handle, err = io.open(self.filePath, "r")
    if not handle then
      log(WARNING, "[config cache]: startup might be slower, no config cache was found")
      return false
    end
    
    local fdata = handle:read("*all")
    handle:close()
    
    local dc = data.json:decode(fdata)

    self.data = dc
  end,
  
  saveToFile = function(self)
    local handle, err = io.open(self.filePath, 'w')
    handle:write(json:encode(self.data))
    handle:close()
  end,

}

namespace.DefaultConfigCache = ConfigCache:new('.ucp-default-config-cache')

return namespace