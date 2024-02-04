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
	virtual std::vector<std::string> listDirectories(const std::string& path) = 0;
	virtual std::vector<std::string> listFiles(const std::string& path) = 0;

};


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


class ZipFileExtensionHandle : public virtual ExtensionHandle {

protected:
	zip_t* z;

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

	FILE* getFilePointer(const char* contents, size_t length, std::string & error) {
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

	ZipFileExtensionHandle(const std::string& modulePath, const std::string& extension) : ExtensionHandle(extension) {


		z = zip_open(modulePath.c_str(), 0, 'r');

		if (z == NULL) {
			throw InvalidZipFileException("Invalid zip file: " + modulePath);
		}

	}

	~ZipFileExtensionHandle() {
		if (z != 0) zip_close(z);
		z = 0;
	}

	int openFileDescriptor(const std::string& path, std::string& error) {
		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			error = "file '" + path + "'does not exist in extension zip: " + this->name;
			return -1;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		std::string fileError;

		int result = getFileDescriptor(buf, bufsize, fileError);
		free(buf);

		if (result == -1) {
			throw ModuleHandleException("error in opening file: " + path + "\n" + fileError);
		}

		return result;
	}

	FILE* openFilePointer(const std::string& path, std::string& error) {
		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(z, path.c_str()) != 0) {
			error = "file '" + path + "' does not exist in extension zip: " + this->name;
			return NULL;
		}

		zip_entry_read(z, (void**)&buf, &bufsize);
		zip_entry_close(z);

		std::string fileError;

		FILE* result = getFilePointer(buf, bufsize, fileError);
		free(buf);

		if (result == NULL) {
			throw ModuleHandleException("error in opening file: " + path + "\n" + fileError);
		}

		return result;
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


class ModuleHandle : public virtual ExtensionHandle {

protected:
	std::map<std::string, void*> loadedLibraries;

public:
	ModuleHandle(const std::string& name) : ExtensionHandle(name) {};

	virtual void* loadLibrary(const std::string& path) = 0;
	virtual FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) = 0;
};


class FolderFileModuleHandle : public ModuleHandle, public FolderFileExtensionHandle {

public:

	FolderFileModuleHandle(const std::string& modulePath, const std::string& extension) : FolderFileExtensionHandle(modulePath, extension), ModuleHandle(extension), ExtensionHandle(extension) {

	}

	void* loadLibrary(const std::string& path) {
		if (loadedLibraries.count(path) == 1) {
			return loadedLibraries[path];
		}

		std::filesystem::path libPath = (this->modulePath / path);
		if (std::filesystem::is_regular_file(libPath)) {
			HMODULE handle = LoadLibraryA(libPath.string().c_str());
			loadedLibraries[path] = handle;
			return handle;
		}
		throw ModuleHandleException("library does not exist: " + libPath.string());
	}

	FARPROC loadFunctionFromLibrary(void* handle, const std::string& name) {
		return GetProcAddress((HMODULE) handle, name.c_str());
	}

};


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


class ModuleHandleManager {

private:

	ModuleHandle* codeHandle = NULL;
	std::map<std::string, ModuleHandle*> moduleHandles;
	std::map<std::string, std::string> moduleHandleErrors;

	std::map<std::string, ExtensionHandle*> extensionHandles;
	std::map<std::string, std::string> extensionHandleErrors;

	ModuleHandleManager() {
		codeHandle = NULL;
	}

	bool verifyZipFile(const std::string& path, const std::string& name, std::string& errorMsg) {
		std::string hash;

		if (!Hasher::getInstance().hashFile(path, hash, errorMsg)) {
			throw ModuleHandleException("failed to hash: " + path + "\n reason: " + errorMsg);
		}

		if (Core::getInstance().getModuleHashStore()->verify(name, hash)) {
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

	/**
		This function works because only one version of any extension can be loaded at the same time.
	*/
	ExtensionHandle* loadedExtensionHandle(const std::string& nameWithoutVersion) {

		for (std::map<std::string, ExtensionHandle*>::iterator iter = this->extensionHandles.begin(); iter != this->extensionHandles.end(); ++iter)
		{
			std::string k = iter->first;
			// First test if the key starts with the extension name
			if (k.rfind(nameWithoutVersion + "-", 0) == 0) {
				// Remove the version portion.
				int lastDashPosition = k.rfind("-");
				if (lastDashPosition == std::string::npos) {
					// We shouldn't get here.
					continue;
				}
				if (k.substr(0, lastDashPosition) == nameWithoutVersion) {
					return iter->second;
				}
			}
		}

		return NULL;
	}

	/**
	This function works because only one version of any extension can be loaded at the same time.
*/
	ModuleHandle* loadedModuleHandle(const std::string& nameWithoutVersion) {

		for (std::map<std::string, ModuleHandle*>::iterator iter = this->moduleHandles.begin(); iter != this->moduleHandles.end(); ++iter)
		{
			std::string k = iter->first;
			// First test if the key starts with the extension name
			if (k.rfind(nameWithoutVersion + "-", 0) == 0) {
				// Remove the version portion.
				int lastDashPosition = k.rfind("-");
				if (lastDashPosition == std::string::npos) {
					// We shouldn't get here.
					continue;
				}
				if (k.substr(0, lastDashPosition) == nameWithoutVersion) {
					return iter->second;
				}
			}
		}

		return NULL;
	}

	ExtensionHandle* getExtensionHandle(const std::string& path, const std::string& extension, bool verifyContents)
	{
		if (extensionHandles.count(extension) == 1) {
			return extensionHandles[extension];
		}

		if (extensionHandleErrors.count(extension) == 1) {
			throw ModuleHandleException(extensionHandleErrors[extension]);
		}

		std::string zipPath = path + ".zip";
		bool existsAsZip = std::filesystem::is_regular_file(zipPath);
		bool existsAsFolder = std::filesystem::is_directory(path);

		if (Core::getInstance().secureMode) {
			if (verifyContents) {
				if (!existsAsZip) {
					if (existsAsFolder) {
						std::string errMsg = "extension verification error: extension '" + path + "' exists as a folder on the file system but not as a zip file as required in secure mode";
						extensionHandleErrors[extension] = errMsg;
						throw ModuleHandleException(errMsg);
					}
					else {
						std::string errMsg = ("extension does not exist");
						extensionHandleErrors[extension] = errMsg;
						throw ModuleHandleException(errMsg);
					}
				}

				std::string errorMsg;
				if (!verifyZipFile(zipPath, extension, errorMsg)) {
					std::string errMsg = ("failed to verify zip file: " + extension + " reason: " + errorMsg);
					extensionHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
				else {
					Core::getInstance().log(0, "verified zip file: " + extension);
				}

				ZipFileModuleHandle* zfmh = new ZipFileModuleHandle(zipPath, extension);
				extensionHandles[extension] = zfmh;

				return zfmh;
			}
			else {
				// Fall through
			}
			
		}

		if (existsAsFolder || (existsAsFolder && existsAsZip)) {
			FolderFileExtensionHandle* ffeh = new FolderFileExtensionHandle(path, extension);
			extensionHandles[extension] = ffeh;

			return ffeh;
		}

		if (existsAsZip) {
			ZipFileExtensionHandle* zfeh = new ZipFileExtensionHandle(zipPath, extension);
			extensionHandles[extension] = zfeh;

			return zfeh;
		}

		throw ModuleHandleException("extension does not exist: " + extension);
	};

	// also allows opening Code.zip
	ModuleHandle* getModuleHandle(const std::string& path, const std::string& extension)
	{
		if (moduleHandles.count(extension) == 1) {
			return moduleHandles[extension];
		}

		if (moduleHandleErrors.count(extension) == 1) {
			throw ModuleHandleException(moduleHandleErrors[extension]);
		}

		std::string zipPath = path + ".zip";
		bool existsAsZip = std::filesystem::is_regular_file(zipPath);
		bool existsAsFolder = std::filesystem::is_directory(path);

		if (Core::getInstance().secureMode) {
			if (!existsAsZip) {
				if (existsAsFolder) {
					std::string errMsg = "extension verification error: extension '" + path + "' exists as a folder on the file system but not as a zip file as required in secure mode";
					moduleHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
				else {
					std::string errMsg = ("extension does not exist");
					moduleHandleErrors[extension] = errMsg;
					throw ModuleHandleException(errMsg);
				}
			}

			std::string errorMsg;
			if (!verifyZipFile(zipPath, extension, errorMsg)) {
				std::string errMsg = ("failed to verify zip file: " + extension + " reason: " + errorMsg);
				moduleHandleErrors[extension] = errMsg;
				throw ModuleHandleException(errMsg);
			}
			else {
				Core::getInstance().log(0, "verified zip file: " + extension);
			}

			ZipFileModuleHandle* zfmh = new ZipFileModuleHandle(zipPath, extension);
			moduleHandles[extension] = zfmh;

			return zfmh;
		}

		if (existsAsFolder || (existsAsFolder && existsAsZip)) {
			FolderFileModuleHandle* ffmh = new FolderFileModuleHandle(path, extension);
			moduleHandles[extension] = ffmh;
			extensionHandles[extension] = ffmh;
			return ffmh;
		}

		if (existsAsZip) {
			ZipFileModuleHandle* zfmh = new ZipFileModuleHandle(zipPath, extension);
			moduleHandles[extension] = zfmh;
			extensionHandles[extension] = zfmh;
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

		if (!std::filesystem::is_directory(Core::getInstance().UCP_DIR)) {
			throw ModuleHandleException("cannot get latest code handle because directory does not exist: " + Core::getInstance().UCP_DIR.string());
		}

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