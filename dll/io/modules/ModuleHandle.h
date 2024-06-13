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

class FolderFileExtensionHandle : public virtual ExtensionHandle {

protected:
	std::filesystem::path modulePath;

public:

	FolderFileExtensionHandle(const std::string& modulePath, const std::string& extension) : ExtensionHandle(extension) {
		this->modulePath = std::filesystem::path(modulePath);
	}

	// Only read mode is supported for now...
	int openFileDescriptor(const std::string& path, std::string& error) {
		std::filesystem::path fullPath = (this->modulePath / path);
		if (!std::filesystem::is_regular_file(fullPath)) {
			error = "file '" + path + "'does not exist in extension: " + this->name;
			return -1;
		}

		return _open(fullPath.string().c_str(), _O_RDONLY | _O_BINARY );
	}

	// Only read mode is supported for now...
	FILE* openFilePointer(const std::string& path, std::string& error) {
		std::filesystem::path fullPath = (this->modulePath / path);
		if (!std::filesystem::is_regular_file(fullPath)) {
			error = "file '" + path + "'does not exist in extension: " + this->name;
			return NULL;
		}

		return fopen(fullPath.string().c_str(), "rb");
	}

	int getFileSize(const std::string& path, std::string& error) {
		int fd = this->openFileDescriptor(path, error);
		if (fd == -1) return -1;

		return getFileSizeOfRegularFile(fd);
	}

	int getFileContents(const std::string& path, void* buffer, int size, std::string& error) {

		int fd = this->openFileDescriptor(path, error);
		if (fd == -1) {
			error = "Could not open file descriptor";
			return -1;
		};

		return getFileContentsOfRegularFile(fd, buffer, size, error);
	}

	std::vector<std::string> listDirectories(const std::string& path) {

		std::vector<std::string> result;

		int count = 0;

		std::filesystem::path targetPath = path;

		if (!std::filesystem::is_directory(targetPath)) {
			throw ModuleHandleException("not a directory: " + this->modulePath.string() + "/" + path);
		}

		const std::filesystem::path zipExtension(".zip");

		try {
			for (const std::filesystem::directory_entry& entry : std::filesystem::directory_iterator(targetPath)) {
				if (entry.is_directory()) {
					result.push_back((entry.path().string() + "/"));
					count += 1;
				}

				else {
					if (entry.is_regular_file() && entry.path().extension() == ".zip") {
						const std::string p = entry.path().string();
						size_t lastIndex = p.find_last_of(".");
						if (lastIndex != std::string::npos) {
							result.push_back((p.substr(0, lastIndex) + "/"));
							count += 1;
						}

					}
				}
			}
		}
		catch (std::filesystem::filesystem_error e) {
			throw ModuleHandleException("Cannot find the path: " + e.path1().string());
		}

		return result;
	}

	std::vector<std::string> listFiles(const std::string& path) {

		std::vector<std::string> result;

		int count = 0;

		std::filesystem::path targetPath = path;

		if (!std::filesystem::is_directory(targetPath)) {
			throw ModuleHandleException("not a directory: " + this->modulePath.string() + "/" + path);
		}

		const std::filesystem::path zipExtension(".zip");

		try {
			for (const std::filesystem::directory_entry& entry : std::filesystem::directory_iterator(targetPath)) {
				result.push_back((entry.path().string()));
				count += 1;
			}
		}
		catch (std::filesystem::filesystem_error e) {
			throw ModuleHandleException("Cannot find the path: " + e.path1().string());
		}

		return result;
	}

};


class ModuleHandle : public virtual ExtensionHandle {

protected:
	std::map<std::string, void*> loadedLibraries;

public:
	ModuleHandle(const std::string& name) : ExtensionHandle(name) {};

	virtual void* loadLibrary(const std::string& path) = 0;
	virtual FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) = 0;
};

