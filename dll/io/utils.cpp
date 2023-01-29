
#include "utils.h"
#include <filesystem>

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
		result = "path has to remain in the game directory";
		return false;
	}

	result = sanitizedPath.string();
	return true;
}

