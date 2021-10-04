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

FILE* console;
FILE* errorFile;
FILE* user_in;

void executeLuaSnippet(std::string code) {
	lua_State* L = RPS_getLuaState();
	int before = lua_gettop(L);
	int r = luaL_dostring(L, code.c_str());
	if (r == LUA_OK) {
		int after = lua_gettop(L);
		if (after - before > 0) {
			for (int i = before; i < after; i++) {  /* for each argument */
				size_t l;
				const char* s = luaL_tolstring(L, i, &l);  /* convert it to string */
				if (i > 1)  /* not the first element? */
					lua_writestring("\t", 1);  /* add a tab before it */
				lua_writestring(s, l);  /* print it */
				lua_pop(L, 1);  /* pop result */
			}
			lua_writeline();
		}
		lua_pop(L, after - before);
	}
	else {
		std::string errormsg = lua_tostring(L, -1);
		std::cout << "[RPS]: error in lua snippet: " << errormsg << std::endl;
		lua_pop(L, 1); // pop off the error message;
	}
}

void RunUserInputLoop()
{
	std::cout << std::endl << std::endl << "Welcome to the UCP. Type help to get started." << std::endl;

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
		else if (the_command == "luaStackSize") {
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


void initializeConsole() {
	// debug info initialize
	AllocConsole();
	freopen_s(&console, "CONOUT$", "w", stdout);

	if (console == 0) {
		MessageBoxA(0, "Could not allocate console, exiting...", "ERROR", MB_OK);
		return;
	}

	//std::cout << "Allocated console.\n";

	// reroute stdout and stderr
	errorFile = freopen("ucp-3-stderr.log", "w", stderr);

	if (errorFile == 0) {
		std::cout << "Could not open error log file.\n";
	}

	// have user input possible
	//user_input = GetStdHandle(STD_INPUT_HANDLE);
	freopen_s(&user_in, "CONIN$", "r", stdin);
	if (user_in == 0) {
		std::cout << "Could not open user input.\n";
	}

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
