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

#include "LuaIO.h"


namespace LuaIO {

	// When calling this in lua: the first argument should be a table with byte values in it (UTF16 characters, every two bytes being a single character)
	int luaWideCharToMultiByte(lua_State* L)
	{
		luaL_checktype(L, 1, LUA_TTABLE); // check if the first argument is a table
		int size = lua_rawlen(L, 1); // size of the table
		std::string buffer(size, 0);

		for (int i = 0; i < size; i++) {
			lua_rawgeti(L, -1, (i + 1)); // note: lua is 1-based. Pushes the value on the stack
			char value = (char)lua_tointeger(L, -1); // get the value into C++
			buffer[i] = value;
			lua_pop(L, 1); // pop the value from the stack, leaving the table on the stack for the next iteration.
		}

		int size_needed = WideCharToMultiByte(CP_UTF8, 0, (LPCWCH) &buffer[0], size/2, NULL, 0, NULL, NULL);
		std::string strTo(size_needed, 0);
		WideCharToMultiByte(CP_UTF8, 0, (LPCWCH) &buffer[0], size/2, &strTo[0], size_needed, NULL, NULL);

		lua_pushstring(L, strTo.c_str());
		return 1;
	}

	//This function was taken from: https://stackoverflow.com/a/2072890
	inline bool ends_with(std::string const& value, std::string const& ending)
	{
		if (ending.size() > value.size()) return false;
		return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
	}


	FARPROC loadFunctionFromDLL(HMODULE handle, std::string name) {
		return GetProcAddress(handle, name.c_str());
	}

	HMODULE loadDLL(std::string path) {
		return LoadLibraryA(path.c_str());
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



		std::string extension;
		std::string insideExtensionPath;

		if (Core::getInstance().pathIsInModule(sanitizedPath, extension, insideExtensionPath)) {

			if (Core::getInstance().modulesZipMap.count(extension) == 1) {

				zip_t* z = Core::getInstance().modulesZipMap.at(extension);


				void* handle = (void*)loadDLLFromZip(insideExtensionPath, z);
				if (handle == NULL) {
					return luaL_error(L, ("Cannot load library: " + sanitizedPath).c_str());
				}

				lua_CFunction func = (lua_CFunction)loadFunctionFromMemoryDLL(handle, "luaopen_" + modName);
				if (func == NULL) {
					return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
				}

				luaL_requiref(L, modName.c_str(), func, 0);

				return 1;
			}
			else if (Core::getInstance().modulesDirMap.count(extension) == 1) {
				if (!Core::getInstance().modulesDirMap.at(extension)) {
					return luaL_error(L, ("Unexpected error when reading: " + sanitizedPath).c_str());
				}

				// Pass through!

			}
			else {
				lua_pushnil(L);
				lua_pushstring(L, ("file does not exist because extension does not exist: " + sanitizedPath).c_str());
				return 2;
			}


		}


#ifdef COMPILED_MODULES
		//if pointing to the ucp directory, use the UCP_DIR variable, "ucp/" is special
		if (sanitizedPath.rfind("ucp/", 0) == 0) {

			if ((sanitizedPath.rfind("ucp/plugins/", 0) == 0)) {
				// Allowed, move on
				return luaL_error(L, "plugins cannot contain dll files");
			}
			else {
				// Read from memory: do routine and RETURN!

				void* handle = (void*) loadInternalDLL(sanitizedPath);
				if (handle == NULL) {
					return luaL_error(L, ("Cannot load library: " + sanitizedPath).c_str());
				}

				lua_CFunction func = (lua_CFunction) loadFunctionFromInternalDLL(sanitizedPath, "luaopen_" + modName);
				if (func == NULL) {
					return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
				}

				luaL_requiref(L, modName.c_str(), func, 0);
			
				return 1;
			}

		}
		else {
			return luaL_error(L, "Only allowed to open DLLs inside the ucp directory");
		}
#else



		std::filesystem::path fullPath;
		if (sanitizedPath.rfind("ucp/", 0) == 0) {
			fullPath = Core::getInstance().UCP_DIR / sanitizedPath.substr(4);
		}
		else {
			fullPath = Core::getInstance().UCP_DIR / sanitizedPath;
		}
		if (!std::filesystem::exists(fullPath)) {
			lua_pushnil(L);
			lua_pushstring(L, "file does not exist"); //error message. TODO: improve
			return 2;
		}

		std::filesystem::path stem = fullPath.stem();
		if (stem.string().rfind("-") != std::string::npos) {
			lua_pushnil(L);
			lua_pushstring(L, ("invalid dll file name: " + stem.string()).c_str());
			return 2;
		}

		HMODULE handle = loadDLL(fullPath.string());
		if (handle == NULL) {
			return luaL_error(L, ("Cannot load library: " + fullPath.string()).c_str());
		}

		lua_CFunction func = (lua_CFunction)loadFunctionFromDLL(handle, "luaopen_" + modName);
		if (func == NULL) {
			return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
		}

		luaL_requiref(L, modName.c_str(), func, 0); // store in package.loaded
		
		// copy of module is left on the stack, return it
		return 1;
#endif // COMPILED_MODULES			

	}





}