
#include "CompiledLua.h"
#include "lua.hpp"
#include "RuntimePatchingSystem.h"
#include <iostream>
#include <algorithm>

namespace CompiledModules {

	int requireFunctionRef = -1;
	int loadFunctionRef = -1;


	int proxyRequire(lua_State* L) {
		if (lua_gettop(L) != 1) {
			return luaL_error(L, "'require' should be called with 4 arguments");
		}

		const char sep = '.';
		const char rep = '/';
		const std::string BASEDIR = "ucp";

		std::string rawFileName = lua_tostring(L, 1);
		std::string fileName = rawFileName;
		std::replace(fileName.begin(), fileName.end(), sep, rep);
		fileName = BASEDIR + rep + fileName + ".lua";

		//TODO: exclusion criterium for dll files?
		std::map<std::string, std::string>::const_iterator it = compiledModules.find(fileName);
		if (it == compiledModules.end()) {
			return luaL_error(L, ("file cannot be loaded: " + fileName).c_str());
		}

		if (luaL_loadbufferx(L, it->second.c_str(), it->second.size(), fileName.c_str(), "t") != LUA_OK) {
			std::string errorMsg = lua_tostring(L, -1);
			lua_pop(L, 1);
			return luaL_error(L, errorMsg.c_str());
		}

		// Only allow 1 return value
		if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
			std::string errorMsg = lua_tostring(L, -1);
			lua_pop(L, 1);
			return luaL_error(L, errorMsg.c_str());
		}

		// result is left on the stack, so we return

		return 1;
	}

	int proxyLoadfile(lua_State* L) {
		if (lua_gettop(L) != 3) {
			return luaL_error(L, "'loadfile' should be called with 3 arguments");
		}


		std::string fileName = lua_tostring(L, 1);
		std::string mode = lua_tostring(L, 2);

		std::map<std::string, std::string>::const_iterator it = compiledModules.find(fileName);
		if (it == compiledModules.end()) {
			return luaL_error(L, ("file cannot be loaded: " + fileName).c_str());
		}

		if (luaL_loadbufferx(L, it->second.c_str(), it->second.size(), fileName.c_str(), "t") != LUA_OK) {
			std::string errorMsg = lua_tostring(L, -1);
			lua_pop(L, 1);

			lua_pushnil(L);
			lua_pushstring(L, errorMsg.c_str());

			// return nil, errorMessage
			return 2;
		}

		// Push the environment to the top again.
		lua_pushvalue(L, 3);
		// Set the first upvalue of the loaded code to the environment.
		lua_setupvalue(L, -2, 1);
		
		// return result of loadbufferx
		return 1;
	}

	int luaInitializeProxyFunctions(lua_State* L) {

		int a = lua_gettop(L);

		lua_pushglobaltable(L);

		if (requireFunctionRef == -1) {
			if (lua_getglobal(L, "require") != LUA_TFUNCTION) {
				lua_pop(L, 1);
				lua_pop(L, 1);
				return luaL_error(L, "'require' not of type function");
			}
			requireFunctionRef = luaL_ref(L, LUA_REGISTRYINDEX);

			lua_pushcfunction(L, proxyRequire);
			lua_setfield(L, -2, "require");
		}

		if (loadFunctionRef == -1) {
			if (lua_getglobal(L, "loadfile") != LUA_TFUNCTION) {
				lua_pop(L, 1);
				lua_pop(L, 1);
				return luaL_error(L, "'loadfile' not of type function");
			}
			loadFunctionRef = luaL_ref(L, LUA_REGISTRYINDEX);

			lua_pushcfunction(L, proxyLoadfile);
			lua_setfield(L, -2, "loadfile");
		}

		lua_pop(L, 1);
		int b = lua_gettop(L);
		if (a != b) std::cout << "discrepancy in luaInitializeProxyFunctions: " << b - a << std::endl;

		return 0;
	}

	int luaDeinitializeProxyFunctions(lua_State* L) {

		lua_pushglobaltable(L);

		if (requireFunctionRef != -1) {
			lua_rawgeti(L, LUA_REGISTRYINDEX, requireFunctionRef);
			lua_setfield(L, -2, "require");
			requireFunctionRef = -1;
		}

		if (loadFunctionRef != -1) {
			lua_rawgeti(L, LUA_REGISTRYINDEX, loadFunctionRef);
			lua_setfield(L, -2, "loadfile");
			loadFunctionRef = -1;
		}

		lua_pop(L, 1);

		return 0;
	}

	void registerProxyFunctions() {
		luaInitializeProxyFunctions(RPS_getLuaState());
		//lua_register(RPS_getLuaState(), "initializeProxyFunctions", luaInitializeProxyFunctions);
		//lua_register(RPS_getLuaState(), "deinitializeProxyFunctions", luaDeinitializeProxyFunctions);
	}

	void runCompiledModule(std::string name) {
		std::map<std::string, std::string>::const_iterator it = CompiledModules::compiledModules.find(name);
		if (it == CompiledModules::compiledModules.end()) throw "no ucp/api.lua in memory";
		luaL_loadbufferx(RPS_getLuaState(), it->second.c_str(), it->second.size(), "ucp/api.lua", "t");
		if (lua_pcall(RPS_getLuaState(), 0, 0, 0) != LUA_OK) {
			std::string errorMsg = lua_tostring(RPS_getLuaState(), -1);
			lua_pop(RPS_getLuaState(), 1);
			std::cout << errorMsg << std::endl;
		};
	}

	

}