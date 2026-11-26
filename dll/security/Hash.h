#pragma once


#include <wincrypt.h>

#include <functional>
#include <iomanip>
#include <sstream>

#include <filesystem>
#include <sstream>
#include <fstream>


class Hasher {
private:
	Hasher() {};


	std::string hexStr(const uint8_t* data, int len)
	{
		std::stringstream ss;
		ss << std::hex;

		for (int i(0); i < len; ++i)
			ss << std::setw(2) << std::setfill('0') << (int)data[i];

		return ss.str();
	}

	std::vector<unsigned char> HexToBytes(const std::string& hex) {
		std::vector<unsigned char> bytes;

		for (unsigned int i = 0; i < hex.length(); i += 2) {
			std::string byteString = hex.substr(i, 2);
			unsigned char byte = (unsigned char)strtol(byteString.c_str(), NULL, 16);
			bytes.push_back(byte);
		}

		return bytes;
	};

public:
	static Hasher& getInstance()
	{
		static Hasher    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}


	Hasher(Hasher const&) = delete;
	void operator=(Hasher const&) = delete;


	static std::string cryptError(const char* function) {
		const DWORD code = GetLastError();
		std::stringstream ss;
		ss << function << " failed with error 0x" << std::hex << std::setw(8) << std::setfill('0') << code;
		return ss.str();
	}

	// SHA-256 of the data that `feed` passes to CryptHashData.
	bool hash(const std::function<bool(HCRYPTHASH, std::string&)>& feed, std::string& result, std::string& error) {
		HCRYPTPROV hProv = NULL;
		HCRYPTHASH hHash = NULL;
		BYTE hash[32];
		DWORD hashLength = 32;
		bool status = false;

		if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT)) {
			error = cryptError("CryptAcquireContext");
		}
		else if (!CryptCreateHash(hProv, CALG_SHA_256, NULL, 0, &hHash)) {
			error = cryptError("CryptCreateHash");
		}
		else if (feed(hHash, error)) {
			if (CryptGetHashParam(hHash, HP_HASHVAL, hash, &hashLength, 0)) {
				result = hexStr(hash, hashLength);
				status = true;
			}
			else {
				error = cryptError("CryptGetHashParam");
			}
		}

		if (hHash) CryptDestroyHash(hHash);
		if (hProv) CryptReleaseContext(hProv, 0);

		return status;
	}

	bool hash(unsigned char* data, size_t dataLen, std::string& result, std::string& error) {
		return hash([&](HCRYPTHASH hHash, std::string& message) {
			if (CryptHashData(hHash, (const BYTE*)data, dataLen, 0)) return true;
			message = cryptError("CryptHashData");
			return false;
		}, result, error);
	}

	// Reads `file` to its end in chunks.
	bool hash(FILE* file, std::string& result, std::string& error) {
		return hash([&](HCRYPTHASH hHash, std::string& message) {
			BYTE buffer[65536];
			size_t read;
			while ((read = fread(buffer, 1, sizeof(buffer), file)) > 0) {
				if (!CryptHashData(hHash, buffer, (DWORD)read, 0)) {
					message = cryptError("CryptHashData");
					return false;
				}
			}
			if (ferror(file)) {
				message = "cannot read the file";
				return false;
			}
			return true;
		}, result, error);
	}

	bool hashFile(const std::string path, std::string& hash, std::string& errorMsg) {
		std::filesystem::path fpath = std::filesystem::path(path);
		if (!std::filesystem::is_regular_file(fpath)) {
			errorMsg = "not a regular file: " + path;
			return false;
		}

		std::ifstream input(fpath.string(), std::ios::binary);

		std::vector<char> bytes(
			(std::istreambuf_iterator<char>(input)),
			(std::istreambuf_iterator<char>()));

		input.close();

		return this->hash((unsigned char*) bytes.data(), bytes.size(), hash, errorMsg);
	}

};
