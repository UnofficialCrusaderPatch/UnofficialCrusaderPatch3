
local namespace = {}

local overrides = require('overrides')
-- local maps = require('maps')

return {
    enable = function(self, config)
        -- maps.enable(config)
        overrides.enable(config)
    end,
    disable = function(self, config)
    end,
    overrideFileWith = function(self, file, newFile)
        overrides.overrideFileWith(file, newFile)
    end,
    registerOverrideFunction = function(self, func)
        overrides.registerOverrideFunction(func)
    end
}