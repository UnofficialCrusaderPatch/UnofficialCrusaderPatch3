#pragma once

#include "framework.h"

#include "lua.hpp"

#include <io.h>
#include <fcntl.h>
#include <cstdio>

#include <string>
#include "core/Core.h"

namespace LuaIO {
	int luaIOCustomOpen(lua_State* L);
}