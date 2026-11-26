
#include <core/initialization/ucp-internal.h>

#include <RuntimePatchingSystem.h>

#include "framework.h"
#include <psapi.h>
#include <memory>

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

// The SHA-256 of a file as lowercase hex. The path is resolved like io.open's, including aliases.
static bool sha256File(const std::string& path, std::string& hash, std::string& error) {
	try {
		std::unique_ptr<FILE, decltype(&fclose)> file(getFilePointer(path, "rb", error), &fclose);
		if (!file) {
			if (error.empty()) error = "cannot open file: " + path;
			return false;
		}
		return Hasher::getInstance().hash(file.get(), hash, error);
	}
	catch (const std::exception& e) {
		error = e.what();
	}
	catch (...) {
		error = "cannot hash the file";
	}
	return false;
}

// Returns the SHA-256 of a file as lowercase hex, or nil and a message.
static int luaSha256File(lua_State* L) {
	const std::string path = luaL_checkstring(L, 1);
	std::string hash;
	std::string error;
	if (sha256File(path, hash, error)) {
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