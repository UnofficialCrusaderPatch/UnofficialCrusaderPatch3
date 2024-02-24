
local function contains(t, obj)
	for k, v in pairs(t) do
		if v == obj then return true end
	end
	
	return false
end


local TableProxy = function(obj)

	return setmetatable({}, {

		__index = function(self, k)

			local value = obj[k]

			if type(value) == "table" then

				return TableProxy(obj)

			end

			return value

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this table is not allowed. Key: %s", k))

		end,

	})	
end


local PublicProxy = function(obj, publicObjects)

  local publicObjects = publicObjects or {}

	return setmetatable({}, {

		__index = function(self, k)

			if contains(publicObjects, k) then

				local value = obj[k]
				
				if type(value) == "table" then

					return TableProxy(value)

				elseif type(value) == "function" then

					return function(...)

						-- Force the self to be obj

						return value(obj, select(2, ...))

					end

				end
				
				return value

			else

				return nil

			end

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this object is not allowed. Key: %s", k))

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

				return function(...)

					-- Force the self to be obj
					return TableProxy(value(obj, select(2, ...)))

				end

			end
			
			return value

		end,
		
		__newindex = function(self, k, v)

			error(string.format("Setting a value on this extension is not allowed. Key: %s", k))

		end,

	})

end

return {
  TableProxy = TableProxy,
  ExtensionProxy = ExtensionProxy,
  PublicProxy = PublicProxy,
}