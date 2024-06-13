#pragma once

#include "io/modules/ZipFileExtensionHandle.h"

class ZipFileModuleHandle : public ZipFileExtensionHandle, public ModuleHandle {

private:

	FILE* setBinaryMemoryFileContents(const char* contents, size_t length, std::string& error) {
		HANDLE read;
		HANDLE write;

		// A Pipe's resources are only freed after both handles are closed. But since _open_osfhandle involves a transfer of ownwership, I don't think we need flcose because lua will do that for us.
		// https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/open-osfhandle?view=msvc-170
		if (!CreatePipe(&read, &write, NULL, length)) {
			throw ModuleHandleException("couldn't create anonymous pipe");
		}

		DWORD written;
		WriteFile(write, contents, length, &written, NULL);

		//We can close this already because this is the only time we write contents to it.
		CloseHandle(write);

		if (written != length) {
			throw ModuleHandleException("couldn't write all contents to memory pipe");
		}

		int fd = _open_osfhandle((intptr_t)read, _O_RDONLY | _O_BINARY);
		if (fd == -1) {
			throw ModuleHandleException("couldn't create handle to memory pipe");
		}

		FILE* f = _fdopen(fd, "r");
		if (f == 0) {
			throw ModuleHandleException("couldn't open memory pipe for reading");
		}

		return f;
	}

	FILE* setMemoryFileContents(std::string contents, std::string& error) {
		return setBinaryMemoryFileContents(contents.c_str(), contents.size(), error);
	}

public:

	ZipFileModuleHandle(const std::string& modulePath, const std::string& extension) : ZipFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		if (loadedLibraries.count(path) == 1) {
			return loadedLibraries[path];
		}

		unsigned char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			throw ModuleHandleException("library does not exist: " + path);
			// return NULL;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		HMEMORYMODULE handle = MemoryLoadLibrary((void*)buf, (size_t)bufsize);
		free(buf);

		if (handle == NULL)
		{
			MessageBoxA(0, ("Cannot load dll from memory: " + path).c_str(), "ERROR", MB_OK);
			return NULL;
		}

		loadedLibraries[path] = handle;
		return handle;
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return MemoryGetProcAddress(handle, name.c_str());
	}
};