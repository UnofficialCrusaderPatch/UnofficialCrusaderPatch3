#include "ucp3.h"
#include "core/Core.h"
#include "io/modules/ModuleHandle.h"
#include "io/files.h"

std::string errorMsg;

void ucp_initialize() {
	try {
		if (!Core::getInstance().isInitialized) {
			Core::getInstance().initialize();
		}
		else {
			MessageBoxA(NULL, "Cannot initialize UCP Core twice", "FATAL", MB_OK);
			ucp_log(Verbosity_FATAL, "Cannot initialize UCP Core twice");
		}
	}
	catch (ModuleStoreException mse) {
		MessageBoxA(NULL, mse.what(), "FATAL: Extension Store Exception", MB_OK);
	}
	catch (std::exception& e) {
		MessageBoxA(NULL, e.what(), "FATAL", MB_OK);
	}
	
}

void ucp_log(ucp_NamedVerbosity logLevel, const char * logMessage) {
	Core::getInstance().log(logLevel, logMessage);
}

FILE* ucp_getFilePointer(const char * filename, const char * mode) {
	return getFilePointer(filename, mode, errorMsg);
}

int ucp_getFileDescriptor(const char* filename, int mode, int perm) {
	std::string fileNameString = filename;
	return getFileDescriptor(fileNameString, mode, perm, errorMsg);
}

const char * ucp_lastErrorMessage() {
	return errorMsg.c_str();
}

int ucp_logLevel() {
	return Core::getInstance().logLevel;
}

/** 
void ucp_getPathToExtension(const char* extension, const char** path, int* pathSize) {
	std::string p;
	int size;

	// Actual implementation goes here

	if (path == NULL) {
		*pathSize = size;
		return;
	}
	memcpy_s(path, size, p.c_str(), size);
}
*/

FILE* ucp_getFilePointerForFileInExtension(const char* extensionName, const char* path, const char* mode) {

	std::string pathString = path;
	std::string modeString = mode;

	if (modeString != "r" && modeString != "rb") {
		errorMsg = "invalid file access mode ('" + modeString + "') for file path: " + pathString;
		return NULL;
	}
	
	std::string extensionNameString = extensionName;
	ExtensionHandle* eh = ModuleHandleManager::getInstance().loadedExtensionHandle(extensionNameString);
	if (eh == NULL) {
		errorMsg = "no loaded extension handle found for extension name: '" + extensionNameString + "'";
		return NULL;
	}

	try {
		return eh->openFilePointer(pathString, errorMsg);
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return NULL;
	}
	
}

int ucp_getFileDescriptorForFileInExtension(const char* extensionName, const char* path, const char* mode) {

	std::string pathString = path;
	std::string modeString = mode;

	if (modeString != "r" && modeString != "rb") {
		errorMsg = "invalid file access mode ('" + modeString + "') for file path: " + pathString;
		return -1;
	}

	std::string extensionNameString = extensionName;
	ExtensionHandle* eh = ModuleHandleManager::getInstance().loadedExtensionHandle(extensionNameString);
	if (eh == NULL) {
		errorMsg = "no loaded extension handle found for extension name: '" + extensionNameString + "'";
		return -1;
	}

	try {
		return eh->openFileDescriptor(pathString, errorMsg);
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return -1;
	}

}

/**
	Untested!
*/
void * ucp_getProcAddressFromLibraryInModule(const char* moduleName, const char* library, const char* name) {
	std::string moduleNameString = moduleName;
	ModuleHandle* mh = ModuleHandleManager::getInstance().loadedModuleHandle(moduleNameString);

	if (mh == NULL) {
		errorMsg = "no loaded extension handle found for module name: '" + moduleNameString + "'";
		return NULL;
	}

	std::string libraryString = library;
	std::string nameString = name;

	try {
		void* handle = mh->loadLibrary(libraryString);

		if (handle == NULL) {
			errorMsg = "library could not be loaded: '" + libraryString + "'";
			return NULL;
		}

		FARPROC fp = mh->loadFunctionFromLibrary(handle, nameString);

		return fp;
	}
	catch (ModuleHandleException e) {
		errorMsg = e.what();
		return NULL;
	}
	
}
