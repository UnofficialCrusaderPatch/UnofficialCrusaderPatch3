
---This function generates a function that can be used by a module to require its own files.
---The base directory of the module is automatically prepended to the file path
---
---@private
---
---@param path string path to the base folder of a module
---@param env table when the module requires other modules, this is the environment to evaluate these in
---@return function
local function restrictedRequireFunction(path, env, allow_binary)

    local LOADED = {}

    return function(file)

        if type(file) ~= "string" then
            error("'file' parameter is not a string")
        end
        local sanitized_file = file:match("([a-zA-Z0-9_\\./ -]+)$") -- match the last filename, ignore directories
        if not sanitized_file then
            error("illegal 'file': " .. file)
        end
        if sanitized_file:sub(1) == "/" then
            error("illegal 'file': " .. file)
        end
        if sanitized_file:match("[.]+/") then
            error("illegal 'file': " .. file)
        end

        if LOADED[sanitized_file] ~= nil then
            return LOADED[sanitized_file]
        end

        log(DEBUG, "requiring file: " .. sanitized_file)

        local has_lua_extension = sanitized_file:match("([.]lua)$")
        local has_dll_extension = sanitized_file:match("([.]dll)$")

        if has_dll_extension then
            local full_path = path .. "/" .. sanitized_file
            if allow_binary then
                local sanitized_file_name = sanitized_file
                if has_lua_extension or has_dll_extension then
                    sanitized_file_name = sanitized_file:sub(1, -5) -- remove the extension part
                else

                end
                -- TODO: This will run in a global env, test that.
                local handle, err = core.openLibraryHandle(full_path)
                if handle == nil then error(err) end
                return handle:require(sanitized_file_name)
            end
            error("binary files are not allowed: " .. full_path)
        elseif has_lua_extension then
            error("deprecated: " .. sanitized_file)
        else

        end

        local full_path = path .. "/" .. sanitized_file:gsub("[.]", "/") .. ".lua"
		local handle, err = io.open(full_path)
        local err2
		if not handle then

            full_path = path .. "/" .. sanitized_file:gsub("[.]", "/") .. "/init.lua"
            handle, err2 = io.open(full_path)
            if not handle then
                error(err .. "\n" .. err2)
            end
		end

		local data = handle:read("*all")

        local code, message = load(data, "@" .. full_path, 't', env)
        if not code then
            error(message)
        end

        local status, value = pcall(code)

        if not status then
            error(debug.traceback(value))
        end

        LOADED[sanitized_file] = value

        return value
    end
end

local SPECIAL_DIRECTORIES = {
    --- Meant to resolve to: C:/Users/Users/Documents/Stronghold Crusader/
    ["$DATA"] = true,
    ["./"] = true,
}

---This function generated a function that is meant to prevent modules from escaping the UCP directory
---
---@private
---
---@param path string path to the file to be opened
---@param specialDirectories table table of directories that should receive special treatment
---@return table
local function ucpRestrictedOpenFileFunction(path, specialDirectories)
    local specialDirectories = specialDirectories or SPECIAL_DIRECTORIES

    return function(filename, mode)

        filename = filename.gsub("\\+", "/")

        -- Disallow parent paths
        filename = filename.gsub("[.][.]/", "")

        if filename.find(":") then
            error("Colons are not allowed in a path: " .. filename)
        end

        if filename.find("/") == 1 then
            error("A path cannot start with a . " .. filename)
        end

        if filename:find("./") == 1 then
            if specialDirectories['./'] then
                filename = path .. "/" .. filename:sub(3)
            else
                error("Paths relative to the extension have been disabled: " .. filename)
            end
        elseif filename:find("$DATA") == 1 then
            if specialDirectories['$DATA'] then
                filename = path .. "/" .. filename:sub(3)
            else
                error("Access to the data path has been disabled: " .. filename)
            end            
        elseif filename:find("ucp/") == nil then
            error("Access to a file must be relative to the ucp directory: " .. filename)
        end

        return io.open(filename, mode)
    end
end

---Prefixes the module name to a print when the module calls 'print'
---@param moduleName string the name of the module
---@see print
---@private
local function prefixedPrintFunction(moduleName)
    return function(msg, ...)
      local logLevel = LOG_LEVELS.INFO

      ucp.internal.log(logLevel, "[" .. moduleName .. "]: " .. tostring(msg), ...)
    end
end

---Prefixes the module name to a print when the module calls 'print'
---@param moduleName string the name of the module
---@see print
---@private
local function prefixedLogFunction(moduleName)

    local log = log
    

    local cv = tonumber(os.getenv("UCP_CONSOLE_VERBOSITY"))
    local c = tonumber(os.getenv("UCP_VERBOSITY"))

    if (cv ~= nil and cv > 0) or (c ~= nil and c > 0) then
       return function(logLevel, msg, ...)
        local info = debug.getinfo(2)

        ucp.internal.log(logLevel, "[" .. tostring(info.source) .. ":" .. tostring(info.currentline) .. "]: (" .. tostring(info.name) .. "): " .. tostring(msg), ...)
      end
    else
      return function(logLevel, msg, ...)
        ucp.internal.log(logLevel, "[" .. moduleName .. "]: " .. tostring(msg), ...)
      end
    end
    
end

---This function creates the module environment in which module code is evaluated. It provides the environment with custom require and print functions
---@private
local function createRestrictedEnvironment(name, path, forbidsGlobalAssignment, permittedFunctions, allowBinary)

    local env = {}

    if permittedFunctions then
        for k, v in pairs(permittedFunctions) do
            env[k] = v
        end
    end

    env.log = prefixedLogFunction(name)
    env.print = prefixedPrintFunction(name)
    env.require = restrictedRequireFunction(path, env, allowBinary)

    if forbidsGlobalAssignment then
        env = setmetatable(env, {
            __newindex = function(self, k, v)
                error("global assignment not permitted in module: '" .. name .. "', variable: '" .. k .. "'")
            end
        })
    end

    return env
end

return {
    createRestrictedEnvironment = createRestrictedEnvironment
}