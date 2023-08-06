#pragma once

#include <lua.hpp>

namespace LuaYamlParser {
	int luaParseYamlFile(lua_State* L);
	int luaParseYamlContent(lua_State* L);
}