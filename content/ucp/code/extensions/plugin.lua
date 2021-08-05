---@class Plugin
Plugin = {}

---When a plugin is enabled on start up, this function is run.
---@param userConfig table table of user configuration parameters for this plugin
function Plugin:enable(userConfig)
end
---When a module is disabled, this function is run.
function Plugin:disable(userConfig)
end
