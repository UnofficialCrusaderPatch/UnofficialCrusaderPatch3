#include <core/initialization/logging.h>

#include <framework.h>
#include <lua.hpp>
#include <sstream>
#include <console/console.h>

#define LOGURU_WITH_STREAMS 1
#include "loguru.cpp"



void logToStdOut(void* user_data, const loguru::Message& message) {
	Console::logToConsole(message.verbosity, message.message);
}


const char* verbosityToName(loguru::Verbosity verbosity) {
	if (verbosity == loguru::Verbosity_1) {
		return "DEBUG";
	}
	if (verbosity == loguru::Verbosity_2) {
		return "VERBOSE";
	}
	return nullptr;
}

void initializeLogger(int logLevel, int consoleLogLevel) {

	loguru::set_verbosity_to_name_callback(verbosityToName);

	// Put every log message of at least logLevel in ucp3.log
	loguru::add_file("ucp3.log", loguru::Truncate, logLevel);

	// Only log WARNING, ERROR and FATAL to "error.log":
	loguru::add_file("ucp3-error-log.log", loguru::Truncate, loguru::Verbosity_WARNING);

	// Also log logLevel and higher to the console
	loguru::add_callback("stdout", logToStdOut, NULL, consoleLogLevel);

	// Only show most relevant things on stderr:
	loguru::g_stderr_verbosity = loguru::Verbosity_MAX;

	loguru::set_thread_name("(main thread)");
}

void deinitializeLogger() {
	loguru::shutdown();
}

void loguruVLOG_F(int logLevel, std::string message) {
	VLOG_F(logLevel, message.c_str());
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