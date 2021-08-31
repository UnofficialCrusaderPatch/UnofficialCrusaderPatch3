
local namespace = {}

local overrides = require('overrides')
local iteration = require('iteration')

return {
    enable = function(self, config)
        iteration.enable(config)
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