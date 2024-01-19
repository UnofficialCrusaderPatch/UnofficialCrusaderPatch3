local config = {}

config.utils = require('config.utils')
config.matcher = require("config.matcher")
config.merger = require('config.merger')

local checkKey = function(config, name)
  if config[name] == nil then
    log(ERROR, "[config/init]: config is missing key: '" .. name .. "'")
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

        if contents["value"] ~= nil then
          value = contents["value"]
        elseif contents["required-value"] ~= nil then
          value = contents["required-value"]
        elseif contents["suggested-value"] ~= nil then
          value = contents["suggested-value"]
        end
        
        config[k] = value -- this is allowed in lua as long as k already existed in config
      else
        log(ERROR, "[config/init]: config file specified 'contents' in an illegal way, expected a value of type table, but received: '" .. tostring(v) .. "'")
      end
    end

  end
end

config.ConfigHandler = {
    loadDefaultConfig = function() 
        local f, message = io.open(CONFIG_DEFAULTS_FILE)
        if not f then
            log(WARNING, "[config/init]: Could not read '" .. CONFIG_DEFAULTS_FILE .. "'.yml. Reason: " .. message)
            log(WARNING, "[config/init]: Treating '" .. CONFIG_DEFAULTS_FILE .. "' as empty file")
            return { ['meta'] = {['version'] = '1.0.0'}, active = true, ['config-full'] = { modules = {}, plugins = {}, ['load-order'] = {}, }, ['config-sparse'] = { modules = {}, plugins = {}, ['load-order'] = {}, }, }
        end
        local data = f:read("*all")
        f:close()
    
        local result, err = yaml.eval(data)
        if not result then
            log(ERROR, "[config/init]: failed to parse '" .. CONFIG_DEFAULTS_FILE .. "':\n" .. err)
        end
        if not result.plugins then result.plugins = {} end
        if not result.modules then result.modules = {} end
        return result 
    end,

    loadUserConfig = function()
        log(DEBUG, "[config/init]: opening user config file at path: " .. CONFIG_FILE)
        local f, message = io.open(CONFIG_FILE)
        if not f then
            log(WARNING, "[config/init]: Could not read ucp-config.yml. Reason: " .. message)
            log(WARNING, "[config/init]: Treating ucp-config.yml as empty file")
            return { ['meta'] = {['version'] = '1.0.0'}, active = true, ['config-full'] = { modules = {}, plugins = {}, ['load-order'] = {}, }, ['config-sparse'] = { modules = {}, plugins = {}, ['load-order'] = {}, }, }
        end
        local data = f:read("*all")
        f:close()
    
        local result, err = yaml.eval(data)
        if not result then
            log(ERROR, "[config/init]: failed to parse ucp-config.yml:\n" .. err)
        end

        return result
    end,



    validateUserConfig = function(config)
      -- checkKey(config, 'specification-version')
      checkKey(config, 'active')
      if config['specification-version'] == '1.0.0' or (config['meta'] ~= nil and config['meta']['version'] == '1.0.0') or config['specification-version'] == nil then
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
        log(ERROR, "[config/init]: config specified an unknown 'meta.version': " .. tostring((config['meta'] or {['version'] = 'unknown'}).version))
      end

    end,

    normalizeContentsValues = normalizeContentsValues,

}


return config
