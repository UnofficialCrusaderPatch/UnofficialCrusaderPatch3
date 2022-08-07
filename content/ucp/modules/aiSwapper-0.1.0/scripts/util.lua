
-- returns new table containing the value references of the source, but with transformed keys
-- collisions in the transformed keys lead to overwrites
local function createTableWithTransformedKeys(source, transformer, recursive)
  local newTable = {}
  for key, value in pairs(source) do
    if recursive and type(value) == "table" then
      value = createTableWithTransformedKeys(value, transformer, recursive)
    end
    newTable[transformer(key)] = value
  end
  return newTable
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


local function getAiDataPath(root, aiName, dataPath)
  return string.format("%s/%s/%s", root, aiName, dataPath)
end

local function getAiDataPathWithLocale(root, aiName, locale, dataPath)
  if locale == nil then -- save against nil
    return getAiDataPath(root, aiName, dataPath)
  end
  return string.format("%s/%s/lang/%s/%s", root, aiName, locale, dataPath)
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
local function getPathForLocale(root, aiName, locale, dataPath)
  local localePath = getAiDataPathWithLocale(root, aiName, locale, dataPath)
  if doesFileExist(localePath) then
    return localePath
  else
    return getAiDataPath(root, aiName, dataPath)
  end
end

return {
  createTableWithTransformedKeys  = createTableWithTransformedKeys,
  containsValue                   = containsValue,
  getAiDataPath                   = getAiDataPath,
  getAiDataPathWithLocale         = getAiDataPathWithLocale,
  openFileForByteRead             = openFileForByteRead,
  doesFileExist                   = doesFileExist,
  loadByteDataFromFile            = loadByteDataFromFile,
  loadDataFromJSON                = loadDataFromJSON,
  getPathForLocale                = getPathForLocale,
}