#include "lua/LuaRename.h"

#include <string>
#include <filesystem>

namespace LuaIO {
	int luaRename(lua_State* L) {
		std::string from = luaL_checkstring(L, 1);
		std::string to = luaL_checkstring(L, 2);
		try {
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
