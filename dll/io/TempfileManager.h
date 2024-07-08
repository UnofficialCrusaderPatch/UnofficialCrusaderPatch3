#pragma once

#include "framework.h"
#include <random>
#include <filesystem>
#include <string>

class TempfileManager {
private:
	std::random_device rd;
	std::mt19937 mt;
	std::uniform_int_distribution<int> dist;

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
		this->dist = std::uniform_int_distribution<int>(10000000, 99999999);
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