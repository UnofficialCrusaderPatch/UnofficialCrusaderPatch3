
#include <core/initialization/ucp-internal.h>

#include <RuntimePatchingSystem.h>

#include "framework.h"
#include <psapi.h>

// Returns the first and the last address of the game executable's image
static int luaGetMainImageRange(lua_State* L) {
	MODULEINFO info = {};
	if (!GetModuleInformation(GetCurrentProcess(), GetModuleHandleW(NULL), &info, sizeof(info))) {
		return luaL_error(L, "cannot read the game executable's module information, error %d", (int) GetLastError());
	}
	const DWORD base = (DWORD) info.lpBaseOfDll;
	lua_pushinteger(L, base);
	lua_pushinteger(L, base + info.SizeOfImage - 1);
	return 2;
}

void addUCPInternalFunctions(lua_State* L) {
	// stack:
	lua_getglobal(L, "ucp");

	// stack: ucp
	RPS_initializeLuaAPI("");
	// stack: ucp  rps

	lua_pushcfunction(L, luaGetMainImageRange);
	lua_setfield(L, -2, "getMainImageRange");

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(L, -2, "internal");

	// stack: ucp
	lua_pop(L, 1);

	// stack:
}