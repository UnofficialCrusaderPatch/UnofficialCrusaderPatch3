
BASEDIR = "ucp"
UCP_DIR = os.getenv("UCP_DIR")

if UCP_DIR then
  print("Setting UCP_DIR to " .. UCP_DIR)
  BASEDIR = UCP_DIR .. "/" .. "ucp"
end


DEBUG = true
API_VERSION = "1.0.0"
UCP_VERSION = "3.0.0"

---Indicates where to load UCP lua files from
package.path = BASEDIR .. "/?.lua"
core = require 'core'
utils = require 'utils'
data = {}
data.common = require 'data.common'
data.structures = require 'data.structures'
yaml = require 'ext.yaml.yaml'
json = require 'ext.json.json'
mod = require('module')
sha = require("ext.pure_lua_SHA.sha2")
hooks = require('hooks')

-- not yet declared as local because it is convenient to access in the console
config = (function()
  local f, message = io.open(BASEDIR .. "/../ucp-config.yml")
  if not f then error(message) end
  local data = f:read("*all")
  f:close()
  
  return yaml.eval(data)
end)()

-- not declared as local because it should persist
modLoaders = {}

-- not declared as local because it should persist
modules = {}

for k, v in pairs(config.modules) do
  if v.active then
    print("loading module: " .. k .. " version: " .. v.version)
    modLoaders[k] = mod.ModuleLoader:new(k, v.version, v.config)
    -- load the init.lua file of the module
    modLoaders[k]:load()
    modules[k] = modLoaders[k].handle
  end
end

-- TODO: implement a check for module version conflicts.

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

for k, m in pairs(loadOrder) do 
  -- call the enable() function of the module
  if m ~= "lua_api" then
    print("enabling module: " .. m)
    modLoaders[m]:enableModule(config)
  end
end

if config.modules.version then
  if config.modules.version.active then

  end
end