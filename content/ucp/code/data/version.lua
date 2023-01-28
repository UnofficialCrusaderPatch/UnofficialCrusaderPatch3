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
    return core.scanForAOB(targetString, 0x00400000, 0x00600000)
end

local computeVersionString = function(config)

    local function dumpTableToDeterministicString(o)
        local res = ""
        local keys = {}
        for k, v in pairs(o) do
            table.insert(keys, k)
        end
        table.sort(keys)

        for k, key in pairs(keys) do
            local v = o[key]
            res = res .. key
            if type(v) == "table" then
                res = res .. dumpTableToDeterministicString(v)
            elseif type(v) == "function" then
                error()
            else
                res = res .. string.format("%s", v)
            end
        end
        return res
    end

    local mset = {}
    for k, v in pairs(config.modules) do
        if v.active then
            mset[k] = v
        end
    end
    local s = dumpTableToDeterministicString(mset)

    -- an indicator that shows the user a digest of the config for easy verification for multiplayer.
    local digest = sha.sha1(s)

    return digest
end

namespace.initialize = function()
    local f, message = io.open("ucp-version.yml")
    if not f then
        print("Could not read '" .. "ucp-version.yml" .. "'.yml. Reason: " .. message)
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
    namespace.push_vf_address = core.scanForAOB(utils.bytesToAOBString(push_vf))

    if namespace.push_vf_address == nil then
        error()
    end
    
	--- Find the minor version number by searching for: push number
	local vnumber_address = core.scanForAOB("6A", namespace.push_vf_address - 20, namespace.push_vf_address)
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
					error("Cannot parse game version: " .. oString)
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

namespace.overwriteVersion = function(config)
    core.writeCode(namespace.push_vf_address, { 0x68, table.unpack(utils.itob(namespace.custom_menu_version_space)) })

    namespace.digest = computeVersionString(config)
    namespace.setMenuVersion(namespace.original_version_string .. " UCP " .. namespace.known_version_string .. " (" .. namespace.digest:sub(1, 6) .. ")")

    namespace.game_language = core.readInteger(core.scanForAOB("83 c4 20 83 3d ? ? ? ? 04 be 10 00 00 00 ? ? be 11 00 00 00") + 5)
    namespace.afterGameInit = false

    hooks.registerHookCallback("afterInit", function()
                                namespace.afterGameInit = true
                                end)
end

---cr.tex is loaded later
namespace.getGameLanguage = function()
    if namespace.afterGameInit then
        local index = 1 + core.readInteger(namespace.game_language)
        local langs = { "english", "american", "german", "french", "italian", "SPANISH", "polish" }
        return langs[index]
    else
        return nil
    end
end

---Checks if the .exe registers a custom font. Or uses gdi32.dll to get custom size of a font.
namespace.isNonEnglish = function()
    local t1 = scanForString("CreateFontA")
    local t2 = scanForString("GetTextExtentPoint32W")

    return t1 ~= nil or t2 ~= nil
end

namespace.assertEnglishVersion = function()
    if namespace.isNonEnglish() then
        error("This version is a non-English version")
    end
    if namespace.getGameLanguage() ~= "english" then
        error("This version is non english")
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
        error("too long")
    end
    core.writeBytes(namespace.custom_menu_version_space, d)
end

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
        error("cannot determine game dependency for: " .. ext)
    end

    for k, v in pairs(extension.definition.game) do
        local name, eq, version = v:match("([a-zA-Z0-9-_]+)([<>=]+)([0-9\\.]+)")
        if name == gameName then
            local comp = COMPARATORS[eq]
            if comp == nil then
                error("illegal comparator: " .. comp)
            end

            if comp(versionString, version) then
                return true
            end
        end
    end

    log(ERROR, "Dependency version conflict for extension \"" .. ext .. "\": does not work for game: \"" .. gameName .. "\" version " .. versionString)
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
            log(ERROR, "Dependency not found: Extension " .. extension .. " requires module " .. dep.name) 
            error("Dependency check failed for \"" .. extension .. "\"")
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
            log(ERROR, "Version operator malformed inside definition.yml")
            error("Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        if versionConflict then
            log(ERROR, "Dependency version conflict for extension \"" .. extension .. "\": Demanded module \"" .. dep.name .. "\" version " .. versionEqualityDemanded .. " " .. dep.version .. ", found " .. extensionLoaders[dep.name].version)
            error("Dependency check failed for \"" .. extension .. "\"")
            return false
        end

    end
    
	return true
end

return namespace