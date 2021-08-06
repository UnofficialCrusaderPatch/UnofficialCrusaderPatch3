---Version declarations, can be checked by modules
API_VERSION = "0.0.1"
UCP_VERSION = "3.0.0"

---Variable to indicate to show debug information
DEBUG = true

---UCP base directory configuration
BASEDIR = "ucp"

---Change the ucp working directory based on an environment variable
---@param UCP_DIR string path to the ucp directory
UCP_DIR = os.getenv("UCP_DIR")

if UCP_DIR then
    if UCP_DIR:sub(-1) ~= "\\" and UCP_DIR:sub(-1) ~= "/" then
        UCP_DIR = UCP_DIR + "\\"
    end
    print("[api]: Setting BASEDIR to " .. UCP_DIR)
    BASEDIR = UCP_DIR
end

---File that contains the defaults
CONFIG_DEFAULTS_FILE = "ucp-config-defaults.yml"

---Config file configuration
CONFIG_FILE = "ucp-config.yml"

---Change the config path based on an environment variable
---@param UCP_CONFIG string full path to the config file
UCP_CONFIG = os.getenv("UCP_CONFIG")

if UCP_CONFIG then
    print("[api]: Setting UCP_CONFIG to " .. UCP_CONFIG)
    CONFIG_FILE = UCP_CONFIG
end

---Indicates where to load UCP lua files from
package.path = BASEDIR .. "/code/?.lua"
package.path = package.path .. ";" .. BASEDIR .. "/code/?/init.lua"
---Load essential ucp lua code
core = require('core')
utils = require('utils')
data = {}
data.common = require('data.common')
data.structures = require('data.structures')
yaml = require('ext.yaml.yaml')
json = require('ext.json.json')
extensions = require('extensions')
sha = require("ext.pure_lua_SHA.sha2")
hooks = require('hooks')

---Load the default config file
default_config = (function()
    local f, message = io.open(CONFIG_DEFAULTS_FILE)
    if not f then
        print("[api]: Could not read '" .. CONFIG_DEFAULTS_FILE .. "'.yml. Reason: " .. message)
        return { modules = {} }
    end
    local data = f:read("*all")
    f:close()

    return yaml.eval(data)
end)()

---Load the config file
---Note: not yet declared as local because it is convenient to access in the console
config = (function()
    local f, message = io.open(CONFIG_FILE)
    if not f then
        print("[api]: Could not read ucp-config.yml. Reason: " .. message)
        print("[api]: Treating ucp-config.yml as empty file")
        return { modules = {} }
    end
    local data = f:read("*all")
    f:close()

    return yaml.eval(data)
end)()

---Early bail out of UCP
if config.active == false then
    print("[api]: UCP3 is set to inactive. To activate UCP3, change 'active' to true in ucp-config.yml")
    return nil
end


---Table to hold all the modules
---@type table<string, Module>
--- not declared as local because it should persist
modules = {}

---Table to hold all the module loaders
---@type table<string, ModuleLoader>
---Note: not declared as local because it should persist
modLoaders = {}

--- Create a modloader for all modules we know of (via default config)
for k, v in pairs(default_config.modules) do
    print("[api]: Creating module loader for module: " .. k .. " version: " .. v.version)
    modLoaders[k] = extensions.ModuleLoader:create(k, v.version)
end

---Determine the appropriate loading order

---This code is responsible for determining the order in which to load modules.
---Modules can depend on each other, so any dependencies should be loaded first.
---TODO: implement a check for module version conflicts.

local moduleLoadOrder = {}

local modDependencies = {}
for m, modLoader in pairs(modLoaders) do
    modDependencies[m] = {}
    local deps = modLoader:dependencies()
    if deps then
        for k, dep in pairs(deps) do
            table.insert(modDependencies[m], dep.name)
        end
    end
end

for k, mods in pairs(extensions.DependencySolver:new(modDependencies):solve()) do
    for l, m in pairs(mods) do
        table.insert(moduleLoadOrder, m)
    end
end

--- Update the default config with values from the user config
local final_config = table.update(default_config, config)
final_config.plugins = final_config.plugins or {}

---Load modules
---Iterate over all entries in the config => modules entry of the ucp-config file
for k, m in pairs(moduleLoadOrder) do
    local c = final_config.modules[m]
    if c.active then
        --- load the init.lua file of the module
        print("[api]: loading module: " .. m .. " version: " .. c.version)
        modLoaders[m]:load()
        modules[m] = modLoaders[m].handle
    end
end

---Enable modules in the right order
for k, m in pairs(moduleLoadOrder) do
    -- call the enable() function of the module
    if modLoaders[m] == nil or modLoaders[m].handle == nil then
        -- print("[api]: WARNING: Some modules are depending on '" .. m .. "' but it is not set to active. They will probably fail to run properly.")
    else
        if m ~= "lua_api" then
            print("[api]: enabling module: " .. m)
            modLoaders[m]:enableModule(final_config.modules[m].options)
        end
    end
end


---Freeze the modules
modules = extensions.createRecursiveReadOnlyTable(modules)



---Dynamic plugin discovery
pluginFolders = table.pack(ucp.internal.listDirectories(BASEDIR .. "/plugins"))

---@type table<string, PluginLoader>
pluginLoaders = {}
plugins = {}

--- Create a pluginloader for all plugins we can find
for k, pluginFolder in ipairs(pluginFolders) do
    local pluginVersion = pluginFolder:match("(-[0-9\\.]+)$"):sub(2)
    local pluginName = pluginFolder:sub(1, string.len(pluginFolder)-(string.len(pluginVersion)+1)):match("[/\\]+([a-zA-Z0-9-]+)$")
    print("[api]: Creating plugin loader for plugin: " .. pluginName .. " version: " .. pluginVersion)
    pluginLoaders[pluginName] = extensions.PluginLoader:create(pluginName, pluginVersion)
    pluginLoaders[pluginName]:verifyVersion()
end

local ignorantPluginLoadOrder = {}
local pluginDependencies = {}

for m, pluginLoader in pairs(pluginLoaders) do
    pluginDependencies[m] = {}
    local deps = pluginLoader:dependencies()
    if deps then
        for k, dep in pairs(deps) do
            table.insert(pluginDependencies[m], dep.name)
        end
    end
end

for k, mods in pairs(extensions.DependencySolver:new(pluginDependencies):solve()) do
    for l, m in pairs(mods) do
        table.insert(ignorantPluginLoadOrder, m)
    end
end

---Remove the modules we have loaded from the list
local pluginLoadOrder = {}
for k, pluginName in pairs(ignorantPluginLoadOrder) do
    if modLoaders[pluginName] == nil then
        ---It is a plugin, schedule it to be loaded
        table.insert(pluginLoadOrder, pluginName)
    else
        if modLoaders[pluginName].handle == nil then
            print("[api]: module '" .. pluginName .. "' is required for a plugin but it is not active.")
        end
    end
end


---Load plugins
---Iterate over all entries in the config => plugins entry of the ucp-config file
for k, m in pairs(pluginLoadOrder) do
    local c = final_config.plugins[m]
    if c and c.active then
        --- load the init.lua file of the plugin
        print("[api]: loading plugin: " .. m .. " version: " .. c.version)
        pluginLoaders[m]:load()
        plugins[m] = pluginLoaders[m].handle
    end
end

---Enable plugins in the right order
for k, m in pairs(pluginLoadOrder) do
    -- call the enable() function of the plugin
    if pluginLoaders[m] == nil or pluginLoaders[m].handle == nil then
        -- print("[api]: WARNING: Some plugins are depending on '" .. m .. "' but it is not set to active. They will probably fail to run properly.")
    else
        if m ~= "lua_api" then
            print("[api]: enabling plugin: " .. m)
            pluginLoaders[m]:enablePlugin(final_config.plugins[m].options)
        end
    end
end