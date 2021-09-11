/*****************************************************************//**
 * \file   InternalData.cpp
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 *********************************************************************/

#include "InternalData.h"

namespace LuaIO {
	const std::map<std::string, std::string> internalData = {
		//Literal data will go here.
		{"ucp/code/pre.lua", 
R"V0G0N(
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
	local func = load(contents, sanitizedPath, "t", _G)
	local status, result = pcall(func)

	if not status then
		error(result)
	end

	package.loaded[path] = result
	
	return result
end
)V0G0N"},
	};
}