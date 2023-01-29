
#include "LuaUtil.h"

namespace LuaUtil {

	int luaGetCurrentThreadID(lua_State*L) {

		lua_pushinteger(L, GetCurrentThreadId());

		return 1;
	}

}
