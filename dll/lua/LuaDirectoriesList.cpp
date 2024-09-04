#include "lua/LuaDirectoriesList.h"
#include "io/modules/ModuleManager.h"

namespace LuaIO {

	int luaDirectoriesList(lua_State* L) {

		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());


		std::string sanitizedPath;

		if (!Core::getInstance().sanitizePath(rawPath, sanitizedPath)) {
			return luaL_error(L, ("Invalid path: " + rawPath).c_str());
		}

		if (Core::getInstance().resolveAliasedPath(sanitizedPath)) {
			Core::getInstance().log(1, "path contained an alias, new path: " + sanitizedPath);
		}

		std::string extension;
		std::string insideExtensionPath;
		std::string basePath;
		ModuleHandle* mh;

		if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insideExtensionPath)) {
			try {
				mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
			}
			catch (ModuleHandleException e) {
				return luaL_error(L, e.what());
			}

			std::vector<std::string> entries = mh->listDirectories(rawPath);

			lua_createtable(L, 0, 0);
			int count = 0;

			for (std::string entry : entries) {
				lua_pushstring(L, entry.c_str());
				lua_seti(L, -2, count + 1);
				count += 1;
			}

			return 1;
		}

		ExtensionHandle* eh;

		if (Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, insideExtensionPath)) {
			try {
				eh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
			}
			catch (ModuleHandleException e) {
				return luaL_error(L, e.what());
			}

			std::vector<std::string> entries = eh->listDirectories(rawPath);

			lua_createtable(L, 0, 0);
			int count = 0;

			for (std::string entry : entries) {
				lua_pushstring(L, entry.c_str());
				lua_seti(L, -2, count + 1);
				count += 1;
			}

			return 1;
		}

		const bool includeZipFiles = (rawPath == "ucp/modules" || rawPath == "ucp/modules/");

		std::filesystem::path targetPath = sanitizedPath;
		if (sanitizedPath.substr(0, 4) == "ucp/") {
			targetPath = Core::getInstance().UCP_DIR / sanitizedPath.substr(4);
		}

		const std::filesystem::path zipExtension(".zip");

		lua_createtable(L, 0, 0);
		int count = 0;

		try {
			for (const std::filesystem::directory_entry& entry : std::filesystem::directory_iterator(targetPath)) {
				if (entry.is_directory()) {
					lua_pushstring(L, (entry.path().string() + "/").c_str());
					lua_seti(L, -2, count + 1);
					count += 1;
				}

				else {
					if (includeZipFiles) {
						if (entry.is_regular_file() && entry.path().extension() == ".zip") {
							const std::string p = entry.path().string();
							size_t lastIndex = p.find_last_of(".");
							if (lastIndex != std::string::npos) {
								lua_pushstring(L, (p.substr(0, lastIndex) + "/").c_str());
								lua_seti(L, -2, count + 1);
								count += 1;
							}

						}
					}
				}
			}
		}
		catch (std::filesystem::filesystem_error e) {
			return luaL_error(L, ("Cannot find the path: " + e.path1().string()).c_str());
		}

		// Return the table
		return 1;
	}

}