#include <framework.h>
#include <shellapi.h>
#include <string>
#include <filesystem>
#include <sstream>
#include <fstream>
#include <process.h>

#include "io/strings.h"

#include "Core.h"
#include "lua/LuaLoadLibrary.h"
#include "lua/LuaUtil.h"
#include "lua/LuaCustomOpenFile.h"
#include "lua/deprecated/LuaListDirectories.h"
#include "lua/LuaDirectoriesList.h"
#include "lua/deprecated/LuaListFiles.h"
#include "lua/LuaFilesList.h"
#include "lua/yaml/LuaYamlParser.h"
#include "lua/yaml/LuaYamlDumper.h"

#include "RuntimePatchingSystem.h"


#include "compilation/fasm.h"

#include "security/Hash.h"
#include "security/Store.h"
#include "lua/Preload.h"

#include "io/modules/ModuleManager.h"


#include "core/initialization/io.h"
#include "core/initialization/ucp-internal.h"
#include "core/initialization/ucp-memory.h"
#include "core/initialization/logging.h"
#include "core/Core-path.h"

// Option parsing
#include <vendor/cxxopts/include/cxxopts.hpp>

// Debugging
#include "debugging/DebugMemoryAllocation.h"
#include "debugging/DebugExecutionLogger.h"
#include "debugging/DebugSettings.h"


void addUtilityFunctions(lua_State* L) {
	// Put the 'ucp.internal' on the stack
	lua_getglobal(L, "ucp"); // [ucp]
	lua_getfield(L, -1, "internal"); // [ucp, internal]

	// Deprecated
	lua_pushcfunction(L, LuaIO::luaListDirectories); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "listDirectories"); // [ucp, internal]

	// Deprecated
	lua_pushcfunction(L, LuaIO::luaListFiles); // [ucp, internal, luaListDirectories]
	lua_setfield(L, -2, "listFiles"); // [ucp, internal]

	{
		lua_createtable(L, 0, 0);

		lua_pushcfunction(L, LuaIO::luaDirectoriesList); // [ucp, internal, io, directories]
		lua_setfield(L, -2, "directories"); // [ucp, internal]

		lua_pushcfunction(L, LuaIO::luaFilesList); // [ucp, internal, io, files]
		lua_setfield(L, -2, "files"); // [ucp, internal]

		lua_setfield(L, -2, "io");
	}
	
	lua_pushcfunction(L, LuaUtil::luaWideCharToMultiByte);
	lua_setfield(L, -2, "WideCharToMultiByte");

	lua_pushcfunction(L, luaAssemble);
	lua_setfield(L, -2, "assemble");

	lua_pushcfunction(L, LuaUtil::luaGetCurrentThreadID);
	lua_setfield(L, -2, "GetCurrentThreadID");

	lua_pushcfunction(L, luaRegisterPathAlias);
	lua_setfield(L, -2, "registerPathAlias");

	lua_pushcfunction(L, LuaIO::luaResolveAliasedPath);
	lua_setfield(L, -2, "resolveAliasedPath");

	lua_pop(L, 2); // pop table "internal" and pop table "ucp": []
}

const struct luaL_Reg RPS_LIB[] = {

	{NULL, NULL}
};



void Core::log(int logLevel, std::string message) {
	loguruVLOG_F(logLevel, message);
}



void Core::initializeConsole() {
	if (this->hasConsole) {
		Console::initializeConsole();
	}
}

void Core::executeLuaMain() {

	ModuleHandle* mh;

	try {
		mh = ModuleHandleManager::getInstance().getLatestCodeHandle();

		std::string mainPath = "main.lua";
		std::string error;
		FILE* f = mh->openFilePointer(mainPath, error);

		if (f == NULL) {
			MessageBoxA(0, "ERROR: failed to load ucp/code/main.lua: does not exist", "FATAL", MB_OK);
			this->log(-3, "ERROR: failed to load ucp/code/main.lua: does not exist");
		}
		else {
			std::filebuf buf(f);
			std::istream inp(&buf);
			std::stringstream buffer;
			buffer << inp.rdbuf();
			std::string code = buffer.str();
			if (code.empty()) {
				MessageBoxA(0, "Could not execute main.lua: empty file", "FATAL", MB_OK);
				this->log(-3, "Could not execute main.lua: empty file");
			}
			else {
				if (luaL_loadbufferx(this->L, code.c_str(), code.size(), "ucp/code/main.lua", "t") != LUA_OK) {
					std::string errorMsg = std::string(lua_tostring(this->L, -1));
					lua_pop(this->L, 1);
					MessageBoxA(0, ("Failed to load main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
					this->log(-3, "Failed to load main.lua: " + errorMsg);


				}


				// Don't expect return values
				if (lua_pcall(this->L, 0, 0, 0) != LUA_OK) {
					std::string errorMsg = std::string(lua_tostring(this->L, -1));
					lua_pop(this->L, 1);
					MessageBoxA(0, ("Failed to run main.lua: " + errorMsg).c_str(), "FATAL", MB_OK);
					this->log(-3, "Failed to run main.lua: " + errorMsg);
				}

				this->log(0, "Finished running bootstrap file");
			}
		}


	}
	catch (ModuleHandleException e) {
		std::string errorMsg = "ERROR: failed to load ucp/code/main.lua: does not exist";
		errorMsg += ("\n reason: " + std::string(e.what()));

		MessageBoxA(0, errorMsg.c_str(), "FATAL", MB_OK);
		this->log(-3, errorMsg);
	}
}

void Core::startConsoleThread() {
	if (this->hasConsole && this->interactiveConsole) {
		consoleThread = CreateThread(nullptr, 0, (LPTHREAD_START_ROUTINE)Console::ConsoleThread, NULL, 0, nullptr);

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


bool Core::moduleExists(const std::string moduleFullName, bool& asZip, bool& asFolder) {

	asFolder = std::filesystem::is_directory(std::filesystem::path("ucp/modules") / moduleFullName);
	asZip = std::filesystem::is_regular_file(std::filesystem::path("ucp/modules") / (moduleFullName + ".zip"));

	return asZip || asFolder;
}


bool Core::codeLocationExists(bool& asZip, bool& asFolder) {

	asFolder = std::filesystem::is_directory(std::filesystem::path("ucp/code"));
	asZip = std::filesystem::is_regular_file(std::filesystem::path("ucp/code.zip"));

	return asZip || asFolder;
}

Store* Core::getModuleHashStore() {
	return this->moduleHashStore;
}


void Core::setArgsFromCommandLine() {

	// Fetch arguments

	LPWSTR* szArglist;
	int nArgs = 0;

	szArglist = CommandLineToArgvW(GetCommandLineW(), &nArgs);

	if (NULL == szArglist)
	{
		return;
	}

	for (int i = 0; i < nArgs; i++) {
		LPWSTR arg = szArglist[i];

		std::string narrow = io::utf8_encode(arg);
		/*std::wstring wide = converter.from_bytes(narrow_utf8_source_string);*/

		this->argvString.push_back(std::string(narrow));
		this->argc += 1;
	}

	for (int i = 0; i < this->argc; i++) {
		this->argv.push_back(this->argvString[i].c_str());
	}

	// Free memory allocated for CommandLineToArgvW arguments.

	LocalFree(szArglist);
}


cxxopts::Options options("Stronghold Crusader (UCP)", "Command line arguments for UCP");
cxxopts::ParseResult optionsResult;

void Core::setArgsAsGlobalVarInLua() {

	int nArgs = this->argc;

	lua_createtable(this->L, nArgs, 0);

	for (int i = 0; i < nArgs; i++) {

		lua_pushstring(this->L, this->argv[i]);
		lua_seti(this->L, -2, i + 1); // lua is 1-based
	}

	lua_setglobal(this->L, "arg");


	lua_createtable(this->L, 0, optionsResult.arguments().size());
	for (cxxopts::KeyValue kv : optionsResult.arguments()) {
		lua_pushstring(this->L, kv.value().c_str());
		lua_setfield(this->L, -2, kv.key().c_str());
	}

	lua_setglobal(this->L, "processedArg");
}


void Core::processEnvironmentVariables() {

	const char* UCP_CONSOLE = std::getenv("UCP_CONSOLE");
	std::string CMD_UCP_CONSOLE;

	if (UCP_CONSOLE != NULL) {
		if (std::string(UCP_CONSOLE) == "0" || std::string(UCP_CONSOLE) == "false") {
			this->hasConsole = false;
		}
		else if (std::string(UCP_CONSOLE) == "1" || std::string(UCP_CONSOLE) == "true") {
			this->hasConsole = true;
		}
	}



	int verbosity = 0;
	const char* UCP_VERBOSITY = std::getenv("UCP_VERBOSITY");
	if (UCP_VERBOSITY != NULL) {
		std::istringstream s(UCP_VERBOSITY);
		s >> verbosity; // We don't care about errors at this point.
	}

	int consoleVerbosity = 0;
	const char* UCP_CONSOLE_VERBOSITY = std::getenv("UCP_CONSOLE_VERBOSITY");
	if (UCP_CONSOLE_VERBOSITY != NULL) {
		std::istringstream s(UCP_CONSOLE_VERBOSITY);
		s >> consoleVerbosity; // We don't care about errors at this point.
	}

	this->consoleLogLevel = consoleVerbosity;
	this->logLevel = verbosity;
}


void Core::processCommandLineArguments() {
	options.add_options()
		("ucp-console", "Enable the console", cxxopts::value<bool>()->default_value("false")) // a bool parameter
		("ucp-no-console", "Disable the console", cxxopts::value<bool>()->default_value("false")) // a bool parameter
		("ucp-verbosity", "Set verbosity level", cxxopts::value<int>()->default_value("0"))
		("ucp-console-verbosity", "Set verbosity level for the console", cxxopts::value<int>()->default_value("0"))
		("ucp-config-file", "Override the default config file: 'ucp-config.yml'", cxxopts::value<std::string>()->default_value("ucp-config.yml"))
		("ucp-game-data-path", "Override the path game data is loaded from", cxxopts::value<std::string>()->default_value(""))
		("ucp-no-security", "Disable security (permit modules from non official sources)", cxxopts::value<bool>()->default_value("false"))
		("ucp-security", "Enable security (permit modules from official sources only)", cxxopts::value<bool>()->default_value("false"))
		("ucp-debugging-memory-allocator", "Enable memory allocation logger", cxxopts::value<bool>()->default_value("false"))
		("ucp-debugging-execution-logger", "Enable lua_sethook to log every lua line", cxxopts::value<bool>()->default_value("false"))
		("ucp-debugging-aggressive-gc", "Enable lua_sethook aggressive gc (must be used with other lua_sethook option)", cxxopts::value<bool>()->default_value("false"))
		;

	// For wstring, see https://github.com/jarro2783/cxxopts/issues/299
	optionsResult = options.allow_unrecognised_options().parse(this->argc, this->argv.data());

	bool consoleYes = optionsResult["ucp-console"].as<bool>();
	bool consoleNo = optionsResult["ucp-no-console"].as<bool>();

#if !defined(_DEBUG) && defined(COMPILED_MODULES)
	this->hasConsole = consoleYes && !consoleNo;
#else
	this->hasConsole = !consoleNo;
#endif

	if (optionsResult["ucp-no-security"].as<bool>() && !optionsResult["ucp-security"].as<bool>()) {
		this->secureMode = false;
		this->interactiveConsole = true;
	} else if (!optionsResult["ucp-no-security"].as<bool>() && optionsResult["ucp-security"].as<bool>()) {
		this->secureMode = true;
		this->interactiveConsole = false;
	}
	else {
		/* Retain default setting */
	}

	this->consoleLogLevel = optionsResult["ucp-console-verbosity"].as<int>();
	this->logLevel = optionsResult["ucp-verbosity"].as<int>();
}

/**
* Create PID file that is automatically destroyed on exit
* Created in the game folder as the ucp folder location is not yet known
*/
HANDLE pidFile = NULL;
const std::string pidFilePath = "ucp-pid";
void Core::createPIDFile() {
	int pid = _getpid();
	std::string pidString = std::to_string(pid);
	pidFile = CreateFileA(
		(pidFilePath + ("-" + pidString)).c_str(),
		GENERIC_READ | GENERIC_WRITE,
		FILE_SHARE_DELETE | FILE_SHARE_READ,
		NULL,
		CREATE_ALWAYS,
		FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE,
		NULL);
}

bool Core::setProcessDirectory() {
	CHAR path[MAX_PATH];
	GetModuleFileNameA(NULL, path, MAX_PATH);

	std::filesystem::path p = std::filesystem::path(path);
	auto folder = p.parent_path();

	SetCurrentDirectoryA(folder.string().c_str());

	return true;
}



void Core::initialize() {

	if (this->isInitialized) {
		MessageBoxA(NULL, "UCP3 dll was already initialized", "FATAL: already initialized", MB_OK);
		this->log(-3, "UCP3 dll was already initialized");
		return;
	}

	if (!this->secureMode) {
		int answer = MessageBoxA(
			NULL,
			"Warning: you are running the UCP modding framework in DEVELOPER mode, which means NO SECURITY MEASURES are being applied.\n\nContinuing with modules from untrusted sources leads to execution of software from untrusted sources.\n\nIf you click YES, you agree you understand fully what this means and wish to proceed. Otherwise, click NO",
			"WARNING: NO SECURITY",
			MB_YESNO
		);

		if (answer != IDYES) {
			exit(0);
		}
	}

	bool processDirectorySuccess = setProcessDirectory();

	this->createPIDFile();

	this->setArgsFromCommandLine();
	this->processEnvironmentVariables();
	this->processCommandLineArguments();

	initializeLogger(this->logLevel, this->consoleLogLevel);

	this->initializeConsole();

	if (!processDirectorySuccess) {
		this->log(-1, "Failed to set process directory");
	}
	this->log(0, "Current directory: " + std::filesystem::current_path().string());

	this->moduleHashStore = new Store(this->UCP_DIR / "extension-store.yml", this->secureMode);
	
	std::string error;
	if (!TempfileManager::getInstance().initialize("ucp/.cache", error)) {
		MessageBoxA(NULL, error.c_str(), "FATAL", MB_OK);
	}
		
	// Start of lua related initialization
	RPS_initializeLua();
	this->L = RPS_getLuaState();

	if (optionsResult["ucp-debugging-memory-allocator"].as<bool>()) {
		debugging::registerDebuggingMemoryAllocator(this->L);
	}

	if (optionsResult["ucp-debugging-execution-logger"].as<bool>()) {
		lua_sethook(L, debugging::logExecution, LUA_MASKLINE, NULL);
	}

	if (optionsResult["ucp-debugging-aggressive-gc"].as<bool>()) {
		debugging::DebugSettings::getInstance().aggressiveGC = true;
		lua_gc(L, LUA_GCSETPAUSE, 0);
	}
	
	RPS_initializeLuaOpenLibs();

	// Register global ucp table
	lua_newtable(this->L);
	lua_setglobal(this->L, "ucp");

	addUCPInternalFunctions(this->L);
	addUCPMemoryFunctions(this->L);
	addLoggingFunctions(this->L);
	addUtilityFunctions(this->L);
	addIOFunctions(this->L);

	this->setArgsAsGlobalVarInLua();

	this->executeLuaMain();

	// End of lua related initialization
	
	this->startConsoleThread();

	this->isInitialized = true;
}
