#pragma once

#include "io/modules/ZipFileModuleHandle.h"
#include "io/modules/TempFileExtensionHandle.h"
#include "io/modules/LibraryStore.h"

class TempFileModuleHandle : public TempFileExtensionHandle, public ModuleHandle {

public:

	TempFileModuleHandle(const std::string& modulePath, const std::string& extension) : TempFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	// This is copy pasted from ZipFileModuleHandle.h inheritance could solve this
	void* loadLibrary(const std::string& path) {
		bool isCustom;
		void* handle;

		Core::getInstance().log(ucp_NamedVerbosity::Verbosity_2, "module '" + this->name + "' loading library: " + path);

		if (LibraryStore::getInstance().fetch(path, isCustom, &handle)) {
			Core::getInstance().log(ucp_NamedVerbosity::Verbosity_2, "module '" + this->name + "' dll found in store");
			return handle;
		}

		return LibraryStore::getInstance().putLibraryFromZipWithFallback(path, z);
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return LibraryStore::getInstance().loadFunction(handle, name.c_str());
	}
};