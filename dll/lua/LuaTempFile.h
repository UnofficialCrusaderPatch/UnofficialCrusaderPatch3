#pragma once

#include "framework.h"
#include "lua.hpp"

namespace LuaIO {
	int luaCreateWriteProtectedTempFile(lua_State* L);
}
