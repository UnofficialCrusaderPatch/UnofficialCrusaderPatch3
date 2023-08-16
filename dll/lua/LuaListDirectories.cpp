#include "LuaListDirectories.h"
#include "io/modules/ModuleHandle.h"

namespace LuaIO {

	// Only for filesystem files: unchecked path!
	int luaListFileSystemDirectories(lua_State* L, bool includeZipFiles) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		int count = 0;

		std::filesystem::path targetPath = rawPath;
		if (rawPath.substr(0, 4) == "ucp/") {
			targetPath = Core::getInstance().UCP_DIR / rawPath.substr(4);
		}
		

		const std::filesystem::path zipExtension(".zip");



		try {
			for (const std::filesystem::directory_entry& entry : std::filesystem::directory_iterator(targetPath)) {
				if (entry.is_directory()) {
					lua_pushstring(L, (entry.path().string() + "/").c_str());
					count += 1;
				}

				else {
					if (includeZipFiles) {
						if (entry.is_regular_file() && entry.path().extension() == ".zip") {
							const std::string p = entry.path().string();
							size_t lastIndex = p.find_last_of(".");
							if (lastIndex != std::string::npos) {
								lua_pushstring(L, (p.substr(0, lastIndex) + "/").c_str());
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

		return count;
	}



	int luaListDirectories(lua_State* L) {
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
			for (std::string entry : entries) {
				lua_pushstring(L, entry.c_str());
			}

			return entries.size();
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
			for (std::string entry : entries) {
				lua_pushstring(L, entry.c_str());
			}

			return entries.size();
		}

		lua_pushstring(L, sanitizedPath.c_str());
		lua_replace(L, 1); // Replace the path 

		if (rawPath == "ucp/modules" || rawPath == "ucp/modules/") {



			return luaListFileSystemDirectories(L, true);
		}

		return luaListFileSystemDirectories(L, false);
	}

}
