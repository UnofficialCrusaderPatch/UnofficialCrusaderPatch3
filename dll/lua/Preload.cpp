#include "Preload.h"

const std::string ucp_code_pre = R"V0G0N(
require = function(path)

       if package.loaded[path] then return package.loaded[path] end

       local sanitizedPath = "ucp/code/" .. path:gsub("[.]", "/")
       local filePath = sanitizedPath .. ".lua"
       local folderPath = sanitizedPath .. "/init.lua"

       local f, message = io.open(filePath, "r")
       if not f then
               f, message2 = io.open(folderPath, "r")
               if not f then
                       error(message .. "\n" .. message2)
               end
       end

       local contents = f:read("*all")
       local func, err = load(contents, sanitizedPath, "t", _G)
	   if not func then error(err) end

       local status, result = pcall(func)

       if not status then
               error(result)
       end

       package.loaded[path] = result

       return result
end

)V0G0N";