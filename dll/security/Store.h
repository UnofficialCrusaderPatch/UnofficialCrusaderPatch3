#pragma once
#include "framework.h"
#include <string>

#include <sstream>

#include <filesystem>
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

		std::string errorMsg;
		if (!SignatureVerifier::getInstance().verifyFile(path, path.string() + ".sig", errorMsg)) {
			MessageBoxA(NULL, errorMsg.c_str(), "store could not be verified", MB_OK);
			throw ModuleStoreException("store could not be verified: " + errorMsg);
		}

		YAML::Node root = YAML::LoadFile(path.string());

		if (!root.IsMap()) {
			throw ModuleStoreException("invalid store file");
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
