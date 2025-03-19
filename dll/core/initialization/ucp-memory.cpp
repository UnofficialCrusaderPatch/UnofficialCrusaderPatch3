
#include "core/initialization/ucp-memory.h"
#include "lua/LuaLoadLibraryRaw.h"


void addUCPMemoryFunctions(lua_State* L) {
	// stack:
	lua_getglobal(L, "ucp");

	// stack: ucp
	lua_newtable(L);

	// stack: ucp, table
	lua_pushcclosure(L, LuaIO::luaLoadLibraryRaw, 0);
	// stack: ucp, table, func
	lua_setfield(L, -2, "openLibraryHandle");
	// stack: ucp, table

	lua_setfield(L, -2, "library");
	// stack: ucp

	lua_pop(L, 1);

	// stack:
}