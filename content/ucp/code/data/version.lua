local namespace = {}

extensions = require('extensions')

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

namespace.initialize = function(config)
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
    
    namespace.custom_menu_version_space = core.allocate(64)
    local d = table.pack(string.byte("V1.%d", 1, -1))
    table.insert(d, 0)
    core.writeBytes(namespace.custom_menu_version_space, d)

    local vf = scanForString("V1.%d")
    if vf == nil then
        error()
    end
    local push_vf = { 0x68, table.unpack(utils.itob(vf)) }
    if push_vf == nil then
        error()
    end
    namespace.push_vf_address = core.scanForAOB(utils.bytesToAOBString(push_vf))
    if namespace.push_vf_address == nil then
        error()
    end
    local vnumber_address = core.scanForAOB("6A", namespace.push_vf_address - 20, namespace.push_vf_address)
    if vnumber_address == nil then
        error()
    end

    namespace.game_version = { ["major"] = 1, ["minor"] = core.readByte(vnumber_address + 1) }

    core.writeCode(namespace.push_vf_address, { 0x68, table.unpack(utils.itob(namespace.custom_menu_version_space)) })

    namespace.digest = computeVersionString(config)
    namespace.setMenuVersion("V1.%d UCP " .. namespace.known_version_string .. " (" .. namespace.digest:sub(1, 6) .. ")")

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
    local res = scanForString("frontend_main_extreme.tgx")
    return res ~= nil
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

-- Extension versioning logic
namespace.verifyDependencies = function(extension, extensionLoaders)
    local deps = extensionLoaders[extension]:dependencies()

    if deps == nil then return end

    for k, dep in pairs(deps) do
        local dependencyVersionDemanded = versionToInt(dep.version)
        local versionEqualityDemanded = dep.equality

        if extensionLoaders[dep.name] == nil then 
            print("[ERROR] Dependency not found: Extension " .. extension .. " requires module " .. dep.name) 
            error("Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        local dependencyVersion = versionToInt(extensionLoaders[dep.name].version)

        local versionConflict = true
        if versionEqualityDemanded == "==" then
            if dependencyVersion == dependencyVersionDemanded then
                versionConflict = false
            end
        elseif versionEqualityDemanded == ">=" then
            if dependencyVersion >= dependencyVersionDemanded then
                versionConflict = false
            end
        elseif versionEqualityDemanded == "<=" then
            if dependencyVersion <= dependencyVersionDemanded then
                versionConflict = false
            end
        elseif versionEqualityDemanded == ">" then
            if dependencyVersion > dependencyVersionDemanded then
                versionConflict = false
            end
        elseif versionEqualityDemanded == "<" then
            if dependencyVersion < dependencyVersionDemanded then
                versionConflict = false
            end
        else
            print("[ERROR] Version operator malformed inside definition.yml")
            error("Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        if versionConflict then
            print("[ERROR] Dependency version conflict for extension \"" .. extension .. "\": Demanded module \"" .. dep.name .. "\" version " .. versionEqualityDemanded .. " " .. dep.version .. ", found " .. extensionLoaders[dep.name].version)
            error("Dependency check failed for \"" .. extension .. "\"")
            return false
        end

        return true
    end
end

return namespace