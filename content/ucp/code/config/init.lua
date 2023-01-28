local config = {}

config.utils = require('config.utils')

config.ConfigHandler = {
    loadDefaultConfig = function() 
        local f, message = io.open(CONFIG_DEFAULTS_FILE)
        if not f then
            log(WARNING, "[main]: Could not read '" .. CONFIG_DEFAULTS_FILE .. "'.yml. Reason: " .. message)
            log(WARNING, "[main]: Treating '" .. CONFIG_DEFAULTS_FILE .. "' as empty file")
            return { modules = {} }
        end
        local data = f:read("*all")
        f:close()
    
        local result, err = yaml.eval(data)
        if not result then
            log(ERROR, "failed to parse '" .. CONFIG_DEFAULTS_FILE .. "':\n" .. err)
        end
        if not result.plugins then result.plugins = {} end
        if not result.modules then result.modules = {} end
        if not result.order then result.order = {} end
        return result 
    end,

    loadUserConfig = function()
        local f, message = io.open(CONFIG_FILE)
        if not f then
            log(WARNING, "[main]: Could not read ucp-config.yml. Reason: " .. message)
            log(WARNING, "[main]: Treating ucp-config.yml as empty file")
            return { modules = {}, plugins = {} }
        end
        local data = f:read("*all")
        f:close()
    
        local result, err = yaml.eval(data)
        if not result then
            log(ERROR, "failed to parse ucp-config.yml:\n" .. err)
        end
        if not result.plugins then result.plugins = {} end
        if not result.modules then result.modules = {} end
        return result
    end,

}


return config