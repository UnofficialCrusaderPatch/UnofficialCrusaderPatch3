#pragma once

#include "framework.h"
#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include <regex>

#include <string>
#include "lua.hpp"

#include "core/Core.h"
#include "io/utils.h"

namespace LuaIO {
	int luaListDirectories(lua_State* L);
}
