#include <string>
#include <filesystem>
#include "Core.h"

#ifdef COMPILED_MODULES
#include "CompiledLua.h"
#endif

std::string UCP_DIR = "ucp/";

int luaListDirectories(lua_State* L) {
	std::string path = luaL_checkstring(L, 1);
	if (path.empty()) return luaL_error(L, ("Invalid path: " + path).c_str());
	if(path.find("..") != std::string::npos) return luaL_error(L, ("Illegal path: " + path).c_str());

	int count = 0;

	try {
		for (const auto& entry : std::filesystem::directory_iterator(path)) {
			if (entry.is_directory()) {
				lua_pushstring(L, entry.path().lexically_relative(std::filesystem::current_path()).string().c_str());
				count += 1;
			}
		}
	}
	catch (std::filesystem::filesystem_error e) {
		return luaL_error(L, ("Cannot find the path: " + e.path1().string()).c_str());
	}
		
	return count;
}

void addUtilityFunctions(lua_State* L) {
	// Put the 'ucp.internal' on the stack
	lua_getglobal(L, "ucp"); // [ucp]
	lua_getfield(L, -1, "internal"); // [ucp, internal]

	lua_pushcfunction(L, luaListDirectories); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "listDirectories"); // [ucp, internal]

	lua_pop(L, 2); // pop table "internal" and pop table "ucp": []
}

void Core::initialize() {

	initializeConsole();

	RPS_initializeLua();
	RPS_initializeCodeHeap();
	RPS_initializePrintRedirect();

	//RPS_initializeLuaOpenBase();
	RPS_initializeLuaOpenLibs();
	// TODO: implement restrictions here? Or only in lua via lua sandboxes?
	//luaL_requiref(RPS_getLuaState(), LUA_LOADLIBNAME, luaopen_package, true);
	//luaL_requiref(RPS_getLuaState(), LUA_MATHLIBNAME, luaopen_math, true);
	//luaL_requiref(RPS_getLuaState(), LUA_STRLIBNAME, luaopen_string, true);
	//luaL_requiref(RPS_getLuaState(), LUA_TABLIBNAME, luaopen_table, true);
	//luaL_requiref(RPS_getLuaState(), LUA_IOLIBNAME, luaopen_io, true);

	lua_newtable(RPS_getLuaState());
	RPS_initializeLuaAPI("");
	// The namespace is left on the stack. 

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(RPS_getLuaState(), -2, "internal");
	// Our table is left on the stack. Put the table in the global 'ucp' variable.
	lua_setglobal(RPS_getLuaState(), "ucp");

	addUtilityFunctions(RPS_getLuaState());


#ifdef COMPILED_MODULES
	CompiledModules::registerProxyFunctions();
	CompiledModules::runCompiledModule("ucp/main.lua");
#else

	/**
	 * Allow UCP_DIR configuration via the command line.
	 *
	 */
	std::string ENV_UCP_DIR = std::getenv("UCP_DIR");
	if (!ENV_UCP_DIR.empty()) {
		UCP_DIR = ENV_UCP_DIR;
		if (UCP_DIR.back() != '\\' && UCP_DIR.back() != '/') {
			UCP_DIR = UCP_DIR + "/";
		}
	}

	RPS_runBootstrapFile(UCP_DIR + "main.lua");
#endif
	
	consoleThread = CreateThread(nullptr, 0, (LPTHREAD_START_ROUTINE)ConsoleThread, NULL, 0, nullptr);

	if (consoleThread == INVALID_HANDLE_VALUE) {
		MessageBoxA(NULL, std::string("Could not start thread").c_str(), std::string("...").c_str(), MB_OK);
	}
	else if (consoleThread == 0) {
		MessageBoxA(NULL, std::string("Could not start thread").c_str(), std::string("...").c_str(), MB_OK);
	}
	else {
		CloseHandle(consoleThread);
	}

}
