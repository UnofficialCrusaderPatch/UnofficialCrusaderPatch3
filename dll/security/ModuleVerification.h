#pragma once

#include "framework.h"
#include <shlobj.h>
#include <string>
#include <filesystem>
#include <map>
#include <fstream>

class ModuleVerifier
{

public:
	static ModuleVerifier& getInstance()
	{
		static ModuleVerifier    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}

private:
	ModuleVerifier() {};

	std::filesystem::path appDataPath;
	std::map < std::string, std::string> moduleTruthHashMap;
	int status = -1;

	bool initializeAppDataPath() {
		PWSTR ppszPath;
		HRESULT res = SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &ppszPath);
		if (res == S_OK) {
			appDataPath = std::filesystem::path(ppszPath);
			CoTaskMemFree(ppszPath);
			return true;
		}

		CoTaskMemFree(ppszPath);
		return false;
	}

public:

	ModuleVerifier(ModuleVerifier const&) = delete;
	void operator=(ModuleVerifier const&) = delete;

	bool initialize() {
		initializeAppDataPath();
		std::filesystem::path theUCP3AppDataPath;
		std::filesystem::path signaturePath;

		theUCP3AppDataPath = appDataPath / "UnofficialCrusaderPatch3";
		signaturePath = theUCP3AppDataPath / "security" / "trusted-modules";

		if (std::filesystem::exists(signaturePath)) {
			for (const auto& entry : std::filesystem::directory_iterator(signaturePath)) {
				if (entry.is_regular_file() && entry.path().extension() == ".sig") {
					std::string k = entry.path().stem().string();

					std::ifstream input(entry.path().string());

					std::string hash;
					input >> hash;

					std::transform(hash.begin(), hash.end(), hash.begin(),
						[](unsigned char c) { return std::tolower(c); });

					moduleTruthHashMap[k] = hash;
				}
			}
			status = 0;
			return true;
		}
		else {
			status = 1;
			return false;
		}
	}

	bool verify(std::string moduleNameVersionString, std::string hash) {

		std::transform(hash.begin(), hash.end(), hash.begin(),
			[](unsigned char c) { return std::tolower(c); });

		if (moduleTruthHashMap.count(moduleNameVersionString) == 1) {
			return moduleTruthHashMap.at(moduleNameVersionString) == hash;
		}
		return false;
	}

};
