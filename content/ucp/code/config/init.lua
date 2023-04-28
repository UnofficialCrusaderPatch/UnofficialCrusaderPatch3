local config = {}

config.utils = require('config.utils')
config.matcher = require("config.matcher")
config.merger = require('config.merger')

local checkKey = function(config, name)
  if config[name] == nil then
    log(ERROR, "config is missing key: '" .. name .. "'")
  end      
end

local normalizeContentsValues
normalizeContentsValues = function(config)
  --[[
    A:
      contents:
        suggested-value: 10

    # Should become:
    A: 10
  --]]
  for k, v in pairs(config) do

    if type(v) == "table" then
      local contents = v["contents"]
      
      if contents == nil then
        normalizeContentsValues(v)
      elseif type(contents) == "table" then
        local value = nil

        if contents["value"] then
          value = contents["value"]
        elseif contents["required-value"] then
          value = contents["required-value"]
        elseif contents["suggested-value"] then
          value = contents["suggested-value"]
        end
        
        config[k] = value -- this is allowed in lua as long as k already existed in config
      else
        log(ERROR, "config file specified 'contents' in an illegal way, expected a value of type table, but received: '" .. tostring(v) .. "'")
      end
    end

  end
end

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
        return result 
    end,

    loadUserConfig = function()
        log(DEBUG, "opening user config file at path: " .. CONFIG_FILE)
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

        return result
    end,



    validateUserConfig = function(config)
      checkKey(config, 'specification-version')
      checkKey(config, 'active')
      if config['specification-version'] == '1.0.0' then
        checkKey(config, 'config-sparse')
        checkKey(config, 'config-full')
        -- checkKey(config['config-full'], 'other-extensions-forbidden')
        -- checkKey(config['config-sparse'], 'other-extensions-forbidden')
        checkKey(config['config-full'], 'load-order')
        checkKey(config['config-sparse'], 'load-order')
        checkKey(config['config-full'], 'modules')
        checkKey(config['config-sparse'], 'modules')
        checkKey(config['config-full'], 'plugins')
        checkKey(config['config-sparse'], 'plugins')
      else
        log(ERROR, "config specified an unknown 'specification-version': " .. config['specification-version'])
      end

    end,

    normalizeContentsValues = normalizeContentsValues,

}


return config