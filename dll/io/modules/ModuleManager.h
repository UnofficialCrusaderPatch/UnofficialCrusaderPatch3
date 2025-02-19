#pragma once

#include "io/modules/ZipFileModuleHandle.h"
#include "io/modules/FolderFileModuleHandle.h"
#include "io/modules/TempFileModuleHandle.h"

#define ZippedExtensionHandler TempFileExtensionHandle
#define ZippedModuleHandler TempFileModuleHandle

class ModuleHandleManager {

private:

	ModuleHandle* codeHandle = NULL;
	std::map<std::string, ModuleHandle*> moduleHandles;
	std::map<std::string, std::string> moduleHandleErrors;

	std::map<std::string, ExtensionHandle*> extensionHandles;
	std::map<std::string, std::string> extensionHandleErrors;

	ModuleHandleManager() {
		codeHandle = NULL;
	}

	bool verifyZipFile(const std::string& path, const std::string& name, std::string& errorMsg) {
		std::string hash;

		if (!Hasher::getInstance().hashFile(path, hash, errorMsg)) {
			throw ModuleHandleException("failed to hash: " + path + "\n reason: " + errorMsg);
		}

		if (Core::getInstance().getModuleHashStore()->verify(name, hash)) {
			return true;
		}

		std::string sigPath = path + ".sig";
		if (std::filesystem::is_regular_file(sigPath)) {
			if (SignatureVerifier::getInstance().verifyFile(path, sigPath, errorMsg)) {
				return true;
			}
		}

		errorMsg = "Missing security signature or signature mismatch for: " + name;
		return false;
	}

public:
	static ModuleHandleManager& getInstance()
	{
		static ModuleHandleManager instance; // Guaranteed to be destroyed.
		// Instantiated on first use.
		return instance;
	}

	ModuleHandleManager(ModuleHandleManager const&) = delete;
	void operator=(ModuleHandleManager const&) = delete;

	/**
		This function works because only one version of any extension can be loaded at the same time.
	*/
	ExtensionHandle* loadedExtensionHandle(const std::string& nameWithoutVersion) {

		for (std::map<std::string, ExtensionHandle*>::iterator iter = this->extensionHandles.begin(); iter != this->extensionHandles.end(); ++iter)
		{
			std::string k = iter->first;
			// First test if the key starts with the extension name
			if (k.rfind(nameWithoutVersion + "-", 0) == 0) {
				// Remove the version portion.
				int lastDashPosition = k.rfind("-");
				if (lastDashPosition == std::string::npos) {
					// We shouldn't get here.
					continue;
				}
				if (k.substr(0, lastDashPosition) == nameWithoutVersion) {
					return iter->second;
				}
			}
		}

		return NULL;
	}

	/**
	This function works because only one version of any extension can be loaded at the same time.
*/
	ModuleHandle* loadedModuleHandle(const std::string& nameWithoutVersion) {

		for (std::map<std::string, ModuleHandle*>::iterator iter = this->moduleHandles.begin(); iter != this->moduleHandles.end(); ++iter)
		{
			std::string k = iter->first;
			// First test if the key starts with the extension name
			if (k.rfind(nameWithoutVersion + "-", 0) == 0) {
				// Remove the version portion.
				int lastDashPosition = k.rfind("-");
				if (lastDashPosition == std::string::npos) {
					// We shouldn't get here.
					continue;
				}
				if (k.substr(0, lastDashPosition) == nameWithoutVersion) {
					return iter->second;
				}
			}
		}

		return NULL;
	}

	ExtensionHandle* getExtensionHandle(const std::string& path, const std::string& extension, bool verifyContents)
	{
		if (extensionHandles.count(extension) == 1) {
			return extensionHandles[extension];
		}

		if (extensionHandleErrors.count(extension) == 1) {
			throw ModuleHandleException(extensionHandleErrors[extension]);
		}

		std::string zipPath = path + ".zip";
		bool existsAsZip = std::filesystem::is_regular_file(zipPath);
		bool existsAsFolder = std::filesystem::is_directory(path);

		if (Core::getInstance().secureMode) {
			if (verifyContents) {
				if (!existsAsZip) {
					if (existsAsFolder) {
						std::string errMsg = "extension verification error: extension '" + path + "' exists as a folder on the file system but not as a zip file as required in secure mode";
						extensionHandleErrors[extension] = errMsg;
						throw ModuleHandleException(errMsg);
					}
					else {
						std::string errMsg = ("extension does not exist");
						extensionHandleErrors[extension] = errMsg;
						throw ModuleHandleException(errMsg);
					}
				}

				std::string errorMsg;
				if (!verifyZipFile(zipPath, extension, errorMsg)) {
					std::string errMsg = ("failed to verify zip file: " + extension + " reason: " + errorMsg);
					extensionHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
				else {
					Core::getInstance().log(0, "verified zip file: " + extension);
				}

				ZippedModuleHandler* zfmh = new ZippedModuleHandler(zipPath, extension);
				extensionHandles[extension] = zfmh;

				return zfmh;
			}
			else {
				// Fall through
			}

		}

		if (existsAsFolder || (existsAsFolder && existsAsZip)) {
			FolderFileExtensionHandle* ffeh = new FolderFileExtensionHandle(path, extension);
			extensionHandles[extension] = ffeh;

			return ffeh;
		}

		if (existsAsZip) {
			ZippedExtensionHandler* zfeh = new ZippedExtensionHandler(zipPath, extension);
			extensionHandles[extension] = zfeh;

			return zfeh;
		}

		throw ModuleHandleException("extension does not exist: " + extension);
	};

	// also allows opening Code.zip
	ModuleHandle* getModuleHandle(const std::string& path, const std::string& extension)
	{
		if (moduleHandles.count(extension) == 1) {
			return moduleHandles[extension];
		}

		if (moduleHandleErrors.count(extension) == 1) {
			throw ModuleHandleException(moduleHandleErrors[extension]);
		}

		std::string zipPath = path + ".zip";
		bool existsAsZip = std::filesystem::is_regular_file(zipPath);
		bool existsAsFolder = std::filesystem::is_directory(path);

		if (Core::getInstance().secureMode) {
			if (!existsAsZip) {
				if (existsAsFolder) {
					std::string errMsg = "extension verification error: extension '" + path + "' exists as a folder on the file system but not as a zip file as required in secure mode";
					moduleHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
				else {
					std::string errMsg = ("extension does not exist");
					moduleHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
			}

			std::string errorMsg;
			if (!verifyZipFile(zipPath, extension, errorMsg)) {
				std::string errMsg = ("failed to verify zip file: " + extension + " reason: " + errorMsg);
				moduleHandleErrors[extension] = errMsg;
				throw ModuleHandleException(errMsg);
			}
			else {
				Core::getInstance().log(0, "verified zip file: " + extension);
			}

			ZippedModuleHandler* zfmh = new ZippedModuleHandler(zipPath, extension);
			moduleHandles[extension] = zfmh;

			return zfmh;
		}

		if (existsAsFolder || (existsAsFolder && existsAsZip)) {
			FolderFileModuleHandle* ffmh = new FolderFileModuleHandle(path, extension);
			moduleHandles[extension] = ffmh;
			extensionHandles[extension] = ffmh;
			return ffmh;
		}

		if (existsAsZip) {
			ZippedModuleHandler* zfmh = new ZippedModuleHandler(zipPath, extension);
			moduleHandles[extension] = zfmh;
			extensionHandles[extension] = zfmh;
			return zfmh;
		}

		throw ModuleHandleException("module does not exist: " + extension);
	};

	ModuleHandle* getLatestCodeHandle() {

		if (codeHandle != NULL) {
			return codeHandle;
		}

		// Generalized form: std::regex re("^([A-Za-z0-9_-]+?)-([0-9]+)[.]([0-9]+)[.]([0-9]+)(?:[.]zip)*$");
		std::regex re("^code-([0-9]+)[.]([0-9]+)[.]([0-9]+)(?:[.]zip)*$");

		std::string latestExtension = "";
		long latestV1 = -1;
		long latestV2 = -1;
		long latestV3 = -1;

		if (!std::filesystem::is_directory(Core::getInstance().UCP_DIR)) {
			throw ModuleHandleException("cannot get latest code handle because directory does not exist: " + Core::getInstance().UCP_DIR.string());
		}

		for (auto const& dir_entry : std::filesystem::directory_iterator(Core::getInstance().UCP_DIR)) {
			std::string filename = dir_entry.path().stem().string();

			if (filename == "code") {
				latestExtension = "code";
			}

			std::smatch m;
			if (std::regex_search(filename, m, re)) {
				std::string extension = m[1];
				std::string version1 = m[2];
				std::string version2 = m[3];
				std::string version3 = m[4];

				long v1 = strtol(version1.data(), NULL, 10);
				long v2 = strtol(version2.data(), NULL, 10);
				long v3 = strtol(version3.data(), NULL, 10);

				if (v1 > latestV1) {
					latestV1 = v1;
					latestV2 = v2;
					latestV3 = v3;
					latestExtension = extension;

					continue;
				}

				if (v1 == latestV1) {
					if (v2 > latestV2) {
						latestV1 = v1;
						latestV2 = v2;
						latestV3 = v3;
						latestExtension = extension;

						continue;
					}
					if (v2 == latestV2) {
						if (v3 > latestV3) {
							latestV1 = v1;
							latestV2 = v2;
							latestV3 = v3;
							latestExtension = extension;

							continue;
						}
					}
				}
			}
		}

		if (latestExtension == "" || latestExtension.empty()) {
			throw ModuleHandleException("no code module found.");
		}

		codeHandle = getModuleHandle((Core::getInstance().UCP_DIR / latestExtension).string(), latestExtension);
		return codeHandle;
	}

};