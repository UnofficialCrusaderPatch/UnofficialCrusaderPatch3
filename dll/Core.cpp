#include <string>
#include <filesystem>
#include <sstream>
#include <fstream>
#include "Core.h"
#include "LuaIO.h"

#define LOGURU_WITH_STREAMS 1
#include "loguru.cpp"

#include "fasm.h"

void addUtilityFunctions(lua_State* L) {
	// Put the 'ucp.internal' on the stack
	lua_getglobal(L, "ucp"); // [ucp]
	lua_getfield(L, -1, "internal"); // [ucp, internal]

	lua_pushcfunction(L, LuaIO::luaListDirectories); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "listDirectories"); // [ucp, internal]

	lua_pushcfunction(L, LuaIO::luaWideCharToMultiByte);
	lua_setfield(L, -2, "WideCharToMultiByte");

	lua_pushcfunction(L, luaAssemble);
	lua_setfield(L, -2, "assemble");

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

void logToStdOut(void* user_data, const loguru::Message& message) {
	std::cout << message.message << std::endl;
}

static int luaPrint(lua_State* L) {
	std::stringstream output;

	int n = lua_gettop(L);  /* number of arguments */
	int i;
	for (i = 1; i <= n; i++) {  /* for each argument */
		size_t l;
		const char* s = luaL_tolstring(L, i, &l);  /* convert it to string */
		if (i > 1)  /* not the first element? */
			output << "\t";
		output << s;
		lua_pop(L, 1);  /* pop result */
	}
	LOG_S(INFO) << output.str();
	return 0;
}

static const struct luaL_Reg printlib[] = {
  {"print", luaPrint},
  {NULL, NULL} /* end of array */
};

void initializeLogger() {
	// Put every log message in "everything.log":
	loguru::add_file("ucp3.log", loguru::Truncate, loguru::Verbosity_MAX);

	// Only log WARNING, ERROR and FATAL to "latest_readable.log":
	loguru::add_file("ucp3-error-log.log", loguru::Truncate, loguru::Verbosity_WARNING);

	loguru::add_callback("stdout", logToStdOut, NULL, loguru::Verbosity_MAX);

	// Only show most relevant things on stderr:
	loguru::g_stderr_verbosity = loguru::Verbosity_MAX;
}

void deinitializeLogger() {
	loguru::shutdown();
}

int luaLog(lua_State* L) {
	if (lua_gettop(L) < 2) {
		return luaL_error(L, "invalid number of arguments, expected at least 2: log level, message, ...");
	}
	int logLevel = luaL_checkinteger(L, 1);

	std::stringstream output;

	int n = lua_gettop(L);  /* number of arguments */
	int i;
	const int start = 2;
	for (i = start; i <= n; i++) {  /* for each argument */
		size_t l;
		const char* s = luaL_tolstring(L, i, &l);  /* convert it to string */
		if (i > start)  /* not the first element? */
			output << "\t";
		output << s;
		lua_pop(L, 1);  /* pop result */
	}

	// If log is worse than warning
	if (logLevel < loguru::Verbosity_WARNING) {
		MessageBoxA(0, output.str().c_str(), "Error", MB_OK);
	}

	VLOG_F(logLevel, output.str().c_str());

	return 0;
}

void addLoggingFunctions(lua_State* L) {
	lua_pushglobaltable(L);
	luaL_setfuncs(L, printlib, 0);
	lua_pop(L, 1);

	// Put the 'ucp.internal' on the stack
	lua_getglobal(L, "ucp"); // [ucp]
	lua_getfield(L, -1, "internal"); // [ucp, internal]

	lua_pushcfunction(L, luaLog); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "log"); // [ucp, internal]

	lua_pop(L, 2); // pop table "internal" and pop table "ucp": []
}

bool Core::resolvePath(const std::string& path, std::string& result, bool& isInternal) {

	isInternal = true;

	if (!this->sanitizePath(path, result)) {
		return false;
	}

	if (result.find("ucp/") == 0) {
#ifdef COMPILED_MODULES
		if (result.find("ucp/plugins/") == 0) {
			result = (std::filesystem::current_path() / result).string();
			isInternal = false;
			return true;
		}
		isInternal = true;
		return true;
#else
		result = (this->UCP_DIR / result.substr(4)).string();
		isInternal = false;
		return true;
#endif
	}

	result = (std::filesystem::current_path() / result).string();
	isInternal = false;
	return true;
}

bool Core::sanitizePath(const std::string& path, std::string& result) {
	std::string rawPath = path;

	//Assert non empty path
	if (rawPath.empty()) {
		result = "invalid path";
		return false;
	}

	std::filesystem::path sanitizedPath(rawPath);
	sanitizedPath = sanitizedPath.lexically_normal(); // Remove "/../" and "/./"

	if (!std::filesystem::path(sanitizedPath).is_relative()) {
		result = "path has to be relative";
		return false;
	}

	result = sanitizedPath.string();

	//Now we can assume sanitizedPath cannot escape the game directory.
//Let's assert that
	std::filesystem::path a = std::filesystem::current_path();
	std::filesystem::path b = a / result;
	std::filesystem::path r = std::filesystem::relative(b, a);
	if (r.string().find("..") == 0) {
		result = "the path specified is not a proper relative path";
		return false;
	}

	//Replace \\ with /. Note: don't call make_preferred on the path, it will reverse this change.
	std::replace(result.begin(), result.end(), '\\', '/');

	return true;
}

void Core::initialize() {

	initializeLogger();

#if !defined(_DEBUG) && defined(COMPILED_MODULES)
	// No Console
	this->hasConsole = false;
#else
	// In principle yes, unless explicitly not
	this->hasConsole = true;
	char* ENV_UCP_CONSOLE = std::getenv("UCP_CONSOLE");
	if (ENV_UCP_CONSOLE != NULL) {
		if (std::string(ENV_UCP_CONSOLE) == "0") {
			this->hasConsole = false;
		}
	}
	if (this->hasConsole) {
		initializeConsole();
	}
//#elif !defined(COMPILED_MODULES)
//	char* ENV_UCP_CONSOLE = std::getenv("UCP_CONSOLE");
//	if (ENV_UCP_CONSOLE != NULL) {
//		if (std::string(ENV_UCP_CONSOLE) == "1") {
//			this->hasConsole = true;
//		}
//	}
//	if (this->hasConsole) {
//		initializeConsole();
//	}
#endif
		
	RPS_initializeLua();
	this->L = RPS_getLuaState();

	RPS_initializeCodeHeap();
	
	RPS_initializeLuaOpenLibs();

	// Install the print redirect to logger

	addUCPInternalFunctions(this->L);
	addLoggingFunctions(this->L);
	addUtilityFunctions(this->L);
	addIOFunctions(this->L);

#ifdef COMPILED_MODULES
	this->UCP_DIR = "ucp/";

	std::string code = LuaIO::readInternalFile("ucp/main.lua");
	if (code.empty()) {
		MessageBoxA(0, "ERROR: failed to load ucp/main.lua: does not exist internally", "FATAL", MB_OK);
		LOG_S(FATAL) << "ERROR: failed to load ucp/main.lua: " << "does not exist internally";
	}
	else {
		if (luaL_loadbufferx(this->L, code.c_str(), code.size(), "ucp/main.lua", "t") != LUA_OK) {
			std::string errorMsg = std::string(lua_tostring(this->L, -1));
			lua_pop(this->L, 1);
			MessageBoxA(0, ("ERROR: failed to load ucp/main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
			LOG_S(FATAL) << "ERROR: failed to load ucp/main.lua: " << errorMsg;
		}

		// Don't expect return values
		if (lua_pcall(this->L, 0, 0, 0) != LUA_OK) {
			std::string errorMsg = std::string(lua_tostring(this->L, -1));
			lua_pop(this->L, 1);
			MessageBoxA(0, ("ERROR: failed to run ucp/main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
			LOG_S(FATAL) << "ERROR: failed to run ucp/main.lua: " << errorMsg;
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

	LOG_S(INFO) << "Running bootstrap file at: " << mainPath.string();

	if (!std::filesystem::exists(mainPath)) {
		MessageBoxA(0, ("Main file not found: " + mainPath.string()).c_str(), "FATAL", MB_OK);
		LOG_S(FATAL) << "FATAL: Main file not found: " << mainPath << std::endl;
	}
	else {
		std::ifstream t(mainPath.string());
		std::stringstream buffer;
		buffer << t.rdbuf();
		std::string code = buffer.str();
		if (code.empty()) {
			MessageBoxA(0, "Could not execute main.lua: empty file", "FATAL", MB_OK);
			LOG_S(FATAL) << "Could not execute main.lua: empty file";
		}
		else {
			if (luaL_loadbufferx(this->L, code.c_str(), code.size(), "ucp/main.lua", "t") != LUA_OK) {
				std::string errorMsg = std::string(lua_tostring(this->L, -1));
				lua_pop(this->L, 1);
				MessageBoxA(0, ("Failed to load main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
				LOG_S(FATAL) << "Failed to load main.lua: " << errorMsg;
				
				
			}

			// Don't expect return values
			if (lua_pcall(this->L, 0, 0, 0) != LUA_OK) {
				std::string errorMsg = std::string(lua_tostring(this->L, -1));
				lua_pop(this->L, 1);
				MessageBoxA(0, ("Failed to run main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
				LOG_S(FATAL) << "Failed to run main.lua: " << errorMsg;
			}

			LOG_S(INFO) << "Finished running bootstrap file";
		}
	}

	
	
#endif
	
	if (this->hasConsole) {
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
}
