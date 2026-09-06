#pragma once

#include "io/modules/DirectoryListing.h"

#include "io/modules/ModuleHandle.h"

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

		return _open(fullPath.string().c_str(), _O_RDONLY | _O_BINARY);
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
		try {
			return ExtensionListing::folder(this->modulePath, path, true);
		}
		catch (const std::exception& e) {
			throw ModuleHandleException(e.what());
		}
	}

	std::vector<std::string> listFiles(const std::string& path) {
		try {
			return ExtensionListing::folder(this->modulePath, path, false);
		}
		catch (const std::exception& e) {
			throw ModuleHandleException(e.what());
		}
	}


};