local namespace = {}

local AOB_CACHE_FILENAME = "ucp/.ucp-aob-cache"

local aobs = {}
namespace.AOB = {}
namespace.AOB.loadFromFile = function()
  log(DEBUG, "[data/cache]: loading cache from file")
  local handle, err = io.open(AOB_CACHE_FILENAME, "r")
  if not handle then
    log(WARNING, "[data/cache]: startup might be slower, no cache was found")
    return false
  end
  
  local fdata = handle:read("*all")
  handle:close()
  
  aobs = yaml.parse(fdata)
  
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
    error(debug.traceback("[data/cache]: AOB could not be found: " .. aob))
  end
  
  return aobs[aob]
end

-- Unique code bindings must be rechecked even when their cached bytes still
-- match. Only publish a verified result into the existing shared AOB cache.
namespace.AOB.retrieveUnique = function(aob, name)
  local label = name or aob
  if type(ucp.internal.scanForAOBInMainModule) ~= "function" then
    error("Unique AOB resolution requires the RPS main-module scanner: " .. label)
  end
  local first, second = ucp.internal.scanForAOBInMainModule(aob)
  if second and second ~= 0 then
    error(string.format("Ambiguous executable AOB for %s: 0x%X and 0x%X", label, first, second))
  end
  if not first or first == 0 then
    error("Executable AOB not found for " .. label .. ": " .. aob)
  end
  aobs[aob] = first
  return first
end

namespace.AOB.dumpToFile = function()
  log(DEBUG, "[data/cache]: dumping cache to file")
  local handle, err = io.open(AOB_CACHE_FILENAME, "w")
  if not handle then
    log(WARNING, "[data/cache]: could not store cache")
    return false
  end  
    
  handle:write(yaml.dump(aobs))
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
    log(DEBUG, "[data/cache]: loading defaults config cache from file")
    local handle, err = io.open(self.filePath, "r")
    if not handle then
      log(WARNING, "[data/cache]: startup might be slower, no config cache was found")
      return false
    end
    
    local fdata = handle:read("*all")
    handle:close()
    
    local dc = yaml.parse(fdata)

    self.data = dc
  end,
  
  saveToFile = function(self)
    local handle, err = io.open(self.filePath, 'w')
    handle:write(yaml.dump(self.data))
    handle:close()
  end,

}

namespace.DefaultConfigCache = ConfigCache:new('ucp/.ucp-default-config-cache')

return namespace
