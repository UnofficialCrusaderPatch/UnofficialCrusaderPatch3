
---This function generates a function that can be used by a module to require its own files.
---The base directory of the module is automatically prepended to the file path
---
---@private
---
---@param path string path to the base folder of a module
---@param env table when the module requires other modules, this is the environment to evaluate these in
---@return function
local function moduleRequireFunction(path, env)
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
        local full_path = path .. "/" .. sanitized_file

        local is_lua = sanitized_file:match("([.]lua)$")
        local is_dll = sanitized_file:match("([.]dll)$")

        if is_dll then
            local sanitized_file_name = sanitized_file
            if is_lua or is_dll then
                sanitized_file_name = sanitized_file:sub(1, -5) -- remove the extension part
            end
            -- TODO: This will run in a global env, test that.
            return assert(package.loadlib(full_path, "luaopen_" .. sanitized_file_name)())
        elseif is_lua then
        else
            ---Assume a lua file
            full_path = full_path .. ".lua"
        end

        local code, message = loadfile(full_path, 't', env)
        if not code then
            error(message)
        end

        local status, value = pcall(code)

        if not status then
            error(value)
        end

        return value
    end
end

---Prefixes the module name to a print when the module calls 'print'
---@param moduleName string the name of the module
---@see print
---@private
local function modulePrintFunction(moduleName)
    return function(...)
        print("[" .. moduleName .. "]: ", ...)
    end
end

---This function creates the module environment in which module code is evaluated. It provides the environment with custom require and print functions
---@private
local function createModuleEnvironment(name, path, forbidsGlobalAssignment, permittedFunctions)

    local env = {}

    if permittedFunctions then
        for k, v in pairs(permittedFunctions) do
            env[k] = v
        end
    end

    env.print = modulePrintFunction(name)
    env.require = moduleRequireFunction(path, env)

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
    createModuleEnvironment = createModuleEnvironment
}