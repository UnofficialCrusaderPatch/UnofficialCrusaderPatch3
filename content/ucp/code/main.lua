---Version declarations, can be checked by modules
LUA_API_VERSION = "1.0.0"
UCP_VERSION = "3.0.0"

--- @deprecated
---Variable to indicate to show debug information
-- DEBUG = true

---Change the ucp working directory based on an environment variable
---@extrecated UCP_DIR is now handled in the dll part
---@param UCP_DIR string path to the ucp directory
UCP_DIR = os.getenv("UCP_DIR")
if UCP_DIR then
  print("[main]: Using UCP_DIR: " .. UCP_DIR)
else 
  print("[main]: Using the default UCP_DIR")
end

require("constants")

---Config file configuration
CONFIG_FILE = CONST_DEFAULT_CONFIG_FILE

---Change the config path based on an environment variable
---@param UCP_CONFIG string full path to the config file
UCP_CONFIG = os.getenv(CONST_ENV_UCP_CONFIG)

if UCP_CONFIG then
    print("[main]: Setting UCP_CONFIG to " .. UCP_CONFIG)
    CONFIG_FILE = UCP_CONFIG
end

---Load essential ucp lua code
core = require('core')
utils = require('utils')
data = require('data')
json = require('vendor.json.json')
extensions = require('extensions')
sha = require("vendor.pure_lua_SHA.sha2")
hooks = require('hooks')
config = require('config')
version = require('version')

require("logging")

fixes = require('fixes')
fixes.applyAll()

data.version.initialize()
data.cache.AOB.loadFromFile()
-- data.cache.DefaultConfigCache:loadFromFile()

---Load the config file
---Note: not yet declared as local because it is convenient to access in the console
userConfig = config.ConfigHandler.loadUserConfig()
config.ConfigHandler.validateUserConfig(userConfig)

---Early bail out of UCP
if userConfig.active == false then
    log(WARNING, "[main]: UCP3 is set to inactive. To activate UCP3, change 'active' to true in ucp-config.yml")
    return nil
end

---Collection of all extensions in the form of extension loaders (ModuleLoader and PluginLoader) which interface with the file structure of extensions
extensionLoaders = {}

-- TODO: rewrite this such that only extensions are loaded that will be actually used...
--[[

This code was a bit too expensive because it forces the computation of SHA256 sums on all extensions

config.utils.loadExtensionsFromFolder(extensionLoaders, "modules", extensions.ModuleLoader)
config.utils.loadExtensionsFromFolder(extensionLoaders, "plugins", extensions.PluginLoader)

So for now we use the following logic:
--]]

moduleFolders = config.utils.parseExtensionsFolder(CONST_MODULES_FOLDER)
pluginFolders = config.utils.parseExtensionsFolder(CONST_PLUGINS_FOLDER)

log(DEBUG, "[main]: module folder count: " .. tostring(#moduleFolders))
log(DEBUG, "[main]: plugin folder count: " .. tostring(#pluginFolders))

fullUserConfig = userConfig['config-full']

loadOrder = fullUserConfig['load-order']

extensionsInLoadOrder = {}

if loadOrder == nil then
    log(FATAL, "[main]: user config does not contain 'load-order'")    
else
  for k, req in pairs(loadOrder) do
  --[[
    This code is for the future:
    
    local m = config.matcher.findMatchForExtensionRequirement(extensionLoaders, req)
  --]]  
  
  log(DEBUG, "[main]: iterating through load order, trying: " .. req)
  
    local m = config.matcher.findPreMatchForExtensionRequirement(moduleFolders, req)
    local e

    if m == nil then
        m = config.matcher.findPreMatchForExtensionRequirement(pluginFolders, req)

        if m == nil then
          log(FATAL, "[main]: Could not find a matching extension for requirement: " .. tostring(req))
        else
          e = config.utils.loadExtensionFromFolder(m.name, m.version, extensions.PluginLoader)
          extensionLoaders[m.name] = e
          ucp.internal.registerPathAlias(CONST_PLUGINS_FOLDER .. m.name .. "/", CONST_PLUGINS_FOLDER .. m.name .. "-" .. m.version .. "/")
          ucp.internal.registerPathAlias(CONST_PLUGINS_FOLDER .. m.name .. "-*" .. "/", CONST_PLUGINS_FOLDER .. m.name .. "-" .. m.version .. "/")
        end
    else
        e = config.utils.loadExtensionFromFolder(m.name, m.version, extensions.ModuleLoader)
        extensionLoaders[m.name] = e
        ucp.internal.registerPathAlias(CONST_MODULES_FOLDER .. m.name .. "/", CONST_MODULES_FOLDER .. m.name .. "-" .. m.version .. "/")
        ucp.internal.registerPathAlias(CONST_MODULES_FOLDER .. m.name .. "-*" .. "/", CONST_MODULES_FOLDER .. m.name .. "-" .. m.version .. "/")
    end



    table.insert(extensionsInLoadOrder, e)
  end
    
end

---Now we are ready to parse the configurations of each extension
---Low level conflict checking should be done when setting the user config

joinedUserConfig = {}
for k, v in pairs(fullUserConfig.modules) do
  local e = extensionLoaders[k]
  local key = k .. "-" .. e.version
  local config = v.config
  joinedUserConfig[key] = config
end
for k, v in pairs(fullUserConfig.plugins) do
  local e = extensionLoaders[k]
  local key = k .. "-" .. e.version
  local config = v.config
  joinedUserConfig[key] = config
end

--[[
-- The defaultConfig is kept in this file for now. We probably want its capabilities in the future...

defaultConfig = {}
for k, ext in pairs(extensionsInLoadOrder) do
  local defaults = data.cache.DefaultConfigCache:retrieve(ext)
  defaultConfig[ext.name .. "-" .. ext.version] = defaults
end

data.cache.DefaultConfigCache:saveToFile()

--]]

allActiveExtensions = extensionsInLoadOrder

---Resolve the user and default config to a final config.
-- configFinal = config.merger.resolveToFinalConfig(allActiveExtensions, joinedUserConfig, defaultConfig)
configFinal = joinedUserConfig
config.ConfigHandler.normalizeContentsValues(configFinal)

log(INFO, "Final config (normalized): ")
log(INFO, "\n" .. tostring(yaml.dump(configFinal)))

local handle, err = io.open(CONST_FINAL_CONFIG_CACHE_FILE, 'w')
handle:write(yaml.dump(configFinal))
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
        error("[main]: unknown extension type for: " .. ext.name)
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
        error("[main]: unknown extension type for: " .. ext.name)
    end
end

(function() 
  local f = io.open(CONST_DEVCODE_PATH, 'r')
  if not f then return end
  
  log(INFO, "loading " .. CONST_DEVCODE_PATH)
  
  local f, err = load(f:read("*all"), CONST_DEVCODE_PATH)
  if not f then
    log(INFO, "\t" .. err)
  end
  local success, result = pcall(f)
  if not success then
    log(INFO, "\t" .. result)
  end
end)()

data.cache.AOB.dumpToFile()

