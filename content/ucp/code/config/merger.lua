local namespace = {}

---Try to merge extension configurations with user 'config'

function namespace.compareConfiguration(c1, c2, conflicts, path)
    conflicts = conflicts or {}
    path = path or "/root"
    for k, v2 in pairs(c2) do
        if c1[k] ~= nil then
            ---k exists in c1 and c2, check if they clash
            local v1 = c1[k]
            if v1 ~= v2 then
                if type(v1) == "table" and type(v2) == "table" then
                  namespace.compareConfiguration(v1, v2, conflicts, path .. "/" .. k)
                else
                    table.insert(conflicts, {path = path .. "/" .. k, value1 = v1, value2 = v2})
                end
            end
        end
    end
    return conflicts
end

function namespace.mergeConfiguration(c1, c2)
    for k, v2 in pairs(c2) do
        if c1[k] ~= nil then
            ---k exists in c1 and c2, check if they clash
            local v1 = c1[k]
            if v1 ~= v2 then
                if type(v1) == "table" and type(v2) == "table" then
                  namespace.mergeConfiguration(v1, v2)
                elseif type(v1) ~= type(v2) then
                    error("[config/merger]: incompatible types in key: " .. k)
                else
                    c1[k] = v2
                end
            end
        else
            c1[k] = v2
        end
    end
end

function namespace.resolveToFinalConfig(extensions, master, slave)
    
  local configMaster = master
  local configSlave = slave


  for k, ext in pairs(extensions) do
      local extConfig = ext:config()
      local conflicts = namespace.compareConfiguration(configMaster, extConfig)
      if #conflicts > 0 then
          local msg = "[config/merger]: failed to merge configuration of user and: " .. ext .. ".\ndifferences: "
          for k2, conflict in pairs(conflicts) do
              msg = "\n\tpath: " .. conflict.path .. ", value 1" .. conflict.value1 .. ", " .. conflict.value2
          end
          error(msg)
      end
      namespace.mergeConfiguration(configMaster, extConfig)
  end

  ---Lastly, to get a complete config, override the defaults, ignore differences or conflicts
  namespace.mergeConfiguration(configSlave, configMaster)

  return configSlave
end

return namespace