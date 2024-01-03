
#include <core/initialization/ucp-internal.h>

#include <RuntimePatchingSystem.h>

void addUCPInternalFunctions(lua_State* L) {
	lua_newtable(L);
	RPS_initializeLuaAPI("");
	// The namespace is left on the stack. 

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(L, -2, "internal");
	// Our table is left on the stack. Put the table in the global 'ucp' variable.
	lua_setglobal(L, "ucp");
}