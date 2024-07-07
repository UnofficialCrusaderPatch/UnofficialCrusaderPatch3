#pragma once

#include "framework.h"
#include <io.h>
#include <fcntl.h>
#include <cstdio>

#include <exception>
#include <regex>

#include <string>
#include "core/Core.h"
#include "security/Hash.h"
#include "io/utils.h"
#include "MemoryModule.h"
#include "exceptions/MessageException.h"


class ModuleHandleException : public MessageException {
	using MessageException::MessageException;
};


class InvalidZipFileException : public ModuleHandleException {
	using ModuleHandleException::ModuleHandleException;
};


class ExtensionHandle {

public:
	std::string name;

	ExtensionHandle(const std::string& name) {
		this->name = name;
	};

	virtual FILE* openFilePointer(const std::string& path, std::string& error) = 0;
	virtual int openFileDescriptor(const std::string& path, std::string& error) = 0;
	virtual int getFileSize(const std::string& path, std::string& error) = 0;
	virtual int getFileContents(const std::string& path, void * buffer, int size, std::string& error) = 0;
	virtual std::vector<std::string> listDirectories(const std::string& path) = 0;
	virtual std::vector<std::string> listFiles(const std::string& path) = 0;

};

inline int getFileSizeOfRegularFile(int fd) {
	_lseek(fd, 0L, SEEK_END);
	long res = _tell(fd);
	_close(fd);

	return res;
}

inline int getFileContentsOfRegularFile(int fd, void* buffer, int size, std::string& error) {
	int res = _read(fd, buffer, size);

	_close(fd);

	if (res == 0) {
		error = "Could not read any bytes";
		return -1;
	};

	if (res < size) {
		error = "Read less than requested";
		return -1;
	}

	return res;
}

inline void* loadLibraryIntoMemory(zip_t* z, const std::string& path) {

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

	return handle;
}

inline FARPROC loadFunctionFromMemoryLibrary(void* handle, const std::string& name) {
	return MemoryGetProcAddress(handle, name.c_str());
}

class ModuleHandle : public virtual ExtensionHandle {

protected:
	std::map<std::string, void*> loadedLibraries;

public:
	ModuleHandle(const std::string& name) : ExtensionHandle(name) {};

	virtual void* loadLibrary(const std::string& path) = 0;
	virtual FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) = 0;
};

