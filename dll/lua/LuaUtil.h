#pragma once


#include "framework.h"
#include "lua.hpp"

namespace LuaUtil {
	int luaGetCurrentThreadID(lua_State* L);
	int luaWideCharToMultiByte(lua_State* L);
}
