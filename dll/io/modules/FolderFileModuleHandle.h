#pragma once

#include "io/modules/FolderFileExtensionHandle.h"


class FolderFileModuleHandle : public ModuleHandle, public FolderFileExtensionHandle {

public:

	FolderFileModuleHandle(const std::string& modulePath, const std::string& extension) : FolderFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		bool isCustom;
		void* handle;
		if (LibraryStore::getInstance().fetch(path, isCustom, &handle)) {
			return handle;
		}

		std::filesystem::path fullPath = this->modulePath / path;

		std::string error;
		int size = this->getFileSize(path, error);
		if (size == -1) {
			handle = MemoryDefaultLoadLibrary(path.c_str(), NULL);
			if (handle == NULL) {
				throw ModuleHandleException("library does not exist: " + path);
			}
			LibraryStore::getInstance().put(path, false, handle);
			return handle;
}

		handle = LibraryStore::getInstance().putLibrary(fullPath.string());
		if (handle == NULL) {
			throw ModuleHandleException("library does not exist: " + path);
		}

		return handle;
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return LibraryStore::getInstance().loadFunction(handle, name.c_str());
	}



};

