#include <string>
#include <filesystem>
#include "Core.h"
#include "LuaIO.h"


void addUtilityFunctions(lua_State* L) {
	// Put the 'ucp.internal' on the stack
	lua_getglobal(L, "ucp"); // [ucp]
	lua_getfield(L, -1, "internal"); // [ucp, internal]

	lua_pushcfunction(L, LuaIO::luaListDirectories); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "listDirectories"); // [ucp, internal]

	lua_pushcfunction(L, LuaIO::luaWideCharToMultiByte);
	lua_setfield(L, -2, "WideCharToMultiByte");

	lua_pop(L, 2); // pop table "internal" and pop table "ucp": []
}

void addIOFunctions(lua_State* L) {
	lua_pushglobaltable(L);
	
	lua_pushcfunction(L, LuaIO::luaLoadLibrary);
	lua_setfield(L, -2, "loadLibrary");

	lua_getfield(L, -1, "io");
	lua_pushcfunction(L, LuaIO::luaIOCustomOpen);
	lua_setfield(L, -2, "open");
	lua_pop(L, 1); // Pop the io table

	/**
	 * The code below is also possible.
	lua_pushcfunction(L, LuaIO::luaScopedRequire);
	lua_setfield(L, -2, "require"); //Overriding the global require
	
	* But we can also do this: */
	std::string pre = LuaIO::readInternalFile("ucp/code/pre.lua");
	if (luaL_loadbufferx(L, pre.c_str(), pre.size(), "ucp/code/pre.lua", "t") != LUA_OK) {
		std::cout << "ERROR in loading pre.lua" << lua_tostring(L, -1) << std::endl;
		lua_pop(L, 1);
	}
	else {
		if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
			std::cout << "ERROR in executing pre.lua: " << lua_tostring(L, -1) << std::endl;
			lua_pop(L, 1);
		};
	}

	lua_pop(L, 1); //Pop the global table
}

void addUCPInternalFunctions(lua_State* L) {
	lua_newtable(L);
	RPS_initializeLuaAPI("");
	// The namespace is left on the stack. 

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(L, -2, "internal");
	// Our table is left on the stack. Put the table in the global 'ucp' variable.
	lua_setglobal(L, "ucp");
}

void initializeLogger() {

}

void deinitializeLogger() {

}


void Core::initialize() {


	initializeConsole();


	initializeLogger();

	RPS_initializeLua();
	this->L = RPS_getLuaState();

	RPS_initializeCodeHeap();
	RPS_initializePrintRedirect();

	//RPS_initializeLuaOpenBase();
	RPS_initializeLuaOpenLibs();
	// TODO: implement restrictions here? Or only in lua via lua sandboxes?
	//luaL_requiref(L, LUA_LOADLIBNAME, luaopen_package, true);
	//luaL_requiref(L, LUA_MATHLIBNAME, luaopen_math, true);
	//luaL_requiref(L, LUA_STRLIBNAME, luaopen_string, true);
	//luaL_requiref(L, LUA_TABLIBNAME, luaopen_table, true);
	//luaL_requiref(L, LUA_IOLIBNAME, luaopen_io, true);


	addUCPInternalFunctions(this->L);
	addUtilityFunctions(this->L);
	addIOFunctions(this->L);

#ifdef COMPILED_MODULES
	this->UCP_DIR = "ucp/";

	std::string code = LuaIO::readInternalFile("ucp/main.lua");
	if (code.empty()) {
		std::cout << "ERROR: failed to load ucp/main.lua: " << "does not exist internally" << std::endl;
	}
	else {
		if (luaL_loadbufferx(this->L, code.c_str(), code.size(), "ucp/main.lua", "t") != LUA_OK) {
			std::string errorMsg = lua_tostring(this->L, -1);
			lua_pop(this->L, 1);
			std::cout << "ERROR: failed to load ucp/main.lua: " << errorMsg << std::endl;
		}

		// Don't expect return values
		if (lua_pcall(this->L, 0, 0, 0) != LUA_OK) {
			std::string errorMsg = lua_tostring(this->L, -1);
			lua_pop(this->L, 1);
			std::cout << "ERROR: failed to run ucp/main.lua: " << errorMsg << std::endl;
		}
	}

#else

	/**
	 * Allow UCP_DIR configuration via the command line.
	 *
	 */
	char * ENV_UCP_DIR = std::getenv("UCP_DIR");
	if (ENV_UCP_DIR != NULL) {
		std::filesystem::path path = std::filesystem::path(ENV_UCP_DIR);
		if (!path.is_absolute()) path = std::filesystem::current_path() / path;
		this->UCP_DIR = path;
	}

	std::filesystem::path mainPath = this->UCP_DIR / "main.lua";

	if (!std::filesystem::exists(mainPath)) {
		std::cout << "FATAL: Main file not found: " << mainPath << std::endl;
	}
	else {
		RPS_runBootstrapFile(mainPath.string());
	}
	
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
