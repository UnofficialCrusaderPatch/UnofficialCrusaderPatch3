#pragma once

#include <string>
#include <lua.hpp>
#include "io/modules/ModuleManager.h"



namespace LuaIO {
	int luaLoadLibraryRaw(lua_State* L);

	ModuleHandle* getModuleForLibraryPath(std::string const& path, std::string& insidePath, std::string& errorMsg);
}