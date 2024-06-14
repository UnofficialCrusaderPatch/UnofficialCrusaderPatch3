#pragma once

#include "io/modules/ZipFileExtensionHandle.h"
#include "io/modules/LibraryStore.h"

class ZipFileModuleHandle : public ZipFileExtensionHandle, public ModuleHandle {

public:

	ZipFileModuleHandle(const std::string& modulePath, const std::string& extension) : ZipFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		bool isCustom;
		void* obj;
		if (LibraryStore::getInstance().fetch(path, isCustom, &obj)) {
			return obj;
		}

		return LibraryStore::getInstance().putLibraryFromZip(path, z);
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return LibraryStore::getInstance().loadFunction(handle, name.c_str());
	}
};