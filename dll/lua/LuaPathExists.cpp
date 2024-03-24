
#include "lua/LuaPathExists.h"

#include <filesystem>

namespace LuaIO {

	int luaPathExists(lua_State* L) {
		std::string rawPath = luaL_checkstring(L, 1);

		try {
			std::filesystem::path path = std::filesystem::path(rawPath);

			bool e = std::filesystem::is_regular_file(path) || std::filesystem::is_directory(path) || std::filesystem::is_symlink(path);

			lua_pushboolean(L, e);

			return 1;
		}
		catch (const std::string& err) {
			return luaL_error(L, ("exists() gave an error. Reason: " + err).c_str());
		}
		catch (...) {
			return luaL_error(L, "exists() gave an unknown error.");
		}
		
	}

}