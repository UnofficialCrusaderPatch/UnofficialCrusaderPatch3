---Temporarily put here

log(INFO, "[main]: verifying extension dependencies")
explicitlyActiveExtensions = {}
for k, ext in pairs(extensionLoadOrder) do
    log(DEBUG, ext)
    if joinedConfig.extensions[ext] then
        if joinedConfig.extensions[ext].active == true then
            if data.version.verifyDependencies(ext, extensionLoaders) then
                if data.version.verifyGameDependency(ext, extensionLoaders) then
                    table.insert(explicitlyActiveExtensions, ext)
                end
			end
        end
    elseif joinedDefaultConfig.extensions[ext] and joinedDefaultConfig.extensions[ext].active == true then
        if data.version.verifyDependencies(ext, extensionLoaders) then
            if data.version.verifyGameDependency(ext, extensionLoaders) then
                table.insert(explicitlyActiveExtensions, ext)
            end
        end
    end
end

log(DEBUG, "[main]: explicitly active extensions:\n" .. json:encode_pretty(explicitlyActiveExtensions))

necessaryDependencies = {}
for k, ext in pairs(explicitlyActiveExtensions) do
    for k2, dep in pairs(extensionDependencies[ext]) do
        if not table.find(necessaryDependencies, dep) then
            table.insert(necessaryDependencies, dep)
        end
    end
end

i = 1
while i <= #necessaryDependencies do
    local ext = necessaryDependencies[i]
    if ext then
        for k, dep in pairs(extensionDependencies[ext]) do
            if not table.find(necessaryDependencies, dep) then
                table.insert(necessaryDependencies, dep)
            end
        end
    end
    i = i + 1
end

log(DEBUG, "required dependencies:\n" .. json:encode_pretty(necessaryDependencies))