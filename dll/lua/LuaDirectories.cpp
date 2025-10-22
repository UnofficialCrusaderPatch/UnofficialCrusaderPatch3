#include "lua/LuaDirectories.h"

#include "framework.h"
#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include <regex>

#include <string>


#include "core/Core.h"
#include "io/utils.h"

namespace LuaIO {
	int luaMakeDirectory(lua_State* L) {
		std::string path = luaL_checkstring(L, 1);
		bool parents = luaL_opt(L, lua_toboolean, 2, false);

		try {
			auto fsPath = std::filesystem::path(path);
			if (parents) {
				std::filesystem::create_directories(fsPath);
			}
			else {
				std::filesystem::create_directory(fsPath);
			}
			
		}
		catch (std::filesystem::filesystem_error err) {
			lua_pushnil(L);
			lua_pushfstring(L, "cannot create directories for path '%s', reason: %s", path.c_str(), err.what());
			return 2;
		}

		lua_pushboolean(L, true);

		return 1;		
	}
}