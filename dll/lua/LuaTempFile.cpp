#include "lua/LuaTempFile.h"

#include "io/TempfileManager.h"
#include <filesystem>

namespace LuaIO {
	int luaCreateWriteProtectedTempFile(lua_State* L) {
		size_t size;
		const char* contents = luaL_checklstring(L, 1, &size);

		std::filesystem::path tempFileName;
		std::string err;
		if (!TempfileManager::getInstance().createTempFileDescriptor(contents, size, tempFileName, err)) {
			return luaL_error(L, "could not create temp file: %s", err.c_str());
		}

		lua_pushstring(L, tempFileName.string().c_str());

		return 1;
	}
}