
local changes = {}

return {

    enable = function(self, config)
    
        log(DEBUG, "loading ucp changes")
        
        for change, opts in pairs(config) do
          if opts.enabled and opts.enabled == true then
            changes[change] = require("port/" .. change)
          end
        end
        
        for name, change in pairs(changes) do
          log(DEBUG, "initializing: " .. name)
          change:init(config[name])
        end
        
        for name, change in pairs(changes) do
          log(DEBUG, "enabling: " .. name)
          change:enable(config[name])
        end

    end,

    disable = function(self, config)
        return false, "not implemented"
    end,

}



