---@module extensions
local extensions = {}

extensions.utils = require("extensions.utils")
extensions.dependencies = require('extensions.dependencies')
extensions.loader = require('extensions.loader')
extensions.environment = require('extensions.environment')
extensions.proxies = require('extensions.proxies')

extensions.ModuleLoader = extensions.loader.ModuleLoader
extensions.PluginLoader = extensions.loader.PluginLoader
extensions.DependencySolver = extensions.dependencies.DependencySolver
extensions.ReadOnlyTable = extensions.utils.ReadOnlyTable
extensions.createRecursiveReadOnlyTable = extensions.utils.createRecursiveReadOnlyTable

return extensions
