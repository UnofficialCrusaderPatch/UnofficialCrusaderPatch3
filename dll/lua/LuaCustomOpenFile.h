#pragma once

#include "framework.h"

#include "lua.hpp"

#include <io.h>
#include <fcntl.h>
#include <cstdio>

#include <string>
#include "core/Core.h"

namespace LuaIO {
	int luaIOCustomOpenFilePointer(lua_State* L);
	int luaIOCustomOpenFileDescriptor(lua_State* L);
	int luaIOCustomOpen(lua_State* L);
	int luaResolveAliasedPath(lua_State* L);
	int luaIOCustomWriteProtectedTempFileOpen(lua_State* L);
}
