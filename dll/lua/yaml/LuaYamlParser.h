#pragma once

#include <lua.hpp>

namespace LuaYamlParser {
	// Will break if yml is more nested than 255, because lua implementation uses recursion and the stack limit is 255.
	int luaParseYamlContent(lua_State* L);
}