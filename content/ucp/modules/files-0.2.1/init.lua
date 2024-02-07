
local namespace = {}

local overrides = require('overrides')
local iteration = require('iteration')

return {
    enable = function(self, config)
        overrides.enable(config)
        iteration.enable(config)
    end,
    disable = function(self, config)
    end,
    overrideFileWith = function(self, file, newFile)
        overrides.overrideFileWith(file, newFile)
    end,
    registerOverrideFunction = function(self, func)
        overrides.registerOverrideFunction(func)
    end,
    setIterationOption = function(self, key, value)
        iteration.setOption(key, value)
    end,
}