local utils = {}


function utils.loadExtensionsFromFolder(extensionLoaders, folder, cls)
    ---Dynamic extensions discovery
    local subFolders, err = table.pack(ucp.internal.listDirectories(BASEDIR .. "/" .. folder))

	if not subFolders then
		log(ERROR, "no subfolders detected for path: " .. BASEDIR .. "/" .. folder)
		error(err)
	end

    --- Create a loader for all extensions we can find
    for k, subFolder in ipairs(subFolders) do
		if subFolder:sub(-1) == "/" then
			subFolder = subFolder:sub(1, -2)
		end
		if subFolder:match("(-[0-9\\.]+)$") == nil then error("invalid extension folder name: " .. subFolder) end
        local version = subFolder:match("(-[0-9\\.]+)$"):sub(2)
        local name = subFolder:sub(1, string.len(subFolder)-(string.len(version)+1)):match("[/\\]*([a-zA-Z0-9-]+)$")

        log(INFO, "[main]: Creating extension loader for: " .. name .. " version: " .. version)

        if extensionLoaders[name] ~= nil then error("extension with name already exists: " .. name) end

        extensionLoaders[name] = cls:create(name, version)
        extensionLoaders[name]:verifyVersion()
    end
end

return utils