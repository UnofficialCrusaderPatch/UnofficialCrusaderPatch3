
#include "files.h"

#include "core/Core.h"
#include "io/modules/ModuleManager.h"


bool getExtensionHandleForFile(
	const std::string& filename, 
	int mode, 
	int perm, 
	bool overridePathSanitization, 
	ExtensionHandle **eh, 
	bool &isRegular, 
	std::string& sanitizedPath, 
	std::string& insidePath, 
	std::string& errorMsg) {

	isRegular = false;

	if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
		if (!overridePathSanitization) {
			errorMsg = ("Invalid path: " + filename + "\n reason: " + sanitizedPath);
			return false;
		}
		// Oomph, this hurts a little... but this is here because the game really wants to load from the documents folder, which is fine, but breaks our relative path rule..
		sanitizedPath = filename;
	}

	if (Core::getInstance().resolveAliasedPath(sanitizedPath)) {
		Core::getInstance().log(1, "path contained an alias, new path: " + sanitizedPath);
	}

	bool isCode = Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, insidePath);
	std::string basePath;
	std::string extension;
	std::string insideExtensionPath;
	bool isModule = Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insidePath);
	bool isPlugin = Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, insidePath);

	if (isCode || isModule || isPlugin) {
		if (mode != (O_RDONLY | O_BINARY)) {
			errorMsg = "invalid file access mode ('" + std::to_string(mode) + "') for file path: " + sanitizedPath;
			return false;
		}
		if (perm != 0) {
			errorMsg = "unimplemented file perm mode ('" + std::to_string(perm) + "') for file path: " + sanitizedPath;
			return false;
		}
	}

	try {
		if (isCode) {
			*eh = ModuleHandleManager::getInstance().getLatestCodeHandle();
		}
		else if (isModule) {
			*eh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
		}
		else if (isPlugin) {
			*eh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
		}
		else {
			isRegular = true;
			eh = NULL;
			return true;
		}
	}
	 catch (ModuleHandleException e) {
		errorMsg = e.what();
		return false;
	}

	 return true;
}

int getFileDescriptor(const std::string &filename, int mode, int perm, std::string& errorMsg, bool overridePathSanitization) {
	std::string regularPath;
	std::string extensionPath;
	bool isRegular;
	ExtensionHandle* eh = 0;
	if (!getExtensionHandleForFile(filename, mode, perm, overridePathSanitization, &eh, isRegular, regularPath, extensionPath, errorMsg)) {
		return -1;
	}
	if (isRegular) {

		int f = _open(regularPath.c_str(), mode, perm);
		if (f == -1) {
			errorMsg = "cannot open file: " + regularPath;
			return -1;
		}
		return f;

	}
	if (eh == NULL) {
		return -1;
	}

	// A file inside the code module or the modules directory
	try {
		int f = eh->openFileDescriptor(extensionPath, errorMsg);

		return f;
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return -1;
	}

}

int getFileDescriptor(const std::string& filename, int mode, int perm, std::string& errorMsg) {
	return getFileDescriptor(filename, mode, perm, errorMsg, false);
}

FILE* getFilePointer(const std::string &filename, const std::string &mode, std::string& errorMsg, const bool overridePathSanitization) {
	int imode = O_RDONLY;
	if (mode == "r") {
		imode = O_RDONLY;
	}
	else if (mode == "rb") {
		imode = O_RDONLY | O_BINARY;
	}
	else if (mode == "w") {
		imode = O_WRONLY;
	}
	else if (mode == "wb") {
		imode = O_WRONLY | O_BINARY;
	}
	else {
		errorMsg = "Unimplemented mode: " + mode;
		return NULL;
	}

	int fd = getFileDescriptor(filename, imode, 0, errorMsg, overridePathSanitization);

	if (fd == -1) {
		return NULL;
	}

	FILE* f = _fdopen(fd, mode.c_str());
	if (f == 0) {
		errorMsg = "Cannot fdopen() file in mode: " + mode;
		return NULL;
	}

	return f;
}

FILE* getFilePointer(const std::string& filename, const std::string& mode, std::string& errorMsg) {
	return getFilePointer(filename, mode, errorMsg, false);
}

int getFileSize(const std::string& filename, std::string& errorMsg) {
	ExtensionHandle* eh = 0;
	bool isRegular = false;
	std::string sanitizedPath;
	std::string insidePath;

	if (!getExtensionHandleForFile(filename, O_RDONLY | O_BINARY, 0, false, &eh, isRegular, sanitizedPath, insidePath, errorMsg)) {
		return -1;
	}

	if (isRegular) {
		int fd = _open(sanitizedPath.c_str(), O_RDONLY | O_BINARY);
		return getFileSizeOfRegularFile(fd);
	}

	if (eh == NULL) {
		return -1;
	}

	try {
		int f = eh->getFileSize(insidePath, errorMsg);

		return f;
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return -1;
	}
}

int getFileContents(const std::string& filename, void* buffer, int size, std::string& errorMsg) {
	ExtensionHandle* eh = 0;
	bool isRegular = false;
	std::string sanitizedPath;
	std::string insidePath;

	if (!getExtensionHandleForFile(filename, O_RDONLY | O_BINARY, 0, false, &eh, isRegular, sanitizedPath, insidePath, errorMsg)) {
		return -1;
	}

	if (isRegular) {
		int fd = _open(sanitizedPath.c_str(), O_RDONLY | O_BINARY);
		return getFileContentsOfRegularFile(fd, buffer, size, errorMsg);
	}

	if (eh == NULL) {
		return -1;
	}

	return eh->getFileContents(insidePath, buffer, size, errorMsg);
}