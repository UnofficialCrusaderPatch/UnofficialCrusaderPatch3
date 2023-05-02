
#include "utils.h"
#include "core/Core.h"

#include <shlobj.h>

/**
 * This function takes a path and sanitizes it. The result is in result.
 *
 * \param path the path to sanitize
 * \param result the sanitized path if this function returns true, else the error message
 * \return whether or not the path was succesfully sanitized
 */
bool sanitizeRelativePath(const std::string& path, std::string& result) {
	std::string rawPath = path;

	//Assert non empty path
	if (rawPath.empty()) {
		result = "invalid path";
		return false;
	}



	std::filesystem::path sanitizedPath(rawPath);

	if (!std::filesystem::path(sanitizedPath).is_relative()) {
		result = "path has to be relative";
		return false;
	}

	if (std::filesystem::relative(std::filesystem::current_path() / sanitizedPath, std::filesystem::current_path()).string().find("..") == 0) {
		if (Core::getInstance().debugMode) {
			Core::getInstance().log(0, "path has to remain in the game directory. path: " + sanitizedPath.string());
		}
		else {
			Core::getInstance().log(-1, "path has to remain in the game directory. path: " + sanitizedPath.string());
			result = "path has to remain in the game directory";
			return false;
		}
		
	}

	result = sanitizedPath.string();
	return true;
}

std::vector<unsigned char> HexToBytes(const std::string& hex) {
	std::vector<unsigned char> bytes;

	for (unsigned int i = 0; i < hex.length(); i += 2) {
		std::string byteString = hex.substr(i, 2);
		unsigned char byte = (unsigned char)strtol(byteString.c_str(), NULL, 16);
		bytes.push_back(byte);
	}

	return bytes;
}

bool getAppDataPath(std::filesystem::path& appDataPath) {
	wchar_t* ppszPath;
	HRESULT res = SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &ppszPath);
	if (res == S_OK) {
		appDataPath = std::filesystem::path(ppszPath);
		CoTaskMemFree(ppszPath);
		return true;
	}

	CoTaskMemFree(ppszPath);

	appDataPath = "";
	return false;
}