-- lua glob logic

function sanitizePath(path)
  return path:gsub("\\+", "/")
end

UCP_EXTENSION_PLUGIN_QUERY = "ucp/plugins/"
UCP_EXTENSION_MODULE_QUERY = "ucp/modules/"


EXTNAME_GLOB_QUERY = "(([a-zA-Z0-9-]+)-([*]))$"
EXTNAME_FIXED_QUERY = "(([a-zA-Z0-9-]+)-([0-9]+[.][0-9]+[.][0-9]+))$"

function getExtPart(path)

  local start, finish = path:find(UCP_EXTENSION_PLUGIN_QUERY)

  if start == nil or finish == nil or start ~= 1 then

    start, finish = path:find(UCP_EXTENSION_MODULE_QUERY)

    if start == nil or finish == nil or start ~= 1 then
      return nil
    end
  end

  local second = path:sub(finish + 1)

  local sep = second:find("/")

  local extGlob = nil

  if sep == nil then
    extGlob = second
  else
    extGlob = second:sub(1, sep - 1)
  end

  local fullmatch, name, asterisk = (extGlob:gmatch(EXTNAME_GLOB_QUERY))()
  if fullmatch == nil then
    local fullmatch, name, version = (extGlob:gmatch(EXTNAME_FIXED_QUERY))()
    if fullmatch == nil then
      return nil
    end

    return {
      glob = false,
      name = name,
      version = version,
    }
  end

  return {
    glob = true,
    name = name,
  }
end

function resolve(path, extensions)

  local path = sanitizePath(path)

  local extPart = getExtPart(path)



end

local example1 = "ucp/plugins/plugin-name-4-*/files-folder-1.0.0/file1.txt"
local resolution1 = "ucp/plugins/plugin-name-4-0.0.1/files-folder-1.0.0/file1.txt"

if resolve(example1, activeExtensions) ~= resolution1 then
  error("failed!")
end