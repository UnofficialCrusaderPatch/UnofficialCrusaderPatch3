local createModuleEnvironment = require('module.environment').createModuleEnvironment

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

return {
    ModuleLoader = ModuleLoader
}