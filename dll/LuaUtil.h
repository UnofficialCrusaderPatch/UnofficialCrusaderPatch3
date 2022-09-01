#pragma once


#include "framework.h"
#include "lua.hpp"

namespace LuaUtil {
	int luaGetCurrentThreadID(lua_State* L);
}
