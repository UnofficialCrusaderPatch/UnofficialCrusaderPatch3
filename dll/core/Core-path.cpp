#include <core/Core-path.h>
#include <regex>
#include <filesystem>

int luaRegisterPathAlias(lua_State* L) {
	std::string alias = luaL_checkstring(L, 1);
	std::string target = luaL_checkstring(L, 2);

	bool overwrite = false;

	if (lua_gettop(L) == 3) {
		luaL_checktype(L, 3, LUA_TBOOLEAN);
		overwrite = lua_toboolean(L, 3);
	}

	if (Core::getInstance().aliasedPaths.count(alias) > 0) {
		if (!overwrite) {
			return luaL_error(L, ("cannot overwrite alias registratrion for path: " + alias + " with: " + target + ". use overwrite = true").c_str());
		}

		Core::getInstance().log(1, "alias registration overwritten for alias: " + alias + " new target: " + target);
	}

	Core::getInstance().aliasedPaths[alias] = target;

	Core::getInstance().log(2, "alias registered for: " + alias + " target: " + target);

	return 0;
}

bool Core::sanitizePath(const std::string& path, std::string& result) {
	std::string rawPath = path;

	//Assert non empty path
	if (rawPath.empty()) {
		result = "empty path";
		return false;
	}

	std::filesystem::path sanitizedPath(rawPath);
	sanitizedPath = sanitizedPath.lexically_normal(); // Remove "/../" and "/./"

	if (!std::filesystem::path(sanitizedPath).is_relative()) {
		result = "path has to be a relative path";
		return false;
	}

	result = sanitizedPath.string();

	//Now we can assume sanitizedPath cannot escape the game directory.
//Let's assert that
	std::filesystem::path a = std::filesystem::current_path();
	std::filesystem::path b = a / result;
	std::filesystem::path r = std::filesystem::relative(b, a);
	if (r.string().find("..") == 0) {

		if (this->debugMode) {
			// Technically not allowed, but we will let it slip because we are debugging
			this->log(1, "the path specified is not a proper relative path. Is it escaping the game directory? path: \n" + r.string());
		}
		else {

			result = "the path specified is not a proper relative path. Is it escaping the game directory? path: \n" + r.string();
			this->log(-1, result);
			return false;
		}
	}

	//Replace \\ with /. Note: don't call make_preferred on the path, it will reverse this change.
	std::replace(result.begin(), result.end(), '\\', '/');

	return true;
}



bool Core::resolveAliasedPath(std::string& path) {

	for (auto const& [alias, resolvedPath] : aliasedPaths) {
		int loc = path.rfind(alias, 0);
		if (loc == 0) {
			path = resolvedPath + path.substr(0 + alias.size());

			return true;
		}

	}

	return false;
}

bool Core::pathIsInPluginDirectory(const std::string& sanitizedPath, std::string& extension, std::string& basePath, std::string& insideExtensionPath) {

	std::regex re("^ucp/+plugins/+([A-Za-z0-9_.-]+)/+(.*)$");
	std::filesystem::path path(sanitizedPath);

	if (sanitizedPath.find("ucp/plugins/") == 0 || sanitizedPath == "ucp/plugins/") {
		std::smatch m;
		if (std::regex_search(sanitizedPath, m, re)) {
			extension = m[1];
			insideExtensionPath = m[2];
			basePath = (Core::getInstance().UCP_DIR / "plugins" / extension).string();
			return true;

		}
		return false;
	}

	return false;
}

bool Core::pathIsInModuleDirectory(const std::string& sanitizedPath, std::string& extension, std::string& basePath, std::string& insideExtensionPath) {

	std::regex re("^ucp/+modules/+([A-Za-z0-9_.-]+)/+(.*)$");
	std::filesystem::path path(sanitizedPath);

	if (sanitizedPath.find("ucp/modules/") == 0 || sanitizedPath == "ucp/modules/") {
		std::smatch m;
		if (std::regex_search(sanitizedPath, m, re)) {
			extension = m[1];
			insideExtensionPath = m[2];
			basePath = (Core::getInstance().UCP_DIR / "modules" / extension).string();
			return true;

		}
		return false;
	}

	return false;
}

bool Core::pathIsInInternalCodeDirectory(const std::string& sanitizedPath, std::string& insideCodePath) {

	std::regex re("^ucp/+code/+(.*)$");
	std::filesystem::path path(sanitizedPath);

	if (sanitizedPath.find("ucp/code/") == 0 || sanitizedPath == "ucp/code/") {
		std::smatch m;
		if (std::regex_search(sanitizedPath, m, re)) {
			insideCodePath = m[1];

			return true;

		}
		return false;
	}

	return false;
}

bool Core::pathIsInCacheDirectory(const std::string& sanitizedPath) {
	std::regex re("^ucp/+.cache/+(.*)$");
	std::filesystem::path path(sanitizedPath);

	if (sanitizedPath.find("ucp/.cache/") == 0 || sanitizedPath == "ucp/.cache/") {
		std::smatch m;
		if (std::regex_search(sanitizedPath, m, re)) {

			return true;

		}
		return false;
	}

	return false;
}