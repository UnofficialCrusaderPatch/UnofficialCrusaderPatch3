#pragma once

#include <algorithm>
#include <filesystem>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

// Extension handles accept and return paths relative to the extension root.
// Lua adds the virtual ucp/modules/<name>/ or ucp/plugins/<name>/ prefix.
namespace ExtensionListing {

inline std::string relativePath(std::string path) {
	std::replace(path.begin(), path.end(), '\\', '/');
	if ((!path.empty() && path[0] == '/') || path.find(':') != std::string::npos ||
		path.find('\0') != std::string::npos) {
		throw std::invalid_argument("Invalid extension listing path");
	}
	std::string result;
	for (size_t start = 0; start < path.size();) {
		size_t end = path.find('/', start);
		if (end == std::string::npos) end = path.size();
		const std::string part = path.substr(start, end - start);
		if (part == "..") throw std::invalid_argument("Parent path in extension listing");
		if (!part.empty() && part != ".") {
			if (!result.empty()) result += '/';
			result += part;
		}
		start = end + 1;
	}
	return result;
}

class Children {

	std::string prefix;
	bool directories;
	bool exists;
	std::set<std::string> paths;

public:
	Children(const std::string& path, bool directories) : directories(directories) {
		prefix = relativePath(path);
		exists = prefix.empty();
		if (!prefix.empty()) prefix += '/';
	}

	void add(const std::string& entry, bool isDirectory) {
		const std::string name = relativePath(entry);
		if (isDirectory && name + '/' == prefix) exists = true;
		if (name.compare(0, prefix.size(), prefix) != 0 || name.size() <= prefix.size()) return;
		exists = true;
		const size_t slash = name.find('/', prefix.size());
		if (directories) {
			// A nested file implies its parent even without explicit ZIP directory entries.
			if (slash != std::string::npos) paths.insert(name.substr(0, slash) + '/');
			else if (isDirectory) paths.insert(name + '/');
		}
		else if (!isDirectory && slash == std::string::npos) paths.insert(name);
	}

	std::vector<std::string> result() const {
		if (!exists) throw std::invalid_argument("Not an extension directory: " + prefix);
		return std::vector<std::string>(paths.begin(), paths.end());
	}
};

inline std::vector<std::string> folder(const std::filesystem::path& root,
	const std::string& path, bool directories) {
	const std::string relative = relativePath(path);
	const std::filesystem::path target = root / relative;
	if (!std::filesystem::is_directory(target)) throw std::invalid_argument("Not an extension directory: " + path);
	Children children(relative, directories);
	children.add(relative, true); // An existing empty directory has no iterator entries.
	for (const auto& entry : std::filesystem::directory_iterator(target)) {
		const std::string name = (std::filesystem::path(relative) / entry.path().filename()).generic_string();
		if (entry.is_directory()) children.add(name, true);
		else if (entry.is_regular_file()) children.add(name, false);
	}
	return children.result();
}

}
