
#include <core/initialization/ucp-internal.h>

#include <RuntimePatchingSystem.h>

#include "framework.h"
#include <psapi.h>
#include <vector>

#include "core/Core.h"
#include "io/files.h"
#include "security/Hash.h"

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

// Returns the SHA-256 of a file as lowercase hex, or nil and a message. The path is checked and resolved like io.open's.
static int luaSha256File(lua_State* L) {
	const std::string path = luaL_checkstring(L, 1);
	std::string error;
	FILE* file = getFilePointer(path, "rb", error);
	if (file == NULL) {
		lua_pushnil(L);
		lua_pushstring(L, error.c_str());
		return 2;
	}
	std::vector<unsigned char> contents;
	unsigned char buffer[65536];
	size_t read;
	while ((read = fread(buffer, 1, sizeof(buffer), file)) > 0) {
		contents.insert(contents.end(), buffer, buffer + read);
	}
	const bool failed = ferror(file) != 0;
	fclose(file);
	std::string hash;
	if (failed) {
		error = "cannot read file: " + path;
	}
	else if (Hasher::getInstance().hash(contents.data(), contents.size(), hash, error)) {
		lua_pushstring(L, hash.c_str());
		return 1;
	}
	lua_pushnil(L);
	lua_pushstring(L, error.c_str());
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

	lua_pushcfunction(L, luaSha256File);
	lua_setfield(L, -2, "sha256File");

	// Set the namespace to the 'internal' field in our table.
	lua_setfield(L, -2, "internal");

	// stack: ucp
	lua_pop(L, 1);

	// stack:
}