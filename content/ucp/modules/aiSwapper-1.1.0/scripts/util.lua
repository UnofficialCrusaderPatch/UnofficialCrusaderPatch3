-- returns new table containing the value references of the source, but with transformed keys
-- collisions in the transformed keys lead to overwrites
-- "nil" returns for the key will not add the value to the new table
local function createTableWithTransformedKeys(source, transformer, recursive)
  local newTable = {}
  for key, value in pairs(source) do
    if recursive and type(value) == "table" then
      value = createTableWithTransformedKeys(value, transformer, recursive)
    end
    local newKey = transformer(key)
    if newKey then
      newTable[newKey] = value
    end
  end
  return newTable
end

local next = next -- apperantly faster due to local context
local function isTableEmpty(tableToCheck)
  return next(tableToCheck) == nil
end

-- source https://stackoverflow.com/a/33511163 (1. comment)
local function containsValue(tableToCheck, value)
  for key, val in pairs(tableToCheck) do
    if val == value then
      return true
    end
  end
  return false
end


local function getAiDataPath(root, dataPath)
  return string.format("%s/%s", root, dataPath)
end

local function getAiDataPathWithLocale(root, locale, dataPath)
  if locale == nil then -- save against nil
    return getAiDataPath(root, dataPath)
  end
  return string.format("%s/lang/%s/%s", root, locale, dataPath)
end


local function openFileForByteRead(path)
  local file, msg = io.open(path, "rb")
  if not file then
    return file, msg
  end
  return file
end

-- source: https://stackoverflow.com/a/4991602
local function doesFileExist(path)
  local file = openFileForByteRead(path)
  if file ~= nil then
    file:close()
    return true
  else
    return false
  end
end

local function loadByteDataFromFile(path)
  local file, msg = openFileForByteRead(path)
  if not file then
    return file, msg
  end
  local fileData = file:read("*all")
  file:close()
  return fileData
end

local function loadDataFromJSON(path)
  local data, msg = loadByteDataFromFile(path)
  if not data then
    return data, msg
  end

  local status, jsonOrErr = pcall(json.decode, json, data)
  if status then
    return jsonOrErr, nil
  else
    return nil, jsonOrErr
  end
end


-- checks locale path, else returns default
-- at the moment, the default language is also checked this way
local function getPathForLocale(root, locale, dataPath)
  local localePath = getAiDataPathWithLocale(root, locale, dataPath)
  if doesFileExist(localePath) then
    return localePath
  else
    return getAiDataPath(root, dataPath)
  end
end

-- TODO: one day refactor address getter to use this utils function (or put it into the core)
local function getAddress(aob, scriptIdentifier, errorMsg, modifierFunc)
  local address = core.AOBScan(aob, 0x400000)
  if address == nil then
    log(ERROR, string.format(errorMsg, scriptIdentifier))
    error(string.format("'%s' can not be initialized.", scriptIdentifier))
  end
  if modifierFunc == nil then
    return address;
  end
  return modifierFunc(address)
end


return {
  createTableWithTransformedKeys = createTableWithTransformedKeys,
  isTableEmpty                   = isTableEmpty,
  containsValue                  = containsValue,
  getAiDataPath                  = getAiDataPath,
  getAiDataPathWithLocale        = getAiDataPathWithLocale,
  openFileForByteRead            = openFileForByteRead,
  doesFileExist                  = doesFileExist,
  loadByteDataFromFile           = loadByteDataFromFile,
  loadDataFromJSON               = loadDataFromJSON,
  getPathForLocale               = getPathForLocale,
  getAddress                     = getAddress,
}
