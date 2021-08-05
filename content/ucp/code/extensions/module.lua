---@class Module
Module = {}

---When a module is enabled on start up, this function is run.
---@param userConfig table table of user configuration parameters for this module
function Module:enable(userConfig)
end
---When a module is disabled, this function is run.
function Module:disable(userConfig)
end
