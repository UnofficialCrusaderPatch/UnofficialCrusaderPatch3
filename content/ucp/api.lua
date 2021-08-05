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
package.path = BASEDIR .. "/?.lua"
package.path = package.path .. ";" .. BASEDIR .. "/?/init.lua"
---Load essential ucp lua code
core = require('core')
utils = require('utils')
data = {}
data.common = require('data.common')
data.structures = require('data.structures')
yaml = require('ext.yaml.yaml')
json = require('ext.json.json')
mod = require('module')
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
---@type Table<string, Module>
-- not declared as local because it should persist
modules = {}

---Table to hold all the module loaders
---@type Table<string, ModuleLoader>
---Note: not declared as local because it should persist
modLoaders = {}

--- Create a modloader for all modules we know of (via default config)
for k, v in pairs(default_config.modules) do
    print("[api]: Creating module loader for module: " .. k .. " version: " .. v.version)
    modLoaders[k] = mod.ModuleLoader:new(k, v.version, v.options)
end

---Determine the appropriate loading order

---This code is responsible for determining the order in which to load modules.
---Modules can depend on each other, so any dependencies should be loaded first.
---TODO: implement a check for module version conflicts.

local loadOrder = {}

local modDependencies = {}
for m, modLoader in pairs(modLoaders) do
    modDependencies[m] = {}
    local deps = modLoader:dependencies()
    if deps then
        for k, dep in pairs(deps) do
            table.insert(modDependencies[m], dep.module)
        end
    end
end

for k, mods in pairs(mod.DependencySolver:new(modDependencies):solve()) do
    for l, m in pairs(mods) do
        table.insert(loadOrder, m)
    end
end

--- Update the default config with values from the user config
local final_config = table.update(default_config, config)

---Load modules
---Iterate over all entries in the config => modules entry of the ucp-config file
for k, m in pairs(loadOrder) do
    local c = final_config.modules[m]
    if c.active then
        --- load the init.lua file of the module
        print("[api]: loading module: " .. m .. " version: " .. c.version)
        modLoaders[m]:load()
        modules[m] = modLoaders[m].handle
    end
end

---Enable modules in the right order
for k, m in pairs(loadOrder) do
    -- call the enable() function of the module
    if modLoaders[m] == nil then
        print("[api]: WARNING: Some modules are depending on '" .. m .. "' but it is not set to active. They will probably fail to run properly.")
    else
        if m ~= "lua_api" then
            print("[api]: enabling module: " .. m)
            modLoaders[m]:enableModule(final_config.modules[m])
        end
    end
end


