#pragma once

#include "io/modules/FolderFileExtensionHandle.h"

class FolderFileModuleHandle : public ModuleHandle, public FolderFileExtensionHandle {

public:

	FolderFileModuleHandle(const std::string& modulePath, const std::string& extension) : FolderFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		if (loadedLibraries.count(path) == 1) {
			return loadedLibraries[path];
		}

		std::filesystem::path libPath = (this->modulePath / path);
		if (std::filesystem::is_regular_file(libPath)) {
			HMODULE handle = LoadLibraryA(libPath.string().c_str());
			loadedLibraries[path] = handle;
			return handle;
		}
		throw ModuleHandleException("library does not exist: " + libPath.string());
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return GetProcAddress((HMODULE)handle, name.c_str());
	}

};