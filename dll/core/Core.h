/*****************************************************************//**
 * \file   Core.h
 * \brief  This is where the core framework is written. It uses a singleton paradigm.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include "framework.h"

#include "lua.hpp"
#include "console/console.h"
#include <filesystem>
#include <map>
#include "zip.h"
#include "security/Store.h"

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

		if (!secureMode) {
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



		moduleHashStore = new Store("b584b8dc58ce1e22bcb45fa332f739094707a650ab95232c33ec5cbc5abf9a701dc979ce2ce63042817b793fc9cd6d240d46ed4300aa422d87fb03c313e03650adf578ac00b68a84c53c76c1f5054c4cc2fe4fb9ef65f4eaeb4dcc32052ddd215ad2ddc3e4158f61341912ca74deef52d0af7b9bb59e918532b622fa3d25c36cb809bfafebb752beb006fd02cc00bcea57548af7355e977fe40baa940d9d30dc65a32e0b35c1c95f1cf305fce2fca8eeb6c766efa031d36f266462cd0e310179c2b624e1fc1d7e0e620caed00324c107f3b4d3f7708f54e1fa54a13a22cc07c0985c77f799a4d4e24c4c71a831b842226531d0e387b0017003421cb1c704c52c71144362784893e4c634066503253aa1b61c84653f5286c661f1ccf32b95a2f8f41d4fc81292b257984cd9d56f53dce39cbab8ce4e6a00062c5ecc276c5281728120d30805894656375dea460bc104e078252a04c93f96d79216b384e58d41192920c838172476678ff1d309fe01abf06a3f7de95f5f9d9e141f4d1118eb62ec8fe1e44793bde0e6c4015d0136c9dc7f7f26bed08fad24c3d2ebe6c3f32ddec5e7b1df0192cfe4ea75b52dd523f75b14dd6a7e604251013fa589c252c655f12303adb7fe20c68d9909e9df51f4cca8525b8e69ec542ef95a2fe283173cdcd89c86e67583fa2f2d3637c972f7832f619f4a713e0ec7f11b357f0f1662a0751ccd");
		std::filesystem::path appData;
		if (!getAppDataPath(appData)) throw "failed to get app data path";
		if (!moduleHashStore->open("ucp3-module-store.yml", "ucp3-module-store-sig.yml")) {

		}
	};

public:

	Core(Core const&) = delete;
	void operator=(Core const&) = delete;

	HANDLE consoleThread = 0;

	void initialize();

	std::filesystem::path UCP_DIR = "ucp/";

	lua_State* L = 0;

	bool hasConsole = false;

	bool sanitizePath(const std::string& path, std::string& result);

	bool pathIsInModule(const std::string& sanitizedPath, std::string& extension, std::string& basePath, std::string& insideExtensionPath);
	bool moduleExists(const std::string moduleName, bool& asZip, bool& asFolder);

	bool pathIsInInternalCode(const std::string& sanitizedPath, std::string& insideCodePath);
	bool codeLocationExists(bool& asZip, bool& asFolder);

	Store getModuleHashStore();

	void log(int logLevel, std::string message);

#ifdef COMPILED_MODULES
	const bool secureMode = true;
#else
	const bool secureMode = false;
#endif

#if defined(_DEBUG)
	const bool debugMode = true;
#else
	const bool debugMode = false;
#endif

};