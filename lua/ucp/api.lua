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
  print("Setting UCP_DIR to " .. UCP_DIR)
  BASEDIR = UCP_DIR .. "/" .. "ucp"
end


---Config file configuration
CONFIG_FILE = "ucp-config.yml"

---Change the config path based on an environment variable
---@param UCP_CONFIG string full path to the config file
UCP_CONFIG = os.getenv("UCP_CONFIG")

if UCP_CONFIG then
  print("Setting UCP_CONFIG to " .. UCP_CONFIG)
  CONFIG_FILE = UCP_CONFIG
end


---Indicates where to load UCP lua files from
package.path = BASEDIR .. "/?.lua"
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

---Load the config file
---Note: not yet declared as local because it is convenient to access in the console
config = (function()
  local f, message = io.open(CONFIG_FILE)
  if not f then error(message) end
  local data = f:read("*all")
  f:close()
  
  return yaml.eval(data)
end)()


---Table to hold all the module loaders
---@type Table<string, ModuleLoader>
---Note: not declared as local because it should persist
modLoaders = {}


---Table to hold all the modules
---@type Table<string, Module>
-- not declared as local because it should persist
modules = {}


---Iterate over all entries in the config => modules entry of the ucp-config file
for k, v in pairs(config.modules) do
  if v.active then
    print("loading module: " .. k .. " version: " .. v.version)
    modLoaders[k] = mod.ModuleLoader:new(k, v.version, v.config)
    -- load the init.lua file of the module
    modLoaders[k]:load()
    modules[k] = modLoaders[k].handle
  end
end


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


---Enable modules in the determined order
for k, m in pairs(loadOrder) do 
  -- call the enable() function of the module
  if m ~= "lua_api" then
    print("enabling module: " .. m)
    modLoaders[m]:enableModule(config)
  end
end