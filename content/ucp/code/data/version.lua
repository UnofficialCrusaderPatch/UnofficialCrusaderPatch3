local namespace = {}

extensions = require('extensions')
version = require('version')

local versionToInt = function(versionString)
    local result = versionString:gsub("%.", "")
    return tonumber(result)
end

local scanForString = function(s)
    local targetBytes = table.pack(string.byte(s, 1, -1))
    local targetString = utils.bytesToAOBString(targetBytes)
    return core.AOBScan(targetString, 0x00400000, 0x00600000)
end

-- The digest is compared between PCs, so it must not depend on the locale: strings are compared
-- byte by byte (Lua's `<` uses strcoll) and numbers are not formatted as decimals.
local function lessBytes(a, b)
    for i = 1, math.min(#a, #b) do
        local x, y = a:byte(i), b:byte(i)
        if x ~= y then return x < y end
    end
    return #a < #b
end

-- Keys sort by type name, then by value.
local function compareKeys(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "boolean" then return (not a) and b end
    if ta == "string" then return lessBytes(a, b) end
    return a < b
end

-- Equal Lua numbers (90, 90.0) encode alike; other floats encode all 64 bits.
local function canonicalNumber(n)
    local integer = math.tointeger(n)
    if integer ~= nil then
        return "i" .. string.format("%d", integer)
    end
    return "f" .. (string.pack("<d", n):gsub(".", function(c) return string.format("%02x", c:byte()) end))
end

local function canonicalString(value)
    local t = type(value)
    if t == "table" then
        local keys = {}
        for k in pairs(value) do
            table.insert(keys, k)
        end
        table.sort(keys, compareKeys)

        local parts = {}
        for _, k in ipairs(keys) do
            table.insert(parts, canonicalString(k) .. "=" .. canonicalString(value[k]))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "number" then
        return canonicalNumber(value)
    elseif t == "boolean" then
        return tostring(value)
    end
    error(string.format("cannot include a value of type %s", t))
end

-- Framework release and full commit from ucp/ucp-version.yml.
local function frameworkIdentity()
    local v = namespace.known_version
    if type(v) ~= "table" then return "" end
    return string.format("%s.%s.%s-%s", v.major, v.minor, v.patch, v.sha)
end

-- Digest of the framework version, the extensions in load order (name and version) and their
-- effective options. File contents are not included.
local computeSetupDigest = function(config, extensionsInOrder)
    local extensions = {}
    for i, ext in ipairs(extensionsInOrder) do
        local id = ext.name .. "-" .. ext.version
        -- ext:enable receives {} for an extension without a config entry
        extensions[i] = { id = id, options = config[id] or {} }
    end

    return sha.sha1(canonicalString({ framework = frameworkIdentity(), extensions = extensions }))
end

local UCP_VERSION_FILE_PATH = "ucp/ucp-version.yml"

namespace.initialize = function()
    local f, message = io.open(UCP_VERSION_FILE_PATH)
    if not f then
        print("[data/version]: Could not read '" .. UCP_VERSION_FILE_PATH .. "'. Reason: " .. message)
        namespace.known_version_string = ""
    else
        local data = f:read("*all")
        f:close()

        namespace.known_version = yaml.eval(data)        
        namespace.known_version_string = namespace.known_version.major  .. "." .. namespace.known_version.minor .. "." .. namespace.known_version.patch .. "-" .. namespace.known_version.sha:sub(1,5)
    end

	--- Scan memory for the original version string
    local vf = scanForString("V1.%d")
    if vf == nil then
        error()
    end
	namespace.original_version_string = core.readString(vf)
	
	--- Allocate space for our new version string, put in the original string for now
    namespace.custom_menu_version_space = core.allocate(64)
    local d = table.pack(string.byte(namespace.original_version_string, 1, -1))
    table.insert(d, 0)
    core.writeBytes(namespace.custom_menu_version_space, d)

	--- Create the search bytes to find the usage of this version string: push versionString
    local push_vf = { 0x68, table.unpack(utils.itob(vf)) }
    namespace.push_vf_address = core.AOBScan(utils.bytesToAOBString(push_vf))

    if namespace.push_vf_address == nil then
        error()
    end
    
	--- Find the minor version number by searching for: push number
	local vnumber_address = core.AOBScan("6A", namespace.push_vf_address - 20, namespace.push_vf_address)
    if vnumber_address == nil then
        error()
    end

	local minorVersion = core.readByte(vnumber_address + 1)

	--- Translates V1.%d to e.g. V1.41
	local oString = string.format(namespace.original_version_string, minorVersion)

	local start, stop, maj, min, patch, extreme = oString:find("V([0-9]+)[.]([0-9]+)[.]([0-9]+)-(E)")
	if not start then
		start, stop, maj, min, extreme = oString:find("V([0-9]+)[.]([0-9]+)-(E)")
		if not start then
			start, stop, maj, min, patch = oString:find("V([0-9]+)[.]([0-9]+)[.]([0-9]+)")
			if not start then
				start, stop, maj, min = oString:find("V([0-9]+)[.]([0-9]+)")	
				if not start then
					error("[data/version]: Cannot parse game version: " .. oString)
				end
			end
		end
	end

    namespace.game_version = { 
		["major"] = maj, 
		["minor"] = min,
		["patch"] = patch,
		["extreme"] = extreme,
	}

end

---@param config table the final configuration, per extension
---@param extensionsInOrder table the active extensions in load order
namespace.overwriteVersion = function(config, extensionsInOrder)
    core.writeCode(namespace.push_vf_address, { 0x68, table.unpack(utils.itob(namespace.custom_menu_version_space)) })

    local success, digest = pcall(computeSetupDigest, config, extensionsInOrder)
    if success then
        namespace.digest = digest
    else
        log(WARNING, "[data/version]: could not compute the setup digest: " .. tostring(digest))
        namespace.digest = nil
    end
    local shownDigest = namespace.digest and namespace.digest:sub(1, 6) or "??????"
    namespace.setMenuVersion(namespace.original_version_string .. " UCP " .. namespace.known_version_string .. " (" .. shownDigest .. ")")

    namespace.game_language = core.readInteger(core.AOBScan("83 c4 20 83 3d ? ? ? ? 04 be 10 00 00 00 ? ? be 11 00 00 00") + 5)
    namespace.afterGameInit = false

    hooks.registerHookCallback("afterInit", function()
                                namespace.afterGameInit = true
                                end)
end

-- The game's language index is the 0-based position of cr.tex group 6 text 0 in this list
-- (compared case-insensitively); any other name gets 0.
local GAME_LANGUAGES = { "english", "american", "german", "french", "italian", "spanish", "polish" }

-- cr.tex group 6 text 0 of editions whose name is not in English, and its language
local NATIVE_LANGUAGE_NAMES = { ["Русский"] = "russian" }

---Group 6 text 0 of cr.tex (UTF-16LE: 260 group offsets in characters, then the texts), as UTF-8.
---Nil when cr.tex cannot be read or the text is empty, outside the file or not terminated.
local function readCrTexLanguageName()
    local f = io.open("cr.tex", "rb")
    if f == nil then return nil end
    local data = f:read("a")
    f:close()
    if data == nil or #data < 1040 then return nil end

    local offset = string.unpack("<i4", data, 1 + 6 * 4)
    if offset < 0 then return nil end
    local chars = {}
    for i = 1041 + 2 * offset, #data - 1, 2 do
        local c = string.unpack("<I2", data, i)
        if c == 0 then
            if #chars == 0 then return nil end
            return table.concat(chars)
        end
        chars[#chars + 1] = utf8.char(c)
    end
    return nil
end

local otherLanguage

---The game language in lowercase: one of GAME_LANGUAGES, "russian", or cr.tex's own name for its language.
---Nil before afterInit (cr.tex is loaded later).
namespace.getGameLanguage = function()
    if not namespace.afterGameInit then
        return nil
    end
    local index = core.readInteger(namespace.game_language)
    if index ~= 0 then
        return GAME_LANGUAGES[1 + index]
    end
    if otherLanguage == nil then
        local name = readCrTexLanguageName() or "english"
        otherLanguage = NATIVE_LANGUAGE_NAMES[name] or name:lower()
    end
    return otherLanguage
end

---Checks if the .exe registers a custom font. Or uses gdi32.dll to get custom size of a font.
namespace.isNonEnglish = function()
    local t1 = scanForString("CreateFontA")
    local t2 = scanForString("GetTextExtentPoint32W")

    return t1 ~= nil or t2 ~= nil
end

namespace.assertEnglishVersion = function()
    if namespace.isNonEnglish() then
        error("[data/version]: This version is a non-English version")
    end
    if namespace.getGameLanguage() ~= "english" then
        error("[data/version]: This version is non english")
    end
    return true
end

namespace.isExtreme = function()
    -- local res = scanForString("frontend_main_extreme.tgx")
    -- return res ~= nil or namespace.game_version["extreme"] ~= nil
    return namespace.game_version["extreme"] ~= nil
end

namespace.getGameVersionMajor = function()
    return namespace.game_version["major"]
end

namespace.getGameVersionMinor = function()
    return namespace.game_version["minor"]
end

namespace.setMenuVersion = function(fstring)
    if fstring == nil then
        error()
    end
    local d = table.pack(string.byte(fstring, 1, -1))
    table.insert(d, 0) -- null termination
    if #d > 64 then
        error("[data/version]: too long")
    end
    core.writeBytes(namespace.custom_menu_version_space, d)
end

---The setup digest (40 hexadecimal digits) shown shortened in the main menu, or nil if it could not be computed.
---@return string|nil
namespace.getDigest = function()
    return namespace.digest
end

local COMPARATORS = {
    ["<"] = function(a, b) return a < b end,
    [">"] = function(a, b) return a > b end,
    ["<="] = function(a, b) return a <= b end,
    [">="] = function(a, b) return a >= b end,
    ["=="] = function(a, b) return a == b end,
}



namespace.verifyGameDependency = function(ext, extensionLoaders)
    local extension = extensionLoaders[ext]

    if extension:type() ~= "ModuleLoader" then return true end

    local isExtreme = namespace.isExtreme()
    local versionString = namespace.getGameVersionMajor() .. "." .. namespace.getGameVersionMinor()
    local gameName = "SHC"
    if isExtreme then
        gameName = gameName .. "E"
    end

    extension:loadDefinition()
    if not extension.definition or not extension.definition.game then
        error("[data/version]: cannot determine game dependency for: " .. ext)
    end

    for k, v in pairs(extension.definition.game) do
        local name, eq, version = v:match("([a-zA-Z0-9-_]+)([<>=]+)([0-9\\.]+)")
        if name == gameName then
            local comp = COMPARATORS[eq]
            if comp == nil then
                error("[data/version]: illegal comparator: " .. comp)
            end

            if comp(versionString, version) then
                return true
            end
        end
    end

    log(ERROR, "[data/version]: Dependency version conflict for extension \"" .. ext .. "\": does not work for game: \"" .. gameName .. "\" version " .. versionString)
    -- error("Game dependency check failed for \"" .. ext .. "\"")
    return false
end

-- Extension versioning logic
namespace.verifyDependencies = function(extension, extensionLoaders)
    local deps = extensionLoaders[extension]:dependencies()

    if deps == nil then return end

    for k, dep in pairs(deps) do
        local dependencyVersionDemanded = versionToInt(dep.version)
        local versionEqualityDemanded = dep.equality

        if extensionLoaders[dep.name] == nil then 
            log(ERROR, "[data/version]: Dependency not found: Extension " .. extension .. " requires module " .. dep.name) 
            error("[data/version]: Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        local dependencyVersion = versionToInt(extensionLoaders[dep.name].version)

        local versionConflict = true
        local comp = COMPARATORS[versionEqualityDemanded]
        if comp ~= nil then
            if comp(dependencyVersion, dependencyVersionDemanded) == true then
                versionConflict = false
            end
        else
            log(ERROR, "[data/version]: Version operator malformed inside definition.yml")
            error("[data/version]: Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        if versionConflict then
            log(ERROR, "[data/version]: Dependency version conflict for extension \"" .. extension .. "\": Demanded module \"" .. dep.name .. "\" version " .. versionEqualityDemanded .. " " .. dep.version .. ", found " .. extensionLoaders[dep.name].version)
            error("[data/version]: Dependency check failed for \"" .. extension .. "\"")
            return false
        end

    end
    
	return true
end

return namespace