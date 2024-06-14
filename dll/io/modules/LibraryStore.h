#pragma once

#include "MemoryModule.h"
#include <map>
#include <string>
#include <filesystem>


typedef struct LibraryResolverHelper {
	void* handler = 0;
	bool isCustom = false;
	int depth = 0;
} LibraryResolverHelper;

inline FARPROC customMemoryGetProcAddress(HCUSTOMMODULE module, LPCSTR name, void* userdata);
inline HCUSTOMMODULE customLoadLibraryFromZipDependencyFunction(LPCSTR path, void* userdata);

class LibraryStore {
private:
	std::map<std::string, void*> hmoduleMapping;
	std::map<void*, std::string> reverseHmoduleMapping;
	std::map<std::string, bool> isCustomMapping;

	LibraryStore() {};

	void name(const std::string& path, std::string& name) {
		name = std::filesystem::path(path).filename().string();
	}

public:
	static LibraryStore& getInstance()
	{
		static LibraryStore instance; // Guaranteed to be destroyed.
		// Instantiated on first use.
		return instance;
	}

	LibraryStore(LibraryStore const&) = delete;
	void operator=(LibraryStore const&) = delete;

	void put(const std::string& path, const bool isCustom, void* obj) {
		Core::getInstance().log(1, "putting by path: " + path);

		std::string name;
		this->name(path, name);
		hmoduleMapping[name] = obj;
		isCustomMapping[name] = isCustom;
		reverseHmoduleMapping[obj] = name;
	}

	bool fetch(const std::string& path, bool& isCustom, void** obj) {
		Core::getInstance().log(1, "fetching by path: " + path);
		std::string name;
		*obj = NULL;
		this->name(path, name);
		if (hmoduleMapping.count(name) == 0) {
			HMODULE hm = GetModuleHandleA(name.c_str());
			if (hm != NULL) {
				this->put(path, false, hm);
				*obj = hm;
				return true;
			}
			return false;
		}
		isCustom = isCustomMapping[name];
		*obj = hmoduleMapping[name];

		return true;
	}

	bool fetchByHandle(void* obj, bool& isCustom, std::string& name) {
		Core::getInstance().log(1, "fetching by handle: ");

		if (this->reverseHmoduleMapping.count(obj) == 0) {
			return false;
		}
		// Implement GetModuleName?
		name = this->reverseHmoduleMapping[obj];
		isCustom = this->isCustomMapping[name];

		return true;
	}

	bool exists(const std::string& path) {
		std::string name;
		this->name(path, name);

		return this->hmoduleMapping.count(name) > 0;
	}

	void* putLibrary(const std::string& path) {
		std::string name;
		this->name(path, name);

		Core::getInstance().log(1, "loading library from path: " + path);

		if (std::filesystem::exists(path)) {
			HCUSTOMMODULE handle = MemoryDefaultLoadLibrary(path.c_str(), NULL);
			if (handle == NULL) {
				Core::getInstance().log(1, "loading library from path failed: " + path);
				return NULL;
			}
			this->put(name, false, handle);

			return handle;
		}
		else {
			void* handle = MemoryDefaultLoadLibrary(name.c_str(), NULL);
			if (handle == NULL) {
				Core::getInstance().log(1, "loading library from name failed: " + name);
				return NULL;
			}

			this->put(name, false, handle);

			return handle;
		}
		
		
	}

	void* putLibraryFromZip(const std::string& path, zip_t* z) {
		std::string name;
		this->name(path, name);

		Core::getInstance().log(1, "loading library from zip into memory: " + name);

		unsigned char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			return NULL;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		LibraryResolverHelper lrh;
		lrh.handler = z;
		lrh.isCustom = true;
		lrh.depth = 0;

		HMEMORYMODULE handle = MemoryLoadLibraryEx(
			(void*)buf,
			(size_t)bufsize,
			MemoryDefaultAlloc,
			MemoryDefaultFree,
			customLoadLibraryFromZipDependencyFunction,
			customMemoryGetProcAddress,
			MemoryDefaultFreeLibrary,
			&lrh
		);
		free(buf);

		if (handle == NULL)
		{
			MessageBoxA(0, ("Cannot load dll from memory: " + path).c_str(), "ERROR", MB_OK);
			return NULL;
		}

		this->put(name, true, handle);

		return handle;
	}

	FARPROC loadFunction(void* handle, LPCSTR func) {
		if (reverseHmoduleMapping.count(handle) == 0) {
			return NULL;
		}
		bool isCustom = isCustomMapping[reverseHmoduleMapping[handle]];
		if (!isCustom) {
			return MemoryDefaultGetProcAddress(handle, func, NULL);
		}
		else {
			return MemoryGetProcAddress(handle, func);
		}
	}
};


inline FARPROC customMemoryGetProcAddress(HCUSTOMMODULE module, LPCSTR name, void* userdata) {
	Core::getInstance().log(1, "get proc address: " + std::string(name));

	std::string moduleName;
	bool isCustom;
	void* handle;
	if (LibraryStore::getInstance().fetchByHandle(module, isCustom, moduleName)) {
		if (isCustom) {
			return MemoryGetProcAddress(module, name);
		}
		return MemoryDefaultGetProcAddress(module, name, userdata);
	}

	// We should never get here
	return MemoryDefaultGetProcAddress(module, name, userdata);
}

inline HCUSTOMMODULE customLoadLibraryFromZipDependencyFunction(LPCSTR path, void* userdata) {
	if (path == NULL) return NULL;

	Core::getInstance().log(1, "looking for library dependency: " + std::string(path));

	bool isCustom;
	void* handle;
	if (LibraryStore::getInstance().fetch(path, isCustom, &handle)) {
		Core::getInstance().log(1, "found in store: " + std::string(path));
		return handle;
	}

	LibraryResolverHelper* lrh = (LibraryResolverHelper*)userdata;
	lrh->depth += 1;

	if (lrh->depth <= 1) {
		handle = LibraryStore::getInstance().putLibraryFromZip(path, (zip_t*)lrh->handler);
		if (handle != NULL) return handle;
	}
	else {
		Core::getInstance().log(1, "max depth for zip loading reached for: " + std::string(path));
	}

	Core::getInstance().log(1, "not found in store (not loaded yet?): " + std::string(path));
	// Fail here
	return MemoryDefaultLoadLibrary(path, userdata);
}

