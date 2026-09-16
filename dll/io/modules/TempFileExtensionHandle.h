#pragma once

#include "io/modules/ZipDirectoryListing.h"

#include "io/TempfileManager.h"
#include "io/modules/ModuleHandle.h"


class TempFileExtensionHandle : public virtual ExtensionHandle {

protected:
	zip_t* z;

	std::map<std::string, std::filesystem::path> mapping;

public:

	TempFileExtensionHandle(const std::string& modulePath, const std::string& extension) : ExtensionHandle(extension) {


		z = zip_open(modulePath.c_str(), 0, 'r');

		if (z == NULL) {
			throw InvalidZipFileException("Invalid zip file: " + modulePath);
		}

	}

	~TempFileExtensionHandle() {
		if (z != 0) zip_close(z);
		z = 0;
	}

	int openFileDescriptor(const std::string& path, std::string& error) {

		if (this->mapping.count(path) == 0) {

			char* buf = NULL;
			size_t bufsize = 0;

			if (zip_entry_open(z, path.c_str()) != 0) {
				error = "file '" + path + "'does not exist in extension zip: " + this->name;
				return -1;
			}

			int size = zip_entry_size(z);
			zip_entry_read(z, (void**)&buf, &bufsize);
			zip_entry_close(z);

			if (size != bufsize) {
				error = "could not read all data";
				free(buf);
				return -1;
			}
			
			std::filesystem::path tmpFile;
			if (!TempfileManager::getInstance().createTempFileDescriptor(buf, size, tmpFile, error)) {
				free(buf);
				return -1;
			}

			this->mapping[path] = tmpFile;

			free(buf);
		}

		std::filesystem::path tmpPath = this->mapping.at(path);

		HANDLE handle = CreateFileA(
			tmpPath.string().c_str(),
			GENERIC_READ,
			FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL,
			OPEN_EXISTING,
			FILE_ATTRIBUTE_NORMAL,
			NULL);

		if (handle == INVALID_HANDLE_VALUE) {
			throw ModuleHandleException("error in opening tmp file: " + path + "\n" + error);
		}

		int fd = _open_osfhandle((intptr_t) handle, O_RDONLY | O_BINARY);
		if (fd == -1) {
			throw ModuleHandleException("error in opening file: " + path + "\n" + error);
		}

		return fd;
	}

	FILE* openFilePointer(const std::string& path, std::string& error) {
		int fd = this->openFileDescriptor(path, error);
		if (fd == -1) return NULL;

		FILE* result = _fdopen(fd, "rb");

		if (result == NULL) {
			throw ModuleHandleException("error in opening file: " + path + "\n" + error);
		}

		return result;
	}

	int getFileSize(const std::string& path, std::string& error) {
		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			error = "file '" + path + "' does not exist in extension zip: " + this->name;
			return -1;
		}

		unsigned long long size = zip_entry_size(z);
		zip_entry_close(z);

		return size;
	}

	int getFileContents(const std::string& path, void* buffer, int size, std::string& error) {
		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			error = "file '" + path + "' does not exist in extension zip: " + this->name;
			return -1;
		}

		int read = zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		if (read < 0) {
			error = "error during zip file reading";
			free(buf);
			return -1;
		}

		if (read < size) {
			error = "Read too few bytes";
			free(buf);
			return -1;
		}

		if (read > size) {
			error = "Read too many bytes";
			free(buf);
			return -1;
		}

		memcpy(buffer, buf, size);

		free(buf);

		return bufsize;
	}

	std::vector<std::string> listDirectories(const std::string& path) {
		try {
			return ExtensionListing::zip(z, path, true);
		}
		catch (const std::exception& e) {
			throw ModuleHandleException(e.what());
		}
	}

	std::vector<std::string> listFiles(const std::string& path) {
		try {
			return ExtensionListing::zip(z, path, false);
		}
		catch (const std::exception& e) {
			throw ModuleHandleException(e.what());
		}
	}


};