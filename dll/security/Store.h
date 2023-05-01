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

#define YAML_CPP_STATIC_DEFINE
#include "yaml-cpp/yaml.h"


class ModuleStoreException : public MessageException {
	using MessageException::MessageException;
};

class Store {

private:
	std::filesystem::path path;
	YAML::Node extensions;

public:

	Store(std::filesystem::path path, bool secureMode) {
		this->path = path;

		if (!secureMode) return;

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

		std::string sigPath = path.string() + ".sig";

		if (!std::filesystem::is_regular_file(sigPath)) {
			throw ModuleStoreException("signature not found: '" + sigPath + "'");
		}

		std::ifstream signature_file_input(sigPath, std::ios::binary);

		std::string signature;

		signature_file_input >> signature;

		signature_file_input.close();

		size_t first_space = signature.find(' ');
		if (first_space != std::string::npos && first_space >= 0) {
			signature = signature.substr(0, first_space);
		}

		if (signature.size() != 1024) {
			throw ModuleStoreException("hash in '" + sigPath + " ' is not of the correct length: '" + std::to_string(signature.size()) + "'");
		}

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

		YAML::Node root = YAML::LoadFile(path.string());

		if (!root.IsMap()) {
			throw ModuleStoreException("invalid store file");
		}

		if (root["ucp-build"].as<std::string>() != "3.0.0") {
			throw ModuleStoreException("store file's ucp version does not match ucp build version");
		}

		if (!root["extensions"]) {
			throw ModuleStoreException("extensions field in store file is not a sequence but NULL");
		}

		extensions = root["extensions"];

		if (!extensions.IsSequence()) {
			throw ModuleStoreException("extensions field in store file is not a sequence");
		}

	}


	/**
		This is the logic to verify extension content.
	*/
	boolean verify(std::string extension, std::string hash) {
		for (std::size_t i = 0; i < extensions.size(); i++) {
			YAML::Node ext = this->extensions[i];
			if (ext["name"].as<std::string>() == extension) {
				if (ext["hash"].as<std::string>() == hash) {
					return true;
				}
			}
		}
		return false;
	}

	/**
		Or more general, including the path to the file
	*/
	/** boolean verifyExtension(std::string extension, std::string path) {
		for (YAML::const_iterator it = this->extensions.begin(); it != this->extensions.end(); ++it) {
			YAML::Node ext = it->as<YAML::Node>();
			if (ext["name"].as<std::string>() == extension) {
				
				std::string hash;
				std::string errorMsg;
				
				if (!Hasher::getInstance().hashFile(path, hash, errorMsg)) {
					throw ModuleStoreException(errorMsg);
				}
				if (ext["hash"].as<std::string>() == hash) {
					return true;
				}
			}
		}
		throw ModuleStoreException("invalid extension");
		return false;
	} */

};
