local createRestrictedEnvironment = require('extensions.environment').createRestrictedEnvironment

--- Create a new instance of a BaseLoader with the :new function. `BaseLoader:new()`
---
---@class BaseLoader
local BaseLoader = {}

--- Create a new module loader
---
---@param name string the name of the module
---@param version string the version of the module in 0.0.0 format
---@param path string
---@param env table
---@return BaseLoader
function BaseLoader:new(obj)
    obj = obj or {}
    local o = setmetatable({
        name = obj.name,
        version = obj.version,
        path = obj.path,
        env = obj.env,
    }, self)
    self.__index = self
    return o
end

---Load the init.lua file for this module.
---
---@return table the module API, as defined by the `init.lua` file of this module.
function BaseLoader:load()

    local init_file_path = self.path .. "/init.lua"

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

function BaseLoader:unload()
    self.handle = nil
end


---Return the dependencies of this module by reading the module.yml file
---@return table an array of hash tables with the entries: name, equality, version
function BaseLoader:dependencies()
    local handle, status, e = io.open(self.path .. "/definition.yml", 'r')
    if not handle then
        return nil
    end

    local data = handle:read("*all")
    handle:close()

    if data:len() == 0 then
        -- print("WARNING: the module.yml file of " .. self.name .. " is empty")
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

---@class ModuleLoader
local ModuleLoader = BaseLoader:new()

function ModuleLoader:create(name, version)
    local path = BASEDIR .. "/modules/" .. name .. "-" .. version
    ---TODO: _G is evil, restrict which functions are given to a module or plugin
    local env = createRestrictedEnvironment(name, path, true, _G, true)
    return ModuleLoader:new{name=name, version=version, path=path, env=env}
end

---Enable the module
---@param options table a table of all the options of all modules
function ModuleLoader:enableModule(options)
    return self.handle:enable(options)
end

---Disable the module
---@param options table a table of all the options of all modules
function ModuleLoader:disableModule(options)
    return self.handle:disable(options)
end

---@class PluginLoader
local PluginLoader = BaseLoader:new()

function PluginLoader:create(name, version)
    local path = BASEDIR .. "/plugins/" .. name .. "-" .. version
    ---TODO: _G is evil, restrict which functions are given to a module or plugin
    local env = createRestrictedEnvironment(name, path, true, _G, false)
    return PluginLoader:new{name=name, version=version, path=path, env=env}
end

---Enable the plugin
---@param options table a table of all the options of all plugin
function PluginLoader:enablePlugin(options)
    return self.handle:enable(options)
end

---Disable the plugin
---@param options table a table of all the options of all plugin
function PluginLoader:disablePlugin(options)
    return self.handle:disable(options)
end

return {
    ModuleLoader = ModuleLoader,
    PluginLoader = PluginLoader,
}