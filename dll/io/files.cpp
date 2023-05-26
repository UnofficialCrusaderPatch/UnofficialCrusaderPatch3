
#include "files.h"

#include "core/Core.h"
#include "io/modules/ModuleHandle.h"

FILE* getFileHandle(std::string filename, std::string mode, std::string &errorMsg) {

	std::string sanitizedPath;

	if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
		errorMsg = ("Invalid path: " + filename + "\n reason: " + sanitizedPath);
		return NULL;
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
		FILE* f = mh->openFile(insidePath, errorMsg);

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