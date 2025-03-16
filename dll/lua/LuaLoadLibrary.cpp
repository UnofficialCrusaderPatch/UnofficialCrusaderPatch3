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

int luaL_getsubtable(lua_State* L, int idx, const char* fname) {
	if (lua_getfield(L, idx, fname) == LUA_TTABLE)
		return 1;  /* table already there */
	else {
		lua_pop(L, 1);  /* remove previous result */
		idx = lua_absindex(L, idx);
		lua_newtable(L);
		lua_pushvalue(L, -1);  /* copy to be left at top */
		lua_setfield(L, idx, fname);  /* assign new table to field */
		return 0;  /* false, because did not find table there */
	}
}

#define LUA_LOADED_TABLE        "_LOADED"

void luaL_requiref(lua_State* L, const char* modname,
	lua_CFunction openf, int glb) {
	luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
	lua_getfield(L, -1, modname);  /* LOADED[modname] */
	if (!lua_toboolean(L, -1)) {  /* package not already loaded? */
		lua_pop(L, 1);  /* remove field */
		lua_pushcfunction(L, openf);
		lua_pushstring(L, modname);  /* argument to open function */
		lua_call(L, 1, 1);  /* call 'openf' to open module */
		lua_pushvalue(L, -1);  /* make copy of module (call result) */
		lua_setfield(L, -3, modname);  /* LOADED[modname] = module */
	}
	lua_remove(L, -2);  /* remove LOADED table */
	if (glb) {
		lua_pushvalue(L, -1);  /* copy of module */
		lua_setglobal(L, modname);  /* _G[modname] = module */
	}
}

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

			// Untested for luajit
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