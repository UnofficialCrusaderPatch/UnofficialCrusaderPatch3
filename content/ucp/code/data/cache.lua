

local namespace = {}


local aobs = {}
namespace.AOB = {}
namespace.AOB.loadFromFile = function()
  log(DEBUG, "[cache]: loading cache from file")
  local handle, err = io.open(".ucp-cache", "r")
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
  local handle, err = io.open(".ucp-cache", "w")
  if not handle then
    log(WARNING, "[cache]: could not store cache")
    return false
  end  
    
  handle:write(json:encode(aobs))
  handle:close()
  
  return true
end


return namespace