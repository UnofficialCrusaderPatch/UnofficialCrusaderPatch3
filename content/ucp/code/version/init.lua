local version = {}

function string.split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function extractSemVerNumbers(v) 
    local result = {}
    local components = string.split(v, ".")
    result['major'] = tonumber(components[1])
    result['minor'] = tonumber(components[2])
    result['patch'] = tonumber(components[3])
    return result
end


---Compares two semantic version strings and returns which one is larger
---@param a string version string A
---@param b string version string B
---@return number Returns the result
version.compareSemanticVersions = function(semVerA, semVerB)

    if semVerA.major > semVerB.major then
        return 1
    end

    if semVerA.major < semVerB.major then
        return -1
    end

    if semVerA.minor > semVerB.minor then
        return 1
    end

    if semVerA.minor < semVerB.minor then
        return -1
    end

    if semVerA.patch > semVerB.patch then
        return 1
    end

    if semVerA.patch < semVerB.patch then
        return -1
    end

    return 0

end

version.SemanticVersion = {

    new = function(self, major, minor, patch) 
        local o = setmetatable({
            major = major or 0,
            minor = minor or 0,
            patch = patch or 0,
        }, {__index = self})

        return o
    end,

    fromString = function(self, versionString)
        local parts = string.split(versionString, ".")
        return self:new(parts[1], parts[2], parts[3])
    end,

    compare = function(self, other) 
        return version.compareSemanticVersions(self, other)
    end,

}

version.VersionRequirement = {

    fromString = function(self, requirementString)

        local name, eq, versionString = requirementString:match("^([a-zA-Z0-9-_]+) *([<>=]+) *([0-9\\.]+)$")

        if name == nil then error("not a valid requirement string: " .. tostring(requirementString) .. "\n\texpected form 'module-name == version'") end

        local o = setmetatable({
            name = name,
            equality = eq,
            version = version.SemanticVersion:fromString(versionString),
        }, {__index = self})

        return o

    end,
}

return version