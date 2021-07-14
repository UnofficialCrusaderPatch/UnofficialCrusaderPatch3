#include "framework.h"
#include <string>
#include <regex>

#include <algorithm>
#include <cctype>
#include <string>

#include "RuntimePatchingSystem.h"
#include "console.h"

FILE* console;
FILE* errorFile;
FILE* user_in;

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
			RPS_executeSnippet(uin);
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
