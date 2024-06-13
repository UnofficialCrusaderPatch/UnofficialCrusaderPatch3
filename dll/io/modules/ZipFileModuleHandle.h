#pragma once

#include "io/modules/ZipFileExtensionHandle.h"

class ZipFileModuleHandle : public ZipFileExtensionHandle, public ModuleHandle {

public:

	ZipFileModuleHandle(const std::string& modulePath, const std::string& extension) : ZipFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		if (loadedLibraries.count(path) == 1) {
			return loadedLibraries[path];
		}

		loadedLibraries[path] = loadLibraryIntoMemory(z, path);
		return loadedLibraries[path];
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return loadFunctionFromMemoryLibrary(handle, name.c_str());
	}
};