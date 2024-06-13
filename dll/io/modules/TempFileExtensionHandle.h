#pragma once

#include <random>
#include <map>
#include <filesystem>
#include "io/modules/ModuleHandle.h"

class TempfileManager {
private:
	std::random_device rd;
	std::mt19937 mt;
	std::uniform_int<int> dist;

	std::filesystem::path tempFolder;

	std::string session;

	bool initialized = false;

	TempfileManager() {};

	int next() {
		return this->dist(this->mt);
	}

	inline void nextFile(std::filesystem::path& path) {
		path = this->tempFolder / (this->session + "-" + std::to_string(this->next()));
	}

public:
	static TempfileManager& getInstance()
	{
		static TempfileManager instance; // Guaranteed to be destroyed.
		// Instantiated on first use.
		return instance;
	}

	TempfileManager(TempfileManager const&) = delete;
	void operator=(TempfileManager const&) = delete;

	bool initialize(const std::string& tempFolder, std::string& error) {
		if (this->initialized) {
			error = "already initialized";
			return false;
		}
		if (tempFolder.empty()) {
			this->tempFolder = "ucp/.cache";
		}
		this->mt = std::mt19937(this->rd());
		this->dist = std::uniform_int<int>(10000000, 99999999);
		this->session = std::to_string(this->next());
		this->tempFolder = tempFolder;
		if (!std::filesystem::exists(this->tempFolder)) {
			if (!std::filesystem::create_directories(this->tempFolder)) {
				error = "could not create directories";
				return false;
			}
		}
		this->initialized = true;
		return true;
	}

	bool createTempFileDescriptor(const char* contents, size_t length, std::filesystem::path& filename, std::string& error) {
		if (!this->initialized) {
			error = "not initialized";
			return false;
		}

		this->nextFile(filename);

		while (std::filesystem::exists(filename)) {
			this->nextFile(filename);
		}

		// This handle gets closed at application death, automatically removing the underlying file!
		HANDLE handle = CreateFileA(
			filename.string().c_str(),
			GENERIC_READ | GENERIC_WRITE,
			FILE_SHARE_DELETE | FILE_SHARE_READ,
			NULL,
			CREATE_ALWAYS,
			FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE,
			NULL);

		if (handle == INVALID_HANDLE_VALUE) {
			error = "could not create temp file";
			return false;
		}

		DWORD written;
		WriteFile(handle, contents, length, &written, NULL);

		if (written < length) {
			error = "did not write all contents";
			return false;
		}

		return true;
	}
};

class TempFileExtensionHandle : public virtual ExtensionHandle {

protected:
	zip_t* z;

	std::map<std::string, std::filesystem::path> mapping;

	// BUG: seek (_lseek) is not supported breaking game files such as gm1 files because the game relies on seek for some file types.
	// It is a strange bug because _tell and _lseek do report the right values, but _read does return the wrong data. I guess Pipes are really just that, Pipes.
	// So, this works for files that only need read() and not seek() such as module code files (.lua files, .dll files, etc.)
	int getFileDescriptor(const char* contents, size_t length, std::string& error) {
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

		return fd;
	}

	int getFileDescriptor(const std::string& contents, std::string& error) {
		return getFileDescriptor(contents.c_str(), contents.size(), error);
	}

	FILE* getFilePointer(const char* contents, size_t length, std::string& error) {
		FILE* f = _fdopen(getFileDescriptor(contents, length, error), "rb");
		if (f == 0) {
			throw ModuleHandleException("couldn't open memory pipe for reading");
		}

		return f;
	}

	FILE* getFilePointer(const std::string& contents, std::string& error) {
		return getFilePointer(contents.c_str(), contents.size(), error);
	}

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
		std::vector<std::string> result;

		//Not sure sanitization is necessary, because zip files cannot really handle weird path names anyway...
		std::string sanitizedPath;
		if (!sanitizeRelativePath(path, sanitizedPath)) {
			throw ModuleHandleException("invalid path: " + path);
		}

		int count = 0;

		std::filesystem::path haystack = std::filesystem::path(path);

		int i, n = zip_entries_total(z);
		for (i = 0; i < n; ++i) {
			zip_entry_openbyindex(z, i);
			{
				const char* name = zip_entry_name(z);
				int isdir = zip_entry_isdir(z);
				// Only directories
				if (isdir) {
					// Only subdirectories of the directly requested path
					std::filesystem::path needle = std::filesystem::path(name);
					std::filesystem::path optionA = haystack.lexically_relative(needle);
					if (optionA.string() == "..") {
						result.push_back(name);
					}
				}
			}
			zip_entry_close(z);
		}

		return result;
	}


	std::vector<std::string> listFiles(const std::string& path) {
		std::vector<std::string> result;

		//Not sure sanitization is necessary, because zip files cannot really handle weird path names anyway...
		std::string sanitizedPath;
		if (!sanitizeRelativePath(path, sanitizedPath)) {
			throw ModuleHandleException("invalid path: " + path);
		}

		int count = 0;

		std::filesystem::path haystack = std::filesystem::path(path);

		int i, n = zip_entries_total(z);
		for (i = 0; i < n; ++i) {
			zip_entry_openbyindex(z, i);
			{
				const char* name = zip_entry_name(z);
				int isdir = zip_entry_isdir(z);
				// Only non-directories
				if (!isdir) {
					// Only subfiles of the directly requested path
					std::filesystem::path needle = std::filesystem::path(name);
					std::filesystem::path optionA = haystack.lexically_relative(needle);
					if (optionA.string() == "..") {
						result.push_back(name);
					}
				}
			}
			zip_entry_close(z);
		}

		return result;
	}

};