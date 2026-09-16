#pragma once

#include <lua.hpp>

namespace debugging {
	void logExecution(lua_State* L, lua_Debug* ar);
}