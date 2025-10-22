---@type ucpiolib
local io = io

local _open = io._open
local USERDATA_SUBFOLDER = "ucp/userdata"

local _, pResourceManager = utils.AOBExtract("A1 I( ? ? ? ? ) 89 46 74 33 C0 39 ? ? ? ? ? 7E 16")
local pGetDocumentsFolderString = core.AOBScan("6A FF 68 ? ? ? ? 64 A1 00 00 00 00 50 83 EC 40 A1 ? ? ? ? 33 C4 89 44 24 3C 53 55 56 57 A1 ? ? ? ? 33 C4 50 8D 44 24 54 64 A3 00 00 00 00 8B 7C 24 64 33 DB 6A 15")

local pFree = core.AOBScan("6A 0C 68 ? ? ? ? E8 ? ? ? ? 8B 75 08")
local free = core.exposeCode(pFree, 1, 0)

local _getDocumentsFolderString = core.exposeCode(pGetDocumentsFolderString, 3, 1)

local addr = core.AOBScan("8D 44 24 ? 50 B9 ? ? ? ? E8 ? ? ? ? BE 10 00 00 00 39 70 18 72 05 8b 48 04 eb 03 8d 48 04 8d 94 24 ? ? ? ? 8b ff")
local StringSize = core.readByte(addr + 3) + 4

local ENSURED = false

local CONFIG = {
	location = "user", -- alternative is "ucp"
}

---@param key string
---@param value string?
local function configure(key, value)
	if value == nil then
		return CONFIG[key]
	end
	CONFIG[key] = value
end

local function cleanup(path)
	path = path:gsub("\\", "/")
	while path:sub(-1) == "/" do
		path = path:sub(1, -2)
	end
	return path
end

local function getCrusaderUserPath()
	if CONFIG.location == "ucp" then return "." end

	local StackString = core.allocateGarbageCollectedObject(StringSize)
	local pStackString = StackString.address
	local str = _getDocumentsFolderString(pResourceManager, pStackString, 1)
	local pString = str + 0x04
	local result
	if core.readInteger(str + (StringSize - 4)) > 0xF then
		pString = core.readInteger(pString)
		result = core.readString(pString)
		free(pString)
		return cleanup(result)
	end
	
	result = core.readString(pString)
	
	return cleanup(result)
end

local function getUserDataPath()
	local path = string.format("%s/%s", getCrusaderUserPath(), USERDATA_SUBFOLDER)

	if not ENSURED then
		ENSURED = true
		io.mkdir(path, true)
	end

	return path
end

---@param path string the to be sanitized path
---@return string sanitized path ending with '/' if "path" also ended with '/'
local function sanitizePath(path)
	local parts = {}
	for match in string.gmatch(path, "([^/]+)") do 
		local sanitized = match:match("^([a-zA-Z0-9.~-]+)$")
		if (not sanitized) or (sanitized:find("%.%.") ~= nil) then 
			error(string.format("malformed path: %s => '%s'", path, match))
		end
		table.insert(parts, sanitized)
	end
	local ending = ""
	if path:sub(-1) == "/" then
		ending = "/"
	end
	return table.concat(parts, "/") .. ending
end

local function getPathInUserDataFolder(path)
	local sanitized = sanitizePath(path)
	return string.format("%s/%s", getUserDataPath(), sanitized)
end

local INITIALIZED = false

hooks.registerHookCallback("afterInit", function()
	INITIALIZED = true
end)

---@param extensionName string
---@return fun():UserDataInterface
local function prepareExtensionInterface(extensionName)
	if type(extensionName) ~= "string" then error("invalid extension name") end

	return function() 

		if INITIALIZED == false then return nil end

		local base = getPathInUserDataFolder(extensionName)

		local status, err = io.mkdir(base, true)
		if not status then error(err) end

		local versionPath = getPathInUserDataFolder(string.format("%s/meta.json", extensionName))
		local handle, err = _open(versionPath, "r")
		if not handle then -- doesn't exist
			local writeHandle, err = _open(versionPath, "w")
			if not writeHandle then error(err) end
			writeHandle:write(json:encode({ version = "1.0.0", meta = { version = "1.0.0", } }))
			writeHandle:close()

			handle, err = _open(versionPath, "r")
			if not handle then error(err) end
		end
		local contents = handle:read("*all")
		local meta = json:decode(contents)


		---@type UserDataInterface
		local interface = {
			version = meta.version, -- contains the last known file format version for all the data in this extension folder
			setVersion = function(self, newVersion)
				local writeHandle, err = _open(versionPath, "w")
				if not writeHandle then error(err) end
				meta.version = newVersion
				writeHandle:write(json:encode(meta))
				writeHandle:close()
			end,
			open = function(self, path, ...)
				local sanitizedPath = getPathInUserDataFolder(string.format("%s/%s", extensionName, path))
				return _open(sanitizedPath, ...)
			end,
			mkdir = function(self, path, parents)
				return io.mkdir(getPathInUserDataFolder(string.format("%s/%s", extensionName, path)), parents)
			end,
			remove = function(self, path, recurse)
				return io.remove(getPathInUserDataFolder(string.format("%s/%s", extensionName, path)), recurse)
			end,
		}

		return interface
	end
end

return {
	getCrusaderUserPath = getCrusaderUserPath,
	getPathInUserDataFolder = getPathInUserDataFolder,
	prepareExtensionInterface = prepareExtensionInterface,
	configure = configure,
}
