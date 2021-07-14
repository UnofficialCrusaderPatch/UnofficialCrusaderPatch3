#include <string>
#include "Core.h"

#ifdef COMPILED_MODULES
#include "CompiledLua.h"
#endif

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
	// The namespace is left on the stack. Set the namespace to the 'internal' field in our table.
	lua_setfield(RPS_getLuaState(), -2, "internal");
	// Our table is left on the stack. Put the table in the global 'ucp' variable.
	lua_setglobal(RPS_getLuaState(), "ucp");

#ifdef COMPILED_MODULES
	CompiledModules::registerProxyFunctions();
	CompiledModules::runCompiledModule("ucp/api.lua");
#else
	RPS_runBootstrapFile("ucp/api.lua");
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
