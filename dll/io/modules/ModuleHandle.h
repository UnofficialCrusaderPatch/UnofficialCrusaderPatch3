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

class MessageException : public std::exception {
private:
	std::string msg;
public:
	explicit MessageException(std::string msg) {
		this->msg = msg;
	}

	char* what() {
		return msg.data();
	}
};

class ModuleHandleException : public MessageException {
	using MessageException::MessageException;
};

class InvalidZipFileException : public ModuleHandleException {
	using ModuleHandleException::ModuleHandleException;
};



class ModuleHandle {
public:
	std::string name;

	ModuleHandle(std::string name) {
		this->name = name;
	};
	virtual FILE* openFile(const std::string& path, std::string& error) = 0;
	virtual void* loadLibrary(std::string& path) = 0;
	virtual std::vector<std::string> listDirectories(std::string& path) = 0;
	virtual FARPROC loadFunctionFromLibrary(void* handle, std::string name) = 0;

};

class ZipFileModuleHandle : public ModuleHandle {


private:
	zip_t* z;
	std::map<std::string, void*> loadedLibraries;



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

		int fd = _open_osfhandle((intptr_t)read, _O_RDONLY);
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

	ZipFileModuleHandle(std::string modulePath, std::string extension) : ModuleHandle(extension) {


		z = zip_open(modulePath.c_str(), 0, 'r');

		if (z == NULL) {
			throw InvalidZipFileException("Invalid zip file: " + modulePath);
		}

	}

	~ZipFileModuleHandle() {
		if (z != 0) zip_close(z);
		z = 0;
	}

	FILE* openFile(const std::string& path, std::string& error) {
		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			error = "file does not exist in extension zip: " + this->name;
			return NULL;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		std::string fileError;

		FILE* result = setBinaryMemoryFileContents(buf, bufsize, fileError);
		free(buf);

		if (result == NULL) {
			throw ModuleHandleException("error in opening file: " + path + "\n" + fileError);
		}

		return result;
	}

	std::vector<std::string> listDirectories(std::string& path) {
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
				unsigned long long size = zip_entry_size(z);
				unsigned int crc32 = zip_entry_crc32(z);
			}
			zip_entry_close(z);
		}

		return result;
	}

	void* loadLibrary(std::string& path) {
		if (loadedLibraries.count(path) == 1) {
			return loadedLibraries[path];
		}

		unsigned char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			return 0;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		HMEMORYMODULE handle = MemoryLoadLibrary((void*)buf, (size_t)bufsize);
		free(buf);

		if (handle == NULL)
		{
			MessageBoxA(0, ("Cannot load dll from memory: " + path).c_str(), "ERROR", MB_OK);
			return 0;
		}

		loadedLibraries[path] = handle;
		return handle;
	}

	FARPROC loadFunctionFromLibrary(void* handle, std::string name) {
		return MemoryGetProcAddress(handle, name.c_str());
	}
};

class FolderFileModuleHandle : public ModuleHandle {

private:
	std::filesystem::path modulePath;

public:

	FolderFileModuleHandle(std::string modulePath, std::string extension) : ModuleHandle(extension) {
		this->modulePath = std::filesystem::path(modulePath);

	}

	// Only read mode is supported for now...
	FILE* openFile(const std::string& path, std::string& error) {
		std::filesystem::path fullPath = (this->modulePath / path);
		if (!std::filesystem::is_regular_file(fullPath)) {
			error = "not a regular file : " + path;
			return NULL;
		}

		return fopen(fullPath.string().c_str(), "r");
	}

	std::vector<std::string> listDirectories(std::string& path) {

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

	void* loadLibrary(std::string& path) {
		std::filesystem::path libPath = (this->modulePath / path);
		if (std::filesystem::is_regular_file(libPath)) {
			return LoadLibraryA(libPath.string().c_str());
		}
		throw ModuleHandleException("library does not exist: " + libPath.string());
	}

	FARPROC loadFunctionFromLibrary(void* handle, std::string name) {
		return GetProcAddress((HMODULE) handle, name.c_str());
	}

};





class ModuleHandleManager {

private:

	ModuleHandle* codeHandle;
	std::map<std::string, ModuleHandle*> moduleHandles;
	std::map<std::string, std::string> moduleHandleErrors;

	ModuleHandleManager() {

	}

	bool verifyZipFile(std::string path, std::string name, std::string& errorMsg) {
		std::string hash;

		if (!Hasher::getInstance().hashFile(path, hash, errorMsg)) {
			throw ModuleHandleException("failed to hash: " + path + "\n reason: " + errorMsg);
		}

		if (Core::getInstance().getModuleHashStore().verify(name, hash)) {
			return true;
		}

		errorMsg = "hash does not match hash from store: " + name;
		return false;
	}


public:
	static ModuleHandleManager& getInstance()
	{
		static ModuleHandleManager instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}


	ModuleHandleManager(ModuleHandleManager const&) = delete;
	void operator=(ModuleHandleManager const&) = delete;


	// also allows opening Code.zip
	ModuleHandle* getModuleHandle(const std::string& path, const std::string& extension)
	{
		if (moduleHandles.count(extension) == 1) {
			return moduleHandles[extension];
		}

		if (moduleHandleErrors.count(extension) == 1) {
			throw ModuleHandleException(moduleHandleErrors[extension]);
		}

		bool existsAsZip = std::filesystem::is_regular_file(path + ".zip");
		bool existsAsFolder = std::filesystem::is_directory(path);

		if (Core::getInstance().secureMode) {
			if (!existsAsZip) {
				if (existsAsFolder) {
					ModuleHandleException* e = new ModuleHandleException("extension verification error: extension exists as a folder on the file system but not as a zip file as required in secure mode");
					moduleHandleErrors[extension] = e->what();
					throw e;
				}
				else {
					ModuleHandleException* e = new ModuleHandleException("extension does not exist");
					moduleHandleErrors[extension] = e->what();
					throw e;
				}
			}

			std::string errorMsg;
			if (!verifyZipFile(path, extension, errorMsg)) {
				ModuleHandleException* e = new ModuleHandleException("failed to verify zip file: " + extension + " reason: " + errorMsg);
				moduleHandleErrors[extension] = e->what();
				throw errorMsg;
			}

			ZipFileModuleHandle* zfmh = new ZipFileModuleHandle(path, extension);
			moduleHandles[extension] = zfmh;

			return zfmh;
		}

		if (existsAsFolder || (existsAsFolder && existsAsZip)) {
			FolderFileModuleHandle* ffmh = new FolderFileModuleHandle(path, extension);
			moduleHandles[extension] = ffmh;

			return ffmh;
		}

		if (existsAsZip) {
			ZipFileModuleHandle* zfmh = new ZipFileModuleHandle(path, extension);
			moduleHandles[extension] = zfmh;

			return zfmh;
		}

		throw ModuleHandleException("module does not exist: " + extension);
	};

	ModuleHandle* getLatestCodeHandle() {

		if (codeHandle != NULL) {
			return codeHandle;
		}

		// Generalized form: std::regex re("^([A-Za-z0-9_-]+?)-([0-9]+)[.]([0-9]+)[.]([0-9]+)(?:[.]zip)*$");
		std::regex re("^code-([0-9]+)[.]([0-9]+)[.]([0-9]+)(?:[.]zip)*$");

		std::string latestExtension = "";
		long latestV1 = -1;
		long latestV2 = -1;
		long latestV3 = -1;

		for (auto const& dir_entry : std::filesystem::directory_iterator(Core::getInstance().UCP_DIR)) {
			std::string filename = dir_entry.path().stem().string();

			if (filename == "code") {
				latestExtension = "code";
			}

			std::smatch m;
			if (std::regex_search(filename, m, re)) {
				std::string extension = m[1];
				std::string version1 = m[2];
				std::string version2 = m[3];
				std::string version3 = m[4];

				long v1 = strtol(version1.data(), NULL, 10);
				long v2 = strtol(version2.data(), NULL, 10);
				long v3 = strtol(version3.data(), NULL, 10);

				if (v1 > latestV1) {
					latestV1 = v1;
					latestV2 = v2;
					latestV3 = v3;
					latestExtension = extension;

					continue;
				}

				if (v1 == latestV1) {
					if (v2 > latestV2) {
						latestV1 = v1;
						latestV2 = v2;
						latestV3 = v3;
						latestExtension = extension;

						continue;
					}
					if (v2 == latestV2) {
						if (v3 > latestV3) {
							latestV1 = v1;
							latestV2 = v2;
							latestV3 = v3;
							latestExtension = extension;

							continue;
						}
					}
				}
			}
		}

		if (latestExtension == "" || latestExtension.empty()) {
			throw ModuleHandleException("no code module found.");
		}

		codeHandle = getModuleHandle((Core::getInstance().UCP_DIR / latestExtension).string(), latestExtension);
		return codeHandle;
	}

};