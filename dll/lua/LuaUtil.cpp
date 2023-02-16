
#include "LuaUtil.h"
#include <string>

namespace LuaUtil {

	int luaGetCurrentThreadID(lua_State*L) {

		lua_pushinteger(L, GetCurrentThreadId());

		return 1;
	}

	// When calling this in lua: the first argument should be a table with byte values in it (UTF16 characters, every two bytes being a single character)
	int luaWideCharToMultiByte(lua_State* L)
	{
		luaL_checktype(L, 1, LUA_TTABLE); // check if the first argument is a table
		int size = lua_rawlen(L, 1); // size of the table
		std::string buffer(size, 0);

		for (int i = 0; i < size; i++) {
			lua_rawgeti(L, -1, (i + 1)); // note: lua is 1-based. Pushes the value on the stack
			char value = (char)lua_tointeger(L, -1); // get the value into C++
			buffer[i] = value;
			lua_pop(L, 1); // pop the value from the stack, leaving the table on the stack for the next iteration.
		}

		int size_needed = WideCharToMultiByte(CP_UTF8, 0, (LPCWCH)&buffer[0], size / 2, NULL, 0, NULL, NULL);
		std::string strTo(size_needed, 0);
		WideCharToMultiByte(CP_UTF8, 0, (LPCWCH)&buffer[0], size / 2, &strTo[0], size_needed, NULL, NULL);

		lua_pushstring(L, strTo.c_str());
		return 1;
	}

}
