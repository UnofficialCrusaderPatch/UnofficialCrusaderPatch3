/*****************************************************************//**
 * \file   Core.h
 * \brief  This is where the core framework is written. It uses a singleton paradigm.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include "framework.h"
#include "lua.hpp"
#include "console.h"
#include <filesystem>
#include <map>
#include "zip.h"


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
	Core() {};

public:

	Core(Core const&) = delete;
	void operator=(Core const&) = delete;

	HANDLE consoleThread = 0;

	void initialize();

	std::filesystem::path UCP_DIR = "ucp/";

	lua_State* L = 0;

	bool hasConsole = false;

	bool sanitizePath(const std::string& path, std::string& result);
	bool resolvePath(const std::string& path, std::string& result, bool& isInternal);

	bool pathIsInModule(const std::string& sanitizedPath, std::string& extension, std::string& insideExtensionPath);

	std::map<std::string, zip_t*> modulesZipMap;
	std::map<std::string, bool> modulesDirMap;
	void loadZippedModules();

	void log(int logLevel, std::string message);
};