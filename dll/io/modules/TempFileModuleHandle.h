#pragma once

#include "io/modules/ZipFileModuleHandle.h"
#include "io/modules/TempFileExtensionHandle.h"

class TempFileModuleHandle : public TempFileExtensionHandle, public ModuleHandle {

public:

	TempFileModuleHandle(const std::string& modulePath, const std::string& extension) : TempFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	// This is copy pasted from ZipFileModuleHandle.h inheritance could solve this
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