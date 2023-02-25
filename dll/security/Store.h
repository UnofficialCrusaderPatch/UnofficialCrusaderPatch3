#pragma once
#include "framework.h"
#include <string>

#include <sstream>

#include <filesystem>
#include <sstream>
#include <fstream>


#include "security/Signature.h"
#include "exceptions/MessageException.h"
#include "io/utils.h"


class ModuleStoreException : public MessageException {
	using MessageException::MessageException;
};

class Store {

private:
	std::filesystem::path path;
	bool secureMode;

public:

	Store(std::filesystem::path path, bool secureMode) {
		this->path = path;
		this->secureMode = secureMode;

		if (!secureMode) {
			return;
		}

		if (!std::filesystem::is_regular_file(path)) {

			std::string error = "file does not exist: " + path.string();

			MessageBoxA(NULL, error.c_str(), "failure to load store", MB_OK);

			throw ModuleStoreException(error);
		}

		std::ifstream store_file_input(path.string(), std::ios::binary);

		std::vector<char> store_file_bytes(
			(std::istreambuf_iterator<char>(store_file_input)),
			(std::istreambuf_iterator<char>()));

		store_file_input.close();

		std::ifstream signature_file_input(path.string() + ".sig", std::ios::binary);

		std::string signature;

		signature_file_input >> signature;

		signature_file_input.close();

		std::vector<unsigned char> signature_file_bytes = HexToBytes(signature);

		std::reverse(signature_file_bytes.begin(), signature_file_bytes.end());

		std::string error = "";
		if (!SignatureVerifier::getInstance().verify(
			(unsigned char*)store_file_bytes.data(),
			store_file_bytes.size(),
			(unsigned char*)signature_file_bytes.data(),
			signature_file_bytes.size(), error)) {

			std::string msg = "failed to verify module store signature:\n" + error;
			MessageBoxA(NULL, msg.c_str(), "failed to verify module store", MB_OK);

			throw ModuleStoreException(msg);
		}


	}

	bool verify(std::string extension, std::string hash) {
		return secureMode;
	}

};
