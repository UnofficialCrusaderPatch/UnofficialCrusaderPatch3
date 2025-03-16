#include "framework.h"
#include <string>
#include <regex>

#include <algorithm>
#include <cctype>
#include <string>
#include <io.h>
#include <fcntl.h>

#include "RuntimePatchingSystem.h"
#include "console.h"

/* print a string */
#if !defined(lua_writestring)
#define lua_writestring(s,l)   fwrite((s), sizeof(char), (l), stdout)
#endif

/* print a newline and flush the output */
#if !defined(lua_writeline)
#define lua_writeline()        (lua_writestring("\n", 1), fflush(stdout))
#endif

namespace Console {

	FILE* console;
	FILE* errorFile;
	FILE* user_in;

	void executeLuaSnippet(const std::string &code) {

		lua_State* L = RPS_getLuaState();

		int before = lua_gettop(L);

		const std::string returnCode = "return " + code;

		std::string finalCode = returnCode;

		if (luaL_loadstring(L, returnCode.c_str()) != LUA_OK) {
			finalCode = code;
			lua_pop(L, 1);

			if (luaL_loadstring(L, code.c_str()) != LUA_OK) {
				std::string errormsg = lua_tostring(L, -1);
				std::cout << errormsg << std::endl;
				lua_pop(L, 1); // pop off the error message;

				lua_settop(L, before);

				return;
			}
		}

		int r = lua_pcall(L, 0, LUA_MULTRET, 0);
		if (r == LUA_OK) {
			int after = lua_gettop(L);
			int nreturns = after - before;
			if (nreturns > 0) {
				for (int i = before; i < after; i++) {  /* for each argument */
					size_t l;
					const char* s = lua_tolstring(L, i + 1, &l);  /* convert it to string and push it on the stack */
					if (i > 0)  /* not the first element? */
						lua_writestring("\t", 1);  /* add a tab before it */
					lua_writestring(s, l);  /* print it */
					lua_pop(L, 1);  /* pop result of tolstring */
				}
				lua_writeline();
			}
			lua_pop(L, nreturns);
		}
		else {
			std::string errormsg = lua_tostring(L, -1);
			std::cout << errormsg << std::endl;
			lua_pop(L, 1); // pop off the error message;
		}

		lua_settop(L, before);
	}

	void RunUserInputLoop()
	{
		// std::cout << std::endl << std::endl << "Welcome to the UCP. Type help to get started." << std::endl;

		std::regex command("^\\s*(\\S+)(\\s|$)");

		while (true) {

			std::cout << "UCP> ";

			std::string uin;
			std::getline(std::cin, uin);

			std::smatch m;
			std::string the_command;

			if (uin == "") {
				continue;
			}
			else {
				if (std::regex_search(uin, m, command)) {
					the_command = m[1];
				}
				else {
					std::cout << "Uninterpretable input: " << uin << std::endl;
					continue;
				};
			}
			if (the_command == "help") {
				std::cout << "Available commands: " << std::endl << "\thelp\n\tluaStackSize\n\texit" << std::endl;
			}
			else if (the_command == ".luaStackSize") {
				std::cout << "Current lua stack size: " << RPS_getCurrentStackSize() << std::endl;
			}
			else if (the_command == "exit") {
				break;
			}
			else {
				executeLuaSnippet(uin);
			}
		}
	}




	bool consoleColoredMode = false;

	void trySetColoredConsole() {
#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING  0x0004
#endif

		HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
		if (hOut != INVALID_HANDLE_VALUE) {
			DWORD dwMode = 0;
			GetConsoleMode(hOut, &dwMode);
			dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
			consoleColoredMode = SetConsoleMode(hOut, dwMode) != 0;
		}
	}


	const std::string loggingVerbosityNames[] = {
		"FATAL",
		"ERROR",
		"WARNING",
		"INFO",
		"DEBUG",
		"VERBOSE",
		"VVERBOSE",
		"VVERBOSE",
		"VVERBOSE",
		"VVERBOSE",
		"VVERBOSE",
		"VVERBOSE",
		"VVERBOSE",
	};


	const std::string logErrorColor("\033[0;91m");
	const std::string logWarningColor("\033[0;93m");
	const std::string logInfoColor("\033[0;97m");
	const std::string logDebugColor("\033[0m");
	const std::string logVerboseColor("\033[0;90m");
	const std::string logColorReset("\033[0m");

	const std::string loggingVerbosityColors[] = {
		logErrorColor, // -3
		logErrorColor,  // -2
		logWarningColor,  // -1
		logInfoColor,  // 0
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor,
		logVerboseColor, // 9
	};


	void logToConsole(const int verbosity, const std::string& message) {

		if (verbosity < -3) {
			std::cout << ": " << message << std::endl;
		}
		else {
			const int zeroBasedVerbosity = verbosity + 3;

			if (consoleColoredMode) {
				std::cout << loggingVerbosityColors[zeroBasedVerbosity] << loggingVerbosityNames[zeroBasedVerbosity] << ": " << message << logColorReset << std::endl;
			}
			else {
				std::cout << loggingVerbosityNames[zeroBasedVerbosity] << ": " << message << std::endl;
			}

		}

	}


	void initializeConsole() {
		// debug info initialize
		AllocConsole();
		freopen_s(&console, "CONOUT$", "w", stdout);

		if (console == 0) {
			MessageBoxA(0, "Could not allocate console, exiting...", "ERROR", MB_OK);
			return;
		}


		// have user input possible
		//user_input = GetStdHandle(STD_INPUT_HANDLE);
		freopen_s(&user_in, "CONIN$", "r", stdin);
		if (user_in == 0) {
			std::cout << "Could not open user input.\n";
		}

		trySetColoredConsole();

		//if (::AllocConsole())
		//{
		//	int hCrt = ::_open_osfhandle((intptr_t) ::GetStdHandle(STD_OUTPUT_HANDLE), _O_TEXT);
		//	FILE* hf = ::_fdopen(hCrt, "w");
		//	*stdout = *hf;
		//	::setvbuf(stdout, NULL, _IONBF, 0);

		//	hCrt = ::_open_osfhandle((intptr_t) ::GetStdHandle(STD_ERROR_HANDLE), _O_TEXT);
		//	hf = ::_fdopen(hCrt, "w");
		//	*stderr = *hf;
		//	::setvbuf(stderr, NULL, _IONBF, 0);
		//}
	}

	void teardownConsole() {
		// debug info remove
		fclose(console);
		FreeConsole();
	}

	void ConsoleThread()
	{

		RunUserInputLoop();

		ExitThread(0);

		return;
	}

}
