
#include "files.h"

#include "core/Core.h"
#include "io/modules/ModuleHandle.h"

// These two functions use basically the same logic except for a minor difference.... simplify?
FILE* getFilePointer(std::string filename, std::string mode, std::string &errorMsg, bool overridePathSanitization) {

	std::string sanitizedPath;

	if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
		if (!overridePathSanitization) {
			errorMsg = ("Invalid path: " + filename + "\n reason: " + sanitizedPath);
			return NULL;
		}
		// Oomph, this hurts a little... but this is here because the game really wants to load from the documents folder, which is fine, but breaks our relative path rule..
		sanitizedPath = filename;
	}

	std::string insidePath;
	ExtensionHandle* mh;
	if (Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, insidePath)) {

		if (mode != "r" && mode != "rb") {
			errorMsg = "invalid file access mode ('" + mode + "') for file path: " + sanitizedPath;
			return NULL;
		}

		try {
			mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
		}
		catch (ModuleHandleException e) {
			errorMsg = e.what();
			return NULL;
		}
	}
	else {

		std::string basePath;
		std::string extension;
		std::string insideExtensionPath;

		if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insidePath)) {

			if (mode != "r" && mode != "rb") {
				errorMsg = "invalid file access mode ('" + mode + "') for file path: " + sanitizedPath;
				return NULL;
			}

			try {
				mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
			}
			catch (ModuleHandleException e) {
				errorMsg = e.what();
				return NULL;
			}

		}
		else {


			if (Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, insidePath)) {

				if (mode != "r" && mode != "rb") {
					errorMsg = "invalid file access mode ('" + mode + "') for file path: " + sanitizedPath;
					return NULL;
				}

				try {
					mh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
				}
				catch (ModuleHandleException e) {
					errorMsg = e.what();
					return NULL;
				}

			}
			else {

				// A regular file outside of the code module or modules directory

				return fopen(sanitizedPath.c_str(), mode.c_str());
			}

		}
	}

	if (mode != "r" && mode != "rb") {
		errorMsg = "invalid file access mode ('" + mode + "') for file path: " + sanitizedPath;
		return NULL;
	}

	// A file inside the code module or the modules directory
	try {
		FILE* f = mh->openFilePointer(insidePath, errorMsg);

		if (f == NULL) {
			return NULL;
		}

		return f;
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return NULL;
	}

}

FILE* getFilePointer(std::string filename, std::string mode, std::string& errorMsg) {
	return getFilePointer(filename, mode, errorMsg, false);
}

int getFileDescriptor(std::string filename, int mode, int perm, std::string& errorMsg, bool overridePathSanitization) {

	std::string sanitizedPath;

	if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
		if (!overridePathSanitization) {
			errorMsg = ("Invalid path: " + filename + "\n reason: " + sanitizedPath);
			return -1;
		}
		// Oomph, this hurts a little... but this is here because the game really wants to load from the documents folder, which is fine, but breaks our relative path rule..
		sanitizedPath = filename;
	}

	std::string insidePath;
	ExtensionHandle* mh;
	if (Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, insidePath)) {

		if (mode != O_RDONLY && mode != O_BINARY) {
			errorMsg = "invalid file access mode ('" + std::to_string(mode) + "') for file path: " + sanitizedPath;
			return -1;
		}

		try {
			mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
		}
		catch (ModuleHandleException e) {
			errorMsg = e.what();
			return -1;
		}
	}
	else {

		std::string basePath;
		std::string extension;
		std::string insideExtensionPath;

		if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insidePath)) {

			if (mode != O_RDONLY && mode != O_BINARY) {
				errorMsg = "invalid file access mode ('" + std::to_string(mode) + "') for file path: " + sanitizedPath;
				return -1;
			}

			try {
				mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
			}
			catch (ModuleHandleException e) {
				errorMsg = e.what();
				return -1;
			}

		}
		else {


			if (Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, insidePath)) {

				if (mode != O_RDONLY && mode != O_BINARY) {
					errorMsg = "invalid file access mode ('" + std::to_string(mode) + "') for file path: " + sanitizedPath;
					return -1;
				}

				try {
					mh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
				}
				catch (ModuleHandleException e) {
					errorMsg = e.what();
					return -1;
				}

			}
			else {

				// A regular file outside of the code module or modules directory
				int f = _open(sanitizedPath.c_str(), mode, perm);
				if (f == -1) {
					errorMsg = "cannot open file: " + sanitizedPath;
					return -1;
				}
				return f;
			}

		}
	}

	if (mode != O_RDONLY && mode != O_BINARY) {
		errorMsg = "invalid file access mode ('" + std::to_string(mode) + "') for file path: " + sanitizedPath;
		return -1;
	}

	// A file inside the code module or the modules directory
	try {
		int f = mh->openFileDescriptor(insidePath, errorMsg);

		return f;
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return -1;
	}

}

int getFileDescriptor(std::string filename, int mode, int perm, std::string& errorMsg) {
	return getFileDescriptor(filename, mode, perm, errorMsg, false);
}