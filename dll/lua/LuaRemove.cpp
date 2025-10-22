#include "lua/LuaRemove.h"

#include <string>
#include <filesystem>

namespace LuaIO {
	int luaRemove(lua_State* L) {
		std::string path = luaL_checkstring(L, 1);
		bool recurse = luaL_opt(L, lua_toboolean, 2, false);
		try {
			if (recurse) {
				std::filesystem::remove_all(std::filesystem::path(path));
			}
			else {
				std::filesystem::remove(std::filesystem::path(path));
			}
		}
		catch (std::filesystem::filesystem_error err) {
			lua_pushnil(L);
			lua_pushfstring(L, "cannot remove path '%s', reason: %s", path.c_str(), err.what());
			return 2;
		}

		lua_pushboolean(L, true);

		return 1;
	}
}