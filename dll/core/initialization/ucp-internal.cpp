
#include <core/initialization/ucp-internal.h>

#include <RuntimePatchingSystem.h>

void addUCPInternalFunctions(lua_State* L) {
	// stack:
	lua_getglobal(L, "ucp");

	// stack: ucp
	RPS_initializeLuaAPI("");
	// stack: ucp  rps

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(L, -2, "internal");

	// stack: ucp
	lua_pop(L, 1);

	// stack:
}