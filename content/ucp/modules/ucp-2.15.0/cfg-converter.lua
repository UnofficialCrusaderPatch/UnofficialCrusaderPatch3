local replace_patterns = {
    { target = [[\]], replace = [[\\]] },
    { target = "Path=(.-)\n", replace = [[Path="%1"]] .. "\n" },
    { target = "-", replace = "_" },
    { target = ";", replace = "," },
    { target = "False", replace = "false" },
    { target = "True", replace = "true" },
    { target = "[.]", replace = "_" },
    { target = "[}] ([^,}])", replace = "}, %1" },
    { target = "([a-zA-Z0-9_]+) ([a-zA-Z0-9_]+)", replace = "%1%2" }
}

local makeCFGLuaCompliant = function(data)
    if type(data) ~= "string" then
        error("'data' parameter is not of type string")
    end

    local result = data

    for k, replace_pattern in ipairs(replace_patterns) do
        result = result:gsub(replace_pattern.target, replace_pattern.replace)
    end

    return result
end

local getCFG = function(filepath)
    local handle, message = io.open(filepath, 'r')
    if not handle then
        error(message)
    end
    local data = handle:read("*all")
    handle:close()

    data = makeCFGLuaCompliant(data)

    local result = {}
    local func, message = load(data, filepath, 't', result)
    if not func then
        error(message)
    end

    local status, res = pcall(func)
    if not status then
        error(res)
    end

    return result
end

return {
    getCFG = getCFG,
}