local utils = {}

local data = require('data')

function utils.parseExtensionsFolder(folder)
    
---Dynamic extensions discovery
    local subFolders, err = table.pack(ucp.internal.listDirectories(BASEDIR .. "/" .. folder))

	if not subFolders then
		log(ERROR, "no subfolders detected for path: " .. BASEDIR .. "/" .. folder)
		error(err)
	end

    local result = {}

    --- Create a loader for all extensions we can find
    for k, subFolder in ipairs(subFolders) do
		if subFolder:sub(-1) == "/" then
			subFolder = subFolder:sub(1, -2)
		end
		if subFolder:match("(-[0-9\\.]+)$") == nil then error("invalid extension folder name: " .. subFolder) end
        local version = subFolder:match("(-[0-9\\.]+)$"):sub(2)
        local name = subFolder:sub(1, string.len(subFolder)-(string.len(version)+1)):match("[/\\]*([a-zA-Z0-9-]+)$")

        local fullName = name .. "-" .. version

        table.insert(result, { name = name, version = version, fullName = fullName, fullPath = BASEDIR .. "/" .. folder .. "/" .. subFolder,})
     end

     return result
end

function utils.loadExtensionFromFolder(name, version, cls)
    return cls:create(name, version)
end

function utils.loadExtensionsFromFolder(extensionLoaders, folder, cls)

    for k, parsedSubFolder in ipairs(utils.parseExtensionsFolder(folder)) do
        local name = parsedSubFolder.name
        local version = parsedSubFolder.version
        local fullName = parsedSubFolder.fullName

        log(INFO, "[main]: Creating extension loader for: " .. name .. " version: " .. version)


        if extensionLoaders[fullName] ~= nil then 
            log(WARNING, "extension with name already exists: " .. name) 
        end

        local e = utils.loadExtensionFromFolder(name, version, cls)
        e:verifyVersion()

        extensionLoaders[fullName] = e
        

    end
end

return utils