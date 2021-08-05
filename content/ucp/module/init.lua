---@module module
local module = {}
module.utils = require("module.utils")
module.dependencies = require('module.dependencies')
module.loader = require('module.loader')
module.environment = require('module.environment')

---@class Module
Module = {}

---When a module is enabled on start up, this function is run.
---@param userConfig table table of user configuration parameters for this module
---@param config table table of all user configuration parameters
function Module:enable(userConfig, config)
end
---When a module is disabled, this function is run.
function Module:disable(userConfig, config)
end


module.ModuleLoader = module.loader.ModuleLoader
module.DependencySolver = module.dependencies.DependencySolver
module.ReadOnlyTable = module.utils.ReadOnlyTable
module.createRecursiveReadOnlyTable = module.utils.createRecursiveReadOnlyTable

return module
