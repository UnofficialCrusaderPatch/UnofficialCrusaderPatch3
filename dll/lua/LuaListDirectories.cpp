#include "LuaListDirectories.h"

namespace LuaIO {

	// Only for filesystem files: unchecked path!
	int luaListFileSystemDirectories(lua_State* L, bool includeZipFiles) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		int count = 0;

		std::filesystem::path targetPath = rawPath;

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

	int luaZipFileDirectoryIterator(lua_State* L, zip_t* z) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		//Not sure sanitization is necessary, because zip files cannot really handle weird path names anyway...
		std::string sanitizedPath;
		if (!sanitizeRelativePath(rawPath, sanitizedPath)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		int count = 0;

		std::filesystem::path haystack = std::filesystem::path(rawPath);

		int i, n = zip_entries_total(z);
		for (i = 0; i < n; ++i) {
			zip_entry_openbyindex(z, i);
			{
				const char* name = zip_entry_name(z);
				int isdir = zip_entry_isdir(z);
				// Only directories
				if (isdir) {
					// Only subdirectories of the directly requested path
					std::filesystem::path needle = std::filesystem::path(name);
					std::filesystem::path optionA = haystack.lexically_relative(needle);
					if (optionA.string() == "..") {
						lua_pushstring(L, name);
						count += 1;
					}
				}
				unsigned long long size = zip_entry_size(z);
				unsigned int crc32 = zip_entry_crc32(z);
			}
			zip_entry_close(z);
		}

		return count;
	}

	// For internal files
	int luaInternalDirectoryIterator(lua_State* L) {

		if (!initInternalData()) {
			return luaL_error(L, "could not initialize internal data");
		}

		return luaZipFileDirectoryIterator(L, internalDataZip);
	};


	int luaListDirectories(lua_State* L) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());


		std::string sanitizedPath;

		if (!Core::getInstance().sanitizePath(rawPath, sanitizedPath)) {
			return luaL_error(L, ("Invalid path: " + rawPath).c_str());
		}

		bool isInternal;

		std::string extension;
		std::string insideExtensionPath;

		if (Core::getInstance().pathIsInModule(sanitizedPath, extension, insideExtensionPath)) {
			if (Core::getInstance().modulesZipMap.count(extension) == 1) {
				zip_t* z = Core::getInstance().modulesZipMap.at(extension);

				return luaZipFileDirectoryIterator(L, z);
			}
			else if (Core::getInstance().modulesDirMap.count(extension) == 1) {
				if (!Core::getInstance().modulesDirMap.at(extension)) {
					return luaL_error(L, ("Unexpected error when reading: " + sanitizedPath).c_str());
				}

				// Pass through!

			}
			else {
				lua_pushnil(L);
				lua_pushstring(L, ("file does not exist because extension does not exist: " + sanitizedPath).c_str());
				return 2;
			}
		}

		if (!Core::getInstance().resolvePath(rawPath, sanitizedPath, isInternal)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		if (isInternal) {
			throw "internal directory iteration has been deprecated";
			return luaInternalDirectoryIterator(L);
		}
		else {
			lua_pushstring(L, sanitizedPath.c_str());
			lua_replace(L, 1); // Replace the path 

			if (rawPath == "ucp/modules") {
				return luaListFileSystemDirectories(L, true);
			}

			return luaListFileSystemDirectories(L, false);
		}

		return luaListFileSystemDirectories(L, false);
	}

}
