---Version declarations, can be checked by modules
API_VERSION = "0.0.1"
UCP_VERSION = "3.0.0"

---Variable to indicate to show debug information
DEBUG = true

---UCP base directory configuration
BASEDIR = "ucp"

---Change the ucp working directory based on an environment variable
---@extrecated UCP_DIR is now handled in the dll part
---@param UCP_DIR string path to the ucp directory
UCP_DIR = os.getenv("UCP_DIR")
if UCP_DIR then
  print("[main]: Using UCP_DIR: " .. UCP_DIR)
else 
  print("[main]: Using the default UCP_DIR")
end

---Config file configuration
CONFIG_FILE = "ucp-config.yml"

---Change the config path based on an environment variable
---@param UCP_CONFIG string full path to the config file
UCP_CONFIG = os.getenv("UCP_CONFIG")

if UCP_CONFIG then
    print("[main]: Setting UCP_CONFIG to " .. UCP_CONFIG)
    CONFIG_FILE = UCP_CONFIG
end

---Load essential ucp lua code
core = require('core')
utils = require('utils')
data = require('data')
yaml = data.yaml
json = require('vendor.json.json')
extensions = require('extensions')
sha = require("vendor.pure_lua_SHA.sha2")
hooks = require('hooks')
config = require('config')
version = require('version')

require("logging")

data.version.initialize()
data.cache.AOB.loadFromFile()
data.cache.DefaultConfigCache:loadFromFile()

---Load the config file
---Note: not yet declared as local because it is convenient to access in the console
user_config = config.ConfigHandler.loadUserConfig()

---Early bail out of UCP
if user_config.active == false then
    log(WARNING, "[main]: UCP3 is set to inactive. To activate UCP3, change 'active' to true in ucp-config.yml")
    return nil
end

---Collection of all extensions in the form of extension loaders (ModuleLoader and PluginLoader) which interface with the file structure of extensions
extensionLoaders = {}

config.utils.loadExtensionsFromFolder(extensionLoaders, "modules", extensions.ModuleLoader)
config.utils.loadExtensionsFromFolder(extensionLoaders, "plugins", extensions.PluginLoader)

extensionsInLoadOrder = {}

if user_config.order == nil then
    log(FATAL, "user config does not contain an extension load 'order'")    
else
  for k, req in pairs(user_config.order) do
    local m = config.matcher.findMatchForExtensionRequirement(extensionLoaders, req)
    if m == nil then
      log(ERROR, "Could not find a matching extension for requirement: " .. tostring(req))
    end
    table.insert(extensionsInLoadOrder, m)
  end
    
end

---Now we are ready to parse the configurations of each extension
---Low level conflict checking should be done when setting the user config

joinedUserConfig = {}
for k, v in pairs(user_config.modules) do
  local key = k .. "-" .. v.version
  local options = v.options
  joinedUserConfig[key] = options
end

defaultConfig = {}
for k, ext in pairs(extensionsInLoadOrder) do
  local defaults = data.cache.DefaultConfigCache:retrieve(ext)
  defaultConfig[ext.name .. "-" .. ext.version] = defaults
end

data.cache.DefaultConfigCache:saveToFile()

allActiveExtensions = extensionsInLoadOrder

---Resolve the user and default config to a final config
configFinal = config.merger.resolveToFinalConfig(allActiveExtensions, joinedUserConfig, defaultConfig)

local handle, err = io.open(".ucp-final-config-cache", 'w')
handle:write(json:encode(configFinal))
handle:close()

---Overwrite game menu version
data.version.overwriteVersion(configFinal)

---Table to hold all the modules
---@type table<string, Module>
--- not declared as local because it should persist
modules = {}
plugins = {}


---TODO: restrict module allowed functions table
moduleEnv = _G
pluginEnv = {
    modules = modules,
    plugins = plugins,
    utils = utils,
    table = table,
    string = string,
    type = type,
    pairs = pairs,
    ipairs = ipairs,
}

for k, ext in pairs(allActiveExtensions) do
    local t = ext:type()
    if t == "ModuleLoader" then
        log(INFO, "[main]: loading extension: " .. ext.name .. " version: " .. ext.version)
        ext:createEnvironment(moduleEnv)
        modules[ext.name] = ext:load(moduleEnv)
    elseif t == "PluginLoader" then
      log(INFO, "[main]: loading extension: " .. ext.name .. " version: " .. ext.version)
        ext:createEnvironment(pluginEnv)
        plugins[ext.name] = ext:load(pluginEnv)
    else
        error("unknown extension type for: " .. ext.name)
    end
end

for k, ext in pairs(allActiveExtensions) do
    local t = ext:type()
    if t == "ModuleLoader" then
      log(INFO, "[main]: enabling extension: " .. ext.name .. " version: " .. ext.version)
        local o = configFinal[ext.name .. "-" .. ext.version] or {}
        ext:enable(o)
        modules[ext.name] = extensions.createRecursiveReadOnlyTable(modules[ext.name])
    elseif t == "PluginLoader" then
      log(INFO, "[main]: enabling extension: " .. ext.name .. " version: " .. ext.version)
        local o = configFinal[ext.name .. "-" .. ext.version] or {}
        ext:enable(o)
        plugins[ext.name] = extensions.createRecursiveReadOnlyTable(plugins[ext.name])
    else
        error("unknown extension type for: " .. ext.name)
    end
end

(function() 
  local f = io.open("ucp/code/dev.lua", 'r')
  if not f then return end
  
  print("loading 'ucp/code/dev.lua'")
  
  local f, err = load(f:read("*all"), "ucp/code/dev.lua")
  if not f then
    print("\t" .. err)
  end
  local success, result = pcall(f)
  if not success then
    print("\t" .. result)
  end
end)()

data.cache.AOB.dumpToFile()

