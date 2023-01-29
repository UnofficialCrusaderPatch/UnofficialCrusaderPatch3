#pragma once

#include "lua.hpp"
//Required for the custom io_open function
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <cstdio>

#include <string>
#include "core/Core.h"
#include "security/InternalData.h"

namespace LuaIO {
	int luaIOCustomOpen(lua_State* L);
}
