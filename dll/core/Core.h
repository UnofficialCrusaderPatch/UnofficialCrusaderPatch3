/*****************************************************************//**
 * \file   Core.h
 * \brief  This is where the core framework is written. It uses a singleton paradigm.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include "framework.h"
#include <filesystem>
#include <map>

#include "lua.hpp"

#include "console/console.h"
#include "zip.h"
#include "security/Store.h"

#include <core/Core-fwd.h>

class Core
{

public:
	static Core& getInstance()
	{
		static Core    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}

private:

	Store* moduleHashStore = NULL;

	Core() {

		if (!secureMode || debugMode) {
			/**
	 * Allow UCP_DIR configuration via the command line.
	 *
	 */
			char* ENV_UCP_DIR = std::getenv("UCP_DIR");
			if (ENV_UCP_DIR != NULL) {
				std::filesystem::path path = std::filesystem::path(ENV_UCP_DIR);
				if (!path.is_absolute()) path = std::filesystem::current_path() / path;
				this->UCP_DIR = path;
			}
		}
		
		std::filesystem::path appData;
		if (!getAppDataPath(appData)) throw "failed to get app data path";
		

	};

	void setArgsAsGlobalVarInLua();
	void setArgsFromCommandLine();
	void processCommandLineArguments();
	void processEnvironmentVariables();
	void initializeConsole();
	void executeLuaMain();
	void startConsoleThread();

public:
	std::vector<std::string> argvString;
	std::vector<const char *> argv;
	int argc = 0;

	int consoleLogLevel = 0;
	int logLevel = 0;

	bool isInitialized = false;

	Core(Core const&) = delete;
	void operator=(Core const&) = delete;

	HANDLE consoleThread = 0;

	void initialize();

	std::filesystem::path UCP_DIR = "ucp/";

	lua_State* L = 0;

	bool sanitizePath(const std::string& path, std::string& result);

	std::map<std::string, std::string> aliasedPaths;
	bool resolveAliasedPath(std::string& path);

	bool pathIsInPluginDirectory(const std::string& sanitizedPath, std::string& extension, std::string& basePath, std::string& insideExtensionPath);
	bool pathIsInModuleDirectory(const std::string& sanitizedPath, std::string& extension, std::string& basePath, std::string& insideExtensionPath);
	bool pathIsInCacheDirectory(const std::string& sanitizedPath);
	bool moduleExists(const std::string moduleName, bool& asZip, bool& asFolder);

	bool pathIsInInternalCodeDirectory(const std::string& sanitizedPath, std::string& insideCodePath);
	bool codeLocationExists(bool& asZip, bool& asFolder);

	void createPIDFile();

	Store* getModuleHashStore();

	void log(int logLevel, std::string message);

#ifdef COMPILED_MODULES
	bool secureMode = true;
#else
	bool secureMode = false;
#endif

#if defined(_DEBUG)
	const bool debugMode = true;
#else
	const bool debugMode = false;
#endif

	bool hasConsole = false;

#if !defined(_DEBUG) && defined(COMPILED_MODULES)
	bool interactiveConsole = false;
#else
	bool interactiveConsole = true;
#endif

};