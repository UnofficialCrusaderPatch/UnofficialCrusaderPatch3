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

-- Arg parsing
if #arg > 0 then
  log(DEBUG, "Passed raw arguments: \n", yaml.dump(arg))
end

log(DEBUG, "Processed arguments: \n", yaml.dump(processedArg))

if processedArg["ucp-config-file"] ~= nil then
  CONFIG_FILE = processedArg["ucp-config-file"]
end

-- Fixes threading issue in the original game
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
publicElements = {}

-- These contains the proxies that are passed to extensions
moduleProxies = {}
pluginProxies = {}
modulePublicProxies = {}
pluginPublicProxies = {}

function table.merge(t1, t2)
  
  for k, v in ipairs(t1) do 
    error("Cannot apply table.merge on an array")
  end
  
  for k, v in ipairs(t2) do 
    error("Cannot apply table.merge on an array")
  end

  local t = {}

  for k, v in pairs(t1) do t[k] = v end
  for k, v in pairs(t2) do t[k] = v end

  return t
end

---TODO: restrict module allowed functions table
moduleEnv = table.merge(_G, {
  modules = moduleProxies,
  plugins = pluginProxies,  
})
pluginEnv = {
    modules = modulePublicProxies,
    plugins = pluginPublicProxies,
    utils = utils,
    table = table,
    string = string,
    type = type,
    pairs = pairs,
    ipairs = ipairs,
}

local ExtensionProxy = extensions.proxies.ExtensionProxy
local PublicProxy = extensions.proxies.PublicProxy

for k, ext in pairs(allActiveExtensions) do
    local t = ext:type()
    if t == "ModuleLoader" then
        log(INFO, "[main]: loading extension: " .. ext.name .. " version: " .. ext.version)
        ext:createEnvironment(moduleEnv)
        local e, p = ext:load(moduleEnv)
        modules[ext.name], publicElements[ext.name] = e, p
        log(DEBUG, string.format("extension '%s' has public elements: %s", ext.name, table.concat(p or {}, ', ')))
        local ep = ExtensionProxy(e)
        moduleProxies[ext.name] = ep
        modulePublicProxies[ext.name] = PublicProxy(ep, p)
    elseif t == "PluginLoader" then
      log(INFO, "[main]: loading extension: " .. ext.name .. " version: " .. ext.version)
        ext:createEnvironment(pluginEnv)
        local e, p = ext:load(pluginEnv)
        plugins[ext.name], publicElements[ext.name] = e, p
        log(DEBUG, string.format("extension '%s' has public elements: %s", ext.name, table.concat(p or {}, ', ')))
        local ep = ExtensionProxy(e)
        pluginProxies[ext.name] = ep
        pluginPublicProxies[ext.name] = PublicProxy(ep, p)
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
    elseif t == "PluginLoader" then
      log(INFO, "[main]: enabling extension: " .. ext.name .. " version: " .. ext.version)
        local o = configFinal[ext.name .. "-" .. ext.version] or {}
        ext:enable(o)
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

