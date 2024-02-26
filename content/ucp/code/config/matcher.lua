local version = require('version')

local matcher = {}

---@param extensions table<string, BaseLoader> extensions
---@param requirement string requirement string
function matcher.findMatchForExtensionRequirement(extensions, requirementString)
  local req = version.VersionRequirement:fromString(requirementString)
  local m
  log(DEBUG, "[config/matcher]: finding extension for requirement: " .. requirementString)
  for extensionName, extensionObject in pairs(extensions) do
      if extensionObject.name == req.name then
          if req.equality == "==" then
              if version.SemanticVersion:fromString(extensionObject.version):compare(req.version) == 0 then
                  m = extensionObject
              end
          elseif req.equality == ">" then
              if version.SemanticVersion:fromString(extensionObject.version):compare(req.version) > 0 then
                  if m == nil then
                      m = extensionObject
                  else
                      if
                          version.SemanticVersion:fromString(extensionObject.version):compare(
                              version.SemanticVersion:fromString(m.version)
                          ) > 0
                       then
                          m = extensionObject
                      end
                  end
              end
          elseif req.equality == ">=" then
              local comp = version.SemanticVersion:fromString(extensionObject.version):compare(req.version)
              if comp == 0 or comp == 1 then
                  if m == nil then
                      m = extensionObject
                  else
                      if
                          version.SemanticVersion:fromString(extensionObject.version):compare(
                              version.SemanticVersion:fromString(m.version)
                          ) > 0
                       then
                          m = extensionObject
                      end
                  end
              end
          end
      end
  end

  if m ~= nil then
    log(DEBUG, "[config/matcher]: found required extension: " .. m.name)
  end

  return m
end


---@param extensions table<string, BaseLoader> extensions
---@param requirement string requirement string
function matcher.findPreMatchForExtensionRequirement(preExtensions, requirement)

  local requirementString, req
  if type(requirement) == "string" then
    requirementString = requirement
    req = version.VersionRequirement:fromString(requirementString)
  elseif type(requirement) == "table" then
    requirementString = string.format("%s %s %s", requirement.extension, '==', requirement.version)
    req = version.VersionRequirement:new(requirement.extension, '==', requirement.version)
  else
    error("error during finding extension for requirement")
  end

  local m
  log(DEBUG, "[config/matcher]: finding extension for requirement: " .. requirementString)
  for k, preExtension in pairs(preExtensions) do
      if preExtension.name == req.name then
          if req.equality == "==" then
              if version.SemanticVersion:fromString(preExtension.version):compare(req.version) == 0 then
                  m = preExtension
              end
          elseif req.equality == ">" then
              if version.SemanticVersion:fromString(preExtension.version):compare(req.version) > 0 then
                  if m == nil then
                      m = preExtension
                  else
                      if
                          version.SemanticVersion:fromString(preExtension.version):compare(
                              version.SemanticVersion:fromString(m.version)
                          ) > 0
                       then
                          m = preExtension
                      end
                  end
              end
          elseif req.equality == ">=" then
              local comp = version.SemanticVersion:fromString(preExtension.version):compare(req.version)
              if comp == 0 or comp == 1 then
                  if m == nil then
                      m = preExtension
                  else
                      if
                          version.SemanticVersion:fromString(preExtension.version):compare(
                              version.SemanticVersion:fromString(m.version)
                          ) > 0
                       then
                          m = preExtension
                      end
                  end
              end
          end
      end
  end

  if m ~= nil then
    log(DEBUG, "[config/matcher]: found required extension: " .. m.name)
  end

  return m
end


return matcher