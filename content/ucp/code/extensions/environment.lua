
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

                local value = assert(package.loadlib(full_path, "luaopen_" .. sanitized_file_name)())
                LOADED[sanitized_file] = value
                return value
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

        local code, message = load(data, full_path:sub(-25), 't', env)
        if not code then
            error(message)
        end

        local status, value = pcall(code)

        if not status then
            error(value)
        end

        LOADED[sanitized_file] = value

        return value
    end
end

---Prefixes the module name to a print when the module calls 'print'
---@param moduleName string the name of the module
---@see print
---@private
local function prefixedPrintFunction(moduleName)
    return function(...)
        print("[" .. moduleName .. "]: ", ...)
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