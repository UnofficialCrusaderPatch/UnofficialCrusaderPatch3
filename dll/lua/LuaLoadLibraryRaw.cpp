
#include "lua/LuaLoadLibraryRaw.h"

#include "io/utils.h"

namespace LuaIO {



	ModuleHandle* getModuleForLibraryPath(std::string const& path, std::string& insidePath, std::string& errorMsg) {

		ModuleHandle* mh = NULL;
		if (Core::getInstance().pathIsInInternalCodeDirectory(path, insidePath)) {

			try {
				mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
			}
			catch (ModuleHandleException e) {
				errorMsg = e.what();
				return NULL;
			}
		}
		else {

			std::string extension;
			std::string basePath;

			if (Core::getInstance().pathIsInModuleDirectory(path, extension, basePath, insidePath)) {
				try {
					mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
				}
				catch (ModuleHandleException e) {
					errorMsg = e.what();
					return NULL;
				}

			}
			else {
				errorMsg = "can only load libraries when in a module or shipped with ucp: " + path;
				return NULL;
			}
		}

		if (mh == NULL) {
			errorMsg = "unexpected error";
			return NULL;
		}

		return mh;
	}

	//This function was taken from: https://stackoverflow.com/a/2072890
	inline bool ends_with(std::string const& value, std::string const& ending)
	{
		if (ending.size() > value.size()) return false;
		return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
	}

	const char* RAW_LIBRARY_ACCESS_MT_NAME = "UCP3.RawLibraryAccess";

	typedef struct RawLibraryAccess {
		ModuleHandle* mh;
		void* handle;
	} RawLibraryAccess;

	int luaGetProcAddress(lua_State* L) {
		if (lua_gettop(L) != 2) {
			return luaL_error(L, "expected two arguments: library handle and function name");
		}

		RawLibraryAccess* access = (RawLibraryAccess *) luaL_checkudata(L, 1, RAW_LIBRARY_ACCESS_MT_NAME);
		std::string funcName = lua_tostring(L, 2);

		FARPROC func = access->mh->loadFunctionFromLibrary(access->handle, funcName);

		if (func == NULL) {
			return luaL_error(L, ("could not get proc address: " + funcName).c_str());
		}

		lua_pushinteger(L, (lua_Integer)func);

		return 1;
	}

	int luaRequireLuaModule(lua_State* L) {
		if (lua_gettop(L) != 2) {
			return luaL_error(L, "expected two arguments: library handle and module name");
		}

		RawLibraryAccess* access = (RawLibraryAccess*)luaL_checkudata(L, 1, RAW_LIBRARY_ACCESS_MT_NAME);
		std::string modName = lua_tostring(L, 2);

		ModuleHandle* mh = access->mh;
		void* handle = access->handle;

		lua_CFunction func = (lua_CFunction)mh->loadFunctionFromLibrary(handle, "luaopen_" + modName);
		if (func == NULL) {
			return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
		}

		luaL_requiref(L, modName.c_str(), func, 0);

		return 1;
	}

	const struct luaL_Reg DLL_ACCESS_LIB[] = {
		{"getProcAddress", luaGetProcAddress},
		{"getFunction", luaGetProcAddress},
		{"require", luaRequireLuaModule},
		{NULL, NULL}
	};

	int luaLoadLibraryRaw(lua_State* L) {
		// stack: path

		//Read path from the stack (first argument)
		if (lua_gettop(L) != 1) {
			return luaL_error(L, "expected one argument");
		}
		std::string rawPath = lua_tostring(L, 1);

		std::string sanitizedPath;
		if (!sanitizeRelativePath(rawPath, sanitizedPath)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		if (!ends_with(sanitizedPath, ".dll")) {
			lua_pushnil(L);
			lua_pushstring(L, "path must end with '.dll'"); //error message
			return 2;
		}

		std::string insidePath;
		std::string errorMsg;

		ModuleHandle* mh = getModuleForLibraryPath(sanitizedPath, insidePath, errorMsg);
		if (mh == NULL) {
			return luaL_error(L, errorMsg.c_str());
		}

		void* handle = NULL;

		try {
			handle = mh->loadLibrary(insidePath);

			if (handle == NULL) {
				return luaL_error(L, ("Cannot load library: " + sanitizedPath).c_str());
			}

		}
		catch (ModuleHandleException e) {
			const DWORD err = GetLastError();

			return luaL_error(L, ("Error loading DLL (error: " + std::to_string(err) + ")" + ": " + sanitizedPath).c_str());
		}

		// stack: path
		RawLibraryAccess * access = (RawLibraryAccess *) lua_newuserdatauv(L, sizeof(RawLibraryAccess), 0);
		access->handle = handle;
		access->mh = mh;
		// stack: path, userdata

		// Check if table exists and in any case, push it to the stack
		if (luaL_newmetatable(L, RAW_LIBRARY_ACCESS_MT_NAME) != 0) {
			// meta table does not yet exist

			// stack: path, userdata, table
			luaL_setfuncs(L, DLL_ACCESS_LIB, 0);
			// stack: path, userdata, table
			lua_pushvalue(L, -1);
			// stack: path, userdata, table, table
			lua_setfield(L, -2, "__index");
			// stack: path, userdata, table
		}
		// stack: path, userdata, table
		lua_setmetatable(L, -2);

		// stack: path, userdata
		return 1;

	}
}