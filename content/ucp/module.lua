---@module module

---@class Module
Module = {}

---When a module is enabled on start up, this function is run.
---@param userConfig table table of user configuration parameters for this module
---@param config table table of all user configuration parameters
function Module:enable(userConfig, config)
end
---When a module is disabled, this function is run.
function Module:disable(userConfig, config)
end

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

--- Create a new instance of a ModuleLoader with the :new function. `ModuleLoader:new()`
---
---@class ModuleLoader
local ModuleLoader = {}

--- Create a new module loader
---
---@param moduleName string the name of the module
---@param moduleVersion string the version of the module in 0.0.0 format
---@param moduleOptions table a table of moduleOptions
---@return ModuleLoader
function ModuleLoader:new(moduleName, moduleVersion, moduleOptions)
    local o = setmetatable({
        moduleName = moduleName,
        moduleVersion = moduleVersion,
        modulePath = BASEDIR .. "/modules/" .. moduleName .. "-" .. moduleVersion,
        moduleOptions = moduleOptions,
    }, self)
    -- TODO _G is evil, restrict functions that are given to a module
    o.env = createModuleEnvironment(o.moduleName, o.modulePath, true, _G)
    self.__index = self
    return o
end

---Load the init.lua file for this module.
---
---@return table the module API, as defined by the `init.lua` file of this module.
function ModuleLoader:load()

    local init_file_path = self.modulePath .. "/init.lua"

    local initCode, message = loadfile(init_file_path, 't', self.env)
    if not initCode then
        error(message)
    end

    local status, value = pcall(initCode)

    if not status then
        error(value)
    else
        self.handle = value
    end

    if not self.handle then
        print("WARNING: " .. init_file_path .. " did not return a valid handle: " .. self.handle)
    end

    return self.handle
end

function ModuleLoader:unload()
    self.handle = nil
end

---Enable the module
---@param options table a table of all the options of all modules
function ModuleLoader:enableModule(options)
    return self.handle:enable(self.moduleOptions, options)
end

---Disable the module
---@param options table a table of all the options of all modules
function ModuleLoader:disableModule(options)
    return self.handle:disable(self.moduleOptions, options)
end

---Return the dependencies of this module by reading the module.yml file
---@return table an array of hash tables with the entries: module, equality, version
function ModuleLoader:dependencies()
    local handle, status, e = io.open(self.modulePath .. "/module.yml", 'r')
    if not handle then
        return nil
    end

    local data = handle:read("*all")
    handle:close()

    if data:len() == 0 then
        -- print("WARNING: the module.yml file of " .. self.moduleName .. " is empty")
        return nil
    end

    local y = yaml.eval(data)

    if not y.depends then
        return nil
    end

    local deps = {}
    for k, v in pairs(y.depends) do
        m, eq, version = v:match("([a-zA-Z0-9-_]+)([<>=]+)([0-9\\.]+)")
        table.insert(deps, {
            module = m,
            equality = eq,
            version = version
        })
    end

    return deps
end

---@private
---@param t table the table to compute the size of
local sizeOfTable = function(t)
    local result = 0
    for k, v in pairs(t) do
        result = result + 1
    end
    return result
end

---@class Set
---@private
local Set = {}
function Set:new(values)
    local o = {
        data = values or {}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Set:index(el)
    for k, v in pairs(self.data) do
        if v == el then
            return k
        end
    end
    return nil
end

function Set:contains(el)
    return self:index(el) ~= nil
end

function Set:add(el)
    if not self:contains(el) then
        table.insert(self.data, el)
        return true
    else
        return false
    end
end

function Set:delete(el)
    local index = self:index(el)
    if index ~= nil then
        table.remove(self.data, index)
        return true
    end
    return false
end

function Set:subtract(s)
    local result = Set:new()
    for k, v in pairs(self.data) do
        if not s:contains(v) then
            result:add(v)
        end
    end
    return result
end

function Set:update(s)
    for k, v in pairs(s.data) do
        self:add(v)
    end
    return self
end

---Class to solve dependencies
---@class DependencySolver
---@private
local DependencySolver = {
    new = function(self, modules)
        local o = {
            modules = modules or {},
        }
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    solve = function(self)
        --[[ Python pseudocode:
            '''
            Dependency resolver

        "arg" is a dependency dictionary in which
        the values are the dependencies of their respective keys.
        '''
        d=dict((k, set(arg[k])) for k in arg)
        r=[]
        while d:
            # values not in keys (items without dep)
            t=set(i for v in d.values() for i in v)-set(d.keys())
            # and keys without value (items without dep)
            t.update(k for k, v in d.items() if not v)
            # can be done right away
            r.append(t)
            # and cleaned up
            d=dict(((k, v-t) for k, v in d.items() if v))
        return r
        --]]

        local d = self.modules
        local r = {}
        while sizeOfTable(d) > 0 do
            local t1 = Set:new()
            local t2 = Set:new()
            local t3 = Set:new()
            for mod, deps in pairs(d) do
                t2:add(mod)

                if sizeOfTable(deps) == 0 then
                    t3:add(mod)
                end

                for l, dep in pairs(deps) do
                    t1:add(dep)
                end
            end
            local t = (t1:subtract(t2)):update(t3)

            table.insert(r, t.data)

            local d2 = {}
            for mod, deps in pairs(d) do
                if sizeOfTable(deps) > 0 then
                    d2[mod] = Set:new(deps):subtract(t).data
                end
            end

            d = d2
        end

        return r
    end,
}

--TODO test this thoroughly
---Creates a read only proxy table by proxying __index and __newindex of an existing table
---@class ReadOnlyTable
---@private
local ReadOnlyTable = {
    ---Create a new read-only table
    ---@param o table the object to make read-only
    new = function(self, o)
        if type(o) ~= "table" then
            error("the first parameter is not a table: " .. type(o))
        end
        return setmetatable({}, {
            __index = function(self, k)
                return o[k]
            end,
            __newindex = function(self, k, v)
                return error("setting values is not allowed: " .. k)
            end
        })
    end
}

---Change a table to a read-only table. Affects all nested tables too.
---@param o table the table to change into a read-only table
---@return table a read-only table
---@private
local function createRecursiveReadOnlyTable(o)
    for k, v in pairs(o) do
        if type(v) == "table" then
            o[k] = createRecursiveReadOnlyTable(v)
        end
    end
    return ReadOnlyTable:new(o)
end

return {
    ModuleLoader = ModuleLoader,
    DependencySolver = DependencySolver,
    ReadOnlyTable = ReadOnlyTable,
    createRecursiveReadOnlyTable = createRecursiveReadOnlyTable,
}
