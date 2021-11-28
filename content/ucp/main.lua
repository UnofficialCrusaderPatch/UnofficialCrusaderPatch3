---Version declarations, can be checked by modules
API_VERSION = "0.0.1"
UCP_VERSION = "3.0.0"

---Variable to indicate to show debug information
DEBUG = true

---UCP base directory configuration
BASEDIR = "ucp"

---Change the ucp working directory based on an environment variable
---@deprecated UCP_DIR is now handled in the dll part
---@param UCP_DIR string path to the ucp directory
UCP_DIR = os.getenv("UCP_DIR")
if UCP_DIR then
  print("[main]: Using UCP_DIR: " .. UCP_DIR)
else 
  print("[main]: Using the default UCP_DIR")
end

---@deprecated UCP_DIR is now handled in the dll part
--[[
if UCP_DIR then
    if UCP_DIR:sub(-1) ~= "\\" and UCP_DIR:sub(-1) ~= "/" then
        UCP_DIR = UCP_DIR + "\\"
    end
    print("[main]: Setting BASEDIR to " .. UCP_DIR)
    BASEDIR = UCP_DIR
end
--]]

---File that contains the defaults
CONFIG_DEFAULTS_FILE = "ucp-config-defaults.yml"

---Config file configuration
CONFIG_FILE = "ucp-config.yml"

---Change the config path based on an environment variable
---@param UCP_CONFIG string full path to the config file
UCP_CONFIG = os.getenv("UCP_CONFIG")

if UCP_CONFIG then
    print("[main]: Setting UCP_CONFIG to " .. UCP_CONFIG)
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
data.version = require('data.version')
data.cache = require('data.cache')
yaml = require('data.yaml')
json = require('vendor.json.json')
extensions = require('extensions')
sha = require("vendor.pure_lua_SHA.sha2")
hooks = require('hooks')

require("logging")

data.version.initialize()
data.cache.AOB.loadFromFile()

---UCP3 Configuration
---Load the default config file
default_config = (function()
    local f, message = io.open(CONFIG_DEFAULTS_FILE)
    if not f then
	    log(WARNING, "[main]: Could not read '" .. CONFIG_DEFAULTS_FILE .. "'.yml. Reason: " .. message)
        log(WARNING, "[main]: Treating '" .. CONFIG_DEFAULTS_FILE .. "' as empty file")
        return { modules = {} }
    end
    local data = f:read("*all")
    f:close()

    local result = yaml.eval(data)
    if not result.plugins then result.plugins = {} end
    if not result.modules then result.modules = {} end
    return result
end)()

---Load the config file
---Note: not yet declared as local because it is convenient to access in the console
config = (function()
    local f, message = io.open(CONFIG_FILE)
    if not f then
        log(WARNING, "[main]: Could not read ucp-config.yml. Reason: " .. message)
        log(WARNING, "[main]: Treating ucp-config.yml as empty file")
        return { modules = {}, plugins = {} }
    end
    local data = f:read("*all")
    f:close()

    local result = yaml.eval(data)
    if not result.plugins then result.plugins = {} end
    if not result.modules then result.modules = {} end
    return result
end)()

---Early bail out of UCP
if config.active == false then
    log(WARNING, "[main]: UCP3 is set to inactive. To activate UCP3, change 'active' to true in ucp-config.yml")
    return nil
end

extensionsTable = {}
extensionLoaders = {}

local function loadExtensionsFromFolder(folder, cls)
    ---Dynamic extensions discovery
    local subFolders, err = table.pack(ucp.internal.listDirectories(BASEDIR .. "/" .. folder))

	if not subFolders then
		log(ERROR, "no subfolders detected for path: " .. BASEDIR .. "/" .. folder)
		error(err)
	end

    --- Create a loader for all extensions we can find
    for k, subFolder in ipairs(subFolders) do
		if subFolder:sub(-1) == "/" then
			subFolder = subFolder:sub(1, -2)
		end
		if subFolder:match("(-[0-9\\.]+)$") == nil then error("invalid extension folder name: " .. subFolder) end
        local version = subFolder:match("(-[0-9\\.]+)$"):sub(2)
        local name = subFolder:sub(1, string.len(subFolder)-(string.len(version)+1)):match("[/\\]+([a-zA-Z0-9-]+)$")

        log(INFO, "[main]: Creating extension loader for: " .. name .. " version: " .. version)

        if extensionLoaders[name] ~= nil then error("extension with name already exists: " .. name) end

        extensionLoaders[name] = cls:create(name, version)
        extensionLoaders[name]:verifyVersion()
    end
end

loadExtensionsFromFolder("modules", extensions.ModuleLoader)
loadExtensionsFromFolder("plugins", extensions.PluginLoader)

log(INFO, "[main]: solving load order")

extensionDependencies = {}
for name, ext in pairs(extensionLoaders) do
    extensionDependencies[name] = {}
    local deps = ext:dependencies()
    if deps then
        for k, dep in pairs(deps) do
            table.insert(extensionDependencies[name], dep.name)
        end
    end
end

extensionLoadOrder = {}
for k, exts in pairs(extensions.DependencySolver:new(extensionDependencies):solve()) do
    for l, ext in pairs(exts) do
        table.insert(extensionLoadOrder, ext)
    end
end



---Now we are ready to parse the configurations of each extension
---Low level conflict checking should be done when setting the user config
joinedDefaultConfig = {extensions = {}}
for k, v in pairs(default_config.modules) do
    joinedDefaultConfig.extensions[k] = v
end
for k, v in pairs(default_config.plugins) do
    joinedDefaultConfig.extensions[k] = v
end

joinedConfig = {extensions = {}}
for k, v in pairs(config.modules) do
    joinedConfig.extensions[k] = v
end
for k, v in pairs(config.plugins) do
    joinedConfig.extensions[k] = v
end

log(INFO, "[main]: verifying extension dependencies")
explicitlyActiveExtensions = {}
for k, ext in pairs(extensionLoadOrder) do
    if joinedConfig.extensions[ext] then
        if joinedConfig.extensions[ext].active == true then
            if data.version.verifyDependencies(ext, extensionLoaders) then
                if data.version.verifyGameDependency(ext, extensionLoaders) then
                    table.insert(explicitlyActiveExtensions, ext)
                end
			end
        end
    elseif joinedDefaultConfig.extensions[ext] and joinedDefaultConfig.extensions[ext].active == true then
        if data.version.verifyDependencies(ext, extensionLoaders) then
            if data.version.verifyGameDependency(ext, extensionLoaders) then
                table.insert(explicitlyActiveExtensions, ext)
            end
        end
    end
end

log(DEBUG, "[main]: explicitly active extensions:\n" .. json:encode_pretty(explicitlyActiveExtensions))

necessaryDependencies = {}
for k, ext in pairs(explicitlyActiveExtensions) do
    for k2, dep in pairs(extensionDependencies[ext]) do
        table.insert(necessaryDependencies, dep)
    end
end

i = 1
while i <= #necessaryDependencies do
	local ext = necessaryDependencies[i]
	if ext then
		for k, dep in pairs(extensionDependencies[ext]) do
			if not table.find(necessaryDependencies, dep) then
				table.insert(necessaryDependencies, dep)
			end
		end
	end
	i = i + 1
end

log(DEBUG, "required dependencies:\n" .. json:encode_pretty(necessaryDependencies))

---Try to merge extension configurations with user 'config'

function compareConfiguration(c1, c2, conflicts, path)
    conflicts = conflicts or {}
    path = path or "/root"
    for k, v2 in pairs(c2) do
        if c1[k] ~= nil then
            ---k exists in c1 and c2, check if they clash
            local v1 = c1[k]
            if v1 ~= v2 then
                if type(v1) == "table" and type(v2) == "table" then
                    compareConfiguration(v1, v2, conflicts, path .. "/" .. k)
                else
                    table.insert(conflicts, {path = path .. "/" .. k, value1 = v1, value2 = v2})
                end
            end
        end
    end
    return conflicts
end

function mergeConfiguration(c1, c2)
    for k, v2 in pairs(c2) do
        if c1[k] ~= nil then
            ---k exists in c1 and c2, check if they clash
            local v1 = c1[k]
            if v1 ~= v2 then
                if type(v1) == "table" and type(v2) == "table" then
                    mergeConfiguration(v1, v2)
                elseif type(v1) ~= type(v2) then
                    error("incompatible types in key: " .. k)
                else
                    c1[k] = v2
                end
            end
        else
            c1[k] = v2
        end
    end
end

configMaster = config
configSlave = default_config

allActiveExtensions = {}
for k, ext in pairs(necessaryDependencies) do
    table.insert(allActiveExtensions, ext)
end
for k, ext in pairs(explicitlyActiveExtensions) do
    if not table.find(allActiveExtensions, ext) then
       table.insert(allActiveExtensions, ext)
    end
end

for k, dep in pairs(allActiveExtensions) do
    local depConfig = extensionLoaders[dep]:config()
    local conflicts = compareConfiguration(configMaster, depConfig)
    if #conflicts > 0 then
        local msg = "failed to merge configuration of user and: " .. dep .. ".\ndifferences: "
        for k2, conflict in pairs(conflicts) do
            msg = "\n\tpath: " .. conflict.path .. ", value 1" .. conflict.value1 .. ", " .. conflict.value2
        end
        error(msg)
    end
    mergeConfiguration(configMaster, depConfig)
end

---Lastly, to get a complete config, override the defaults, ignore differences or conflicts
mergeConfiguration(default_config, configMaster)
configFinal = default_config

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

for k, dep in pairs(allActiveExtensions) do
    local t = extensionLoaders[dep]:type()
    if t == "ModuleLoader" then
        print("[main]: loading extension: " .. dep .. " version: " .. extensionLoaders[dep].version)
        extensionLoaders[dep]:createEnvironment(moduleEnv)
        modules[dep] = extensionLoaders[dep]:load(moduleEnv)
    elseif t == "PluginLoader" then
        print("[main]: loading extension: " .. dep .. " version: " .. extensionLoaders[dep].version)
        extensionLoaders[dep]:createEnvironment(pluginEnv)
        plugins[dep] = extensionLoaders[dep]:load(pluginEnv)
    else
        error("unknown extension type for: " .. dep)
    end
end

for k, dep in pairs(allActiveExtensions) do
    local t = extensionLoaders[dep]:type()
    if t == "ModuleLoader" then
        print("[main]: enabling extension: " .. dep .. " version: " .. extensionLoaders[dep].version)
        extensionLoaders[dep]:enable(configFinal.modules[dep].options or {})
        modules[dep] = extensions.createRecursiveReadOnlyTable(modules[dep])
    elseif t == "PluginLoader" then
        print("[main]: enabling extension: " .. dep .. " version: " .. extensionLoaders[dep].version)
        extensionLoaders[dep]:enable(configFinal.plugins[dep].options or {})
        plugins[dep] = extensions.createRecursiveReadOnlyTable(plugins[dep])
    else
        error("unknown extension type for: " .. dep)
    end
end

data.cache.AOB.dumpToFile()
