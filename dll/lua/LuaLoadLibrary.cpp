/*****************************************************************//**
 * \file   LuaIO.cpp
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 * 
 * The functions in this file exist to handle custom IO operations.
 * These custom IO operations are used to secure lua files from unwanted modification.
 * 
 * 
 * 
 *********************************************************************/



#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include "core/Core.h"
#include <regex>
#include "io/utils.h"

#include "LuaLoadLibrary.h"
#include "io/modules/ModuleManager.h"


namespace LuaIO {

	//This function was taken from: https://stackoverflow.com/a/2072890
	inline bool ends_with(std::string const& value, std::string const& ending)
	{
		if (ending.size() > value.size()) return false;
		return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
	}

	int luaLoadLibrary(lua_State* L) {
		//Read path from the stack (first argument)
		if (lua_gettop(L) != 2) {
			return luaL_error(L, "expected two arguments");
		}
		std::string rawPath = lua_tostring(L, 1);
		std::string modName = lua_tostring(L, 2);

		if (!std::regex_match(modName, std::regex("[a-zA-Z0-9_]+"))) {
			return luaL_error(L, "invalid module name");
		}

		std::string sanitizedPath;
		if (!sanitizeRelativePath(rawPath, sanitizedPath)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		if (!ends_with(sanitizedPath, ".dll")) {
			lua_pushnil(L);
			lua_pushstring(L, "path must end with '.dll'"); //error message
			return 2;
		}




		std::string insidePath;
		ModuleHandle* mh;
		if (Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, insidePath)) {

			try {
				mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
			}
			catch (ModuleHandleException e) {
				return luaL_error(L, e.what());
			}
		}
		else {

			std::string extension;
			std::string basePath;

			if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insidePath)) {
				try {
					mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
				}
				catch (ModuleHandleException e) {
					return luaL_error(L, e.what());
				}

			}
			else {
				return luaL_error(L, ("can only load libraries when in a module or shipped with ucp: " + sanitizedPath).c_str());
			}
		}

		try {
			void* handle = mh->loadLibrary(insidePath);
			if (handle == NULL) {
				return luaL_error(L, ("Cannot load library: " + sanitizedPath).c_str());
			}

			lua_CFunction func = (lua_CFunction)mh->loadFunctionFromLibrary(handle, "luaopen_" + modName);
			if (func == NULL) {
				return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
			}

			luaL_requiref(L, modName.c_str(), func, 0);

			return 1;
		}
		catch (ModuleHandleException e) {
			const DWORD err = GetLastError();

			lua_pushnil(L);
			lua_pushstring(L, ("Error loading DLL (error: " + std::to_string(err)  + ")" + ": " + sanitizedPath).c_str()); //error message
			return 2;
			//return luaL_error(L, e.what());
		}


	}





}