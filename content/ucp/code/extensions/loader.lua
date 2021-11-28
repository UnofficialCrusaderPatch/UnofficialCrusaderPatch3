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
        definition = nil,
    }, self)
    self.__index = self
    return o
end

---Load the init.lua file for this module.
---
---@return table the module API, as defined by the `init.lua` file of this module.
function BaseLoader:load()
    if self.env == nil then error("no valid 'env' specified") end
    local init_file_path = self.path .. "/init.lua"

	local handle, err = io.open(init_file_path)
	if not handle then
		error(err)
	end

	local initData = handle:read("*all")

    local initCode, message = load(initData, init_file_path, 't', self.env)
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

function BaseLoader:loadDefinition()
    if self.definition ~= nil then return end

    local handle, status, e = io.open(self.path .. "/definition.yml", 'r')
    if not handle then
        self.definition = false
        return nil
    end

    local data = handle:read("*all")
    handle:close()

    if data:len() == 0 then
        -- print("WARNING: the module.yml file of " .. self.name .. " is empty")
        self.definition = false
        return nil
    end

    local result, err = yaml.eval(data)
    if not result then
        log(ERROR, "error trying to load definition.yml of: " .. self.path .. "\nreason: " .. err)
        self.definition = {}
    else
        self.definition = result
    end
end

---Return the dependencies of this module by reading the module.yml file
---@return table an array of hash tables with the entries: name, equality, version
function BaseLoader:dependencies()
    self:loadDefinition()

    if not self.definition or not self.definition.depends then
        return { }
    end

    local deps = {}
    for k, v in pairs(self.definition.depends) do
        local m, eq, version = v:match("([a-zA-Z0-9-_]+)([<>=]+)([0-9\\.]+)")
        table.insert(deps, {
            name = m,
            equality = eq,
            version = version
        })
    end

    return deps
end

---Post processing. Changes file path strings to proper local file path strings.
---Checks if a string starts with "local://" and replaces that with the path argument
local function postProcess(path, t)
    local localHeader = "local://"
    local localHeaderSize = localHeader:len()
    local jobs = {}

    for k, v in pairs(t) do
        print(k, v)
        if type(v) == "table" then
            postProcess(path, v)
        elseif type(v) == "string" then
            if v:sub(1, localHeaderSize) == localHeader then
                table.insert(jobs, {tab = t, key = k, val = path .. "/" .. v:sub(localHeaderSize)})
            end
        end
    end
    for k, job in pairs(jobs) do
        job.tab[job.key] = job.val
    end
end


---Read the demanded config
function BaseLoader:config()
    local handle, status, e = io.open(self.path .. "/config.yml", 'r')
    if not handle then
        return { }
    end

    local data = handle:read("*all")
    handle:close()

    if data:len() == 0 then
        return { }
    end

    local y, err = yaml.eval(data)

    if not y then
        log(ERROR, "failed to parse config.yml for: " .. self.path .. "\nreason: " .. err)
    end

    postProcess(self.path, y)

    return y
end


function BaseLoader:verifyVersion()
    self:loadDefinition()

    if not self.definition then
        error("cannot verify version, empty definition.yml")
    end

    if not self.definition.version then
        error("Version mismatch between assumed version: '" .. self.version .. "' and defined version: '" .. self.definition.version .. "'")
    else
        self.definition.version = self.definition.version:gsub(" ", "") -- remove whitespace
    end

    if self.definition.version ~= self.version then
        error("Version mismatch between assumed version: '" .. self.version .. "' and defined version: '" .. self.definition.version .. "'")
    end

    return true
end

---Enable the extension
function BaseLoader:enable(options)
    return self.handle:enable(options)
end

---Disable the extension
function BaseLoader:disable(options)
    return self.handle:disable(options)
end

function BaseLoader:type()
    return "BaseLoader"
end

---@class ModuleLoader
local ModuleLoader = BaseLoader:new()

function ModuleLoader:create(name, version)
    local path = BASEDIR .. "/modules/" .. name .. "-" .. version
    return ModuleLoader:new{name=name, version=version, path=path, env=nil}
end

function ModuleLoader:createEnvironment(allowed)
    self.env = createRestrictedEnvironment(self.name, self.path, true, allowed, true)
end

function ModuleLoader:type()
    return "ModuleLoader"
end

---@class PluginLoader
local PluginLoader = BaseLoader:new()

function PluginLoader:create(name, version)
    local path = BASEDIR .. "/plugins/" .. name .. "-" .. version
    return PluginLoader:new{name=name, version=version, path=path, env=nil}
end

function PluginLoader:createEnvironment(allowed)
    self.env = createRestrictedEnvironment(self.name, self.path, true, allowed, false)
end

function PluginLoader:type()
    return "PluginLoader"
end

return {
    ModuleLoader = ModuleLoader,
    PluginLoader = PluginLoader,
}