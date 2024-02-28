
local utils = {}

function utils.__pairs(tbl)

  -- Iterator function takes the table and an index and returns the next index and associated value
  -- or nil to end iteration

  local function stateless_iter(tbl, k)
    local v
    -- Implement your own key,value selection logic in place of next
    k, v = next(tbl, k)
    if nil~=v then return k,v end
  end

  -- Return an iterator function, the table, starting point
  return stateless_iter, tbl, nil
end

function utils.__ipairs(tbl)
  -- Iterator function
  local function stateless_iter(tbl, i)
    -- Implement your own index, value selection logic
    i = i + 1
    local v = tbl[i]
    if nil~=v then return i, v end
  end

  -- return iterator function, table, and starting point
  return stateless_iter, tbl, 0
end

-- function utils.__next(tbl, index)
--   if index == nil then
--     return next(tbl)
--   end
--   return next(tbl, index)
-- end

local function contains(t, obj)
	for k, v in pairs(t) do
		if v == obj then return true end
	end
	
	return false
end

local TableProxy
TableProxy = function(obj)

  if type(obj) ~= "table" then return obj end

	return setmetatable({}, {

		__index = function(self, k)

			local value = obj[k]

			if type(value) == "table" then

				return TableProxy(value)

			end

			return value

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this table is not allowed. Key: %s", k))

		end,

    __pairs = function(self) 
      -- Iterator function takes the table and an index and returns the next index and associated value
      -- or nil to end iteration

      local function stateless_iter(tbl, k)
        local v
        -- Implement your own key,value selection logic in place of next
        k, v = next(obj, k)
        if nil~=v then 
          return k,TableProxy(v)
        end
      end

      -- Return an iterator function, the table, starting point
      return stateless_iter, self, nil
    end,
      

    __ipairs = function(self) 
      -- Iterator function
      local function stateless_iter(tbl, i)
        -- Implement your own index, value selection logic
        i = i + 1
        local v = obj[i]
        if nil~=v then 
          return i, TableProxy(v) 
        end
      end

      -- return iterator function, table, and starting point
      return stateless_iter, self, 0
    end,

    __next = function(self, k)
      local k, v = next(obj, k)
      if nil~=v then 
        return k,TableProxy(v) 
      end
    end,

	})	
end


local ExtensionProxy = function(obj)

  local filteredOutFunctions = {
    "enable",
    "disable",
    "init",
  }
  
	return setmetatable({}, {
	
		__index = function(self, k)
    
      if contains(filteredOutFunctions, k) then
        
        log(WARNING, string.format("Function call not allowed. Function: %s. ", k))
        
        return nil
      
      end
		
			local value = obj[k]
		
			if type(value) == "table" then

				return TableProxy(value)

			elseif type(value) == "function" then

				return function(epSelf, ...)

          -- Force the self to be obj
          local ret = value(obj, ...)
					
          if type(ret) == "table" then

            return TableProxy(ret)
          
          else
            
            return ret
          
          end					

				end

			end
			
			return value

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this extension is not allowed. Key: %s", k))

		end,

	})

end



local PublicProxy = function(obj, publicObjects)

  local publicObjects = publicObjects or {}

  local ep = ExtensionProxy(obj)

	return setmetatable({}, {

		__index = function(self, k)

			if contains(publicObjects, k) then

        return ep[k]

			else

				return nil

			end

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this extension is not allowed. Key: %s", k))

		end,

	})

end

local Deproxy
Deproxy = function(obj)
  if type(obj) ~= "table" then return obj end

  local result = {}
  for k, v in pairs(obj) do
    local newk = k
    local newv = v
    if type(k) == "table" then
      newk = Deproxy(k)
    end
    if type(v) == "table" then
      newv = Deproxy(v)
    end
    result[newk] = newv
  end
  return result
end


return {
  TableProxy = TableProxy,
  ExtensionProxy = ExtensionProxy,
  PublicProxy = PublicProxy,
  Deproxy = Deproxy,
}