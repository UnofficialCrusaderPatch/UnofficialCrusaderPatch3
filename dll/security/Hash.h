#pragma once


#include <wincrypt.h>

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


	bool hash(unsigned char* data, size_t dataLen, std::string& result, std::string& error) {

		HCRYPTPROV hProv = NULL;
		HCRYPTHASH hHash = NULL;

		BYTE hash[32];
		DWORD hashLength = 32;

		bool status = false;

		if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT))
		{
			error = ("CryptAcquireContext failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		// Hash the data
		if (!CryptCreateHash(hProv, CALG_SHA_256, NULL, 0, &hHash))
		{
			error = ("CryptCreateHash failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		if (!CryptHashData(hHash, (LPCBYTE)data, dataLen, 0))
		{
			error = printf("CryptHashData failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}


		if (CryptGetHashParam(
			hHash,
			HP_HASHVAL,
			hash,
			&hashLength,
			0))
		{
			result = hexStr(hash, hashLength);
			status = true;
		}
		else
		{
			error = ("Error during reading hash value.");
			goto main_exit;
		}

	main_exit:
		if (hHash) CryptDestroyHash(hHash);
		if (hProv) CryptReleaseContext(hProv, 0);



		return status;
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
