#include "lua/LuaRename.h"

#include <string>
#include <filesystem>

namespace LuaIO {
	// Whether path resolves, following links, to an entry inside the canonical folder
	static bool isInside(const std::filesystem::path& folder, const std::string& path) {
		const std::filesystem::path relative = std::filesystem::weakly_canonical(std::filesystem::path(path)).lexically_relative(folder);
		return !relative.empty() && relative != "." && *relative.begin() != "..";
	}

	// rename(folder, from, to): both paths must resolve inside the existing folder
	int luaRename(lua_State* L) {
		std::string folder = luaL_checkstring(L, 1);
		std::string from = luaL_checkstring(L, 2);
		std::string to = luaL_checkstring(L, 3);
		try {
			const std::filesystem::path root = std::filesystem::canonical(std::filesystem::path(folder));
			if (!isInside(root, from) || !isInside(root, to)) {
				lua_pushnil(L);
				lua_pushfstring(L, "cannot rename path '%s' to '%s', reason: the paths must stay inside '%s'", from.c_str(), to.c_str(), folder.c_str());
				return 2;
			}
			std::filesystem::rename(std::filesystem::path(from), std::filesystem::path(to));
		}
		catch (std::filesystem::filesystem_error err) {
			lua_pushnil(L);
			lua_pushfstring(L, "cannot rename path '%s' to '%s', reason: %s", from.c_str(), to.c_str(), err.what());
			return 2;
		}

		lua_pushboolean(L, true);

		return 1;
	}
}
