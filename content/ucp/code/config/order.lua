
--- Temporarily put here
log(INFO, "[config/order]: solving load order")

extensionDependencies = {}
for name, ext in pairs(extensionLoaders) do
    extensionDependencies[name] = {}
    local deps = ext:dependencies()
    if deps then
        for k, dep in pairs(deps) do
            table.insert(extensionDependencies[name], dep.name)
        end
    end
end

extensionLoadOrder = {}
for k, exts in pairs(extensions.DependencySolver:new(extensionDependencies):solve()) do
    for l, ext in pairs(exts) do
        table.insert(extensionLoadOrder, ext)
    end
end

