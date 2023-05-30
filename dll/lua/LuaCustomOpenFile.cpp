
#include "LuaCustomOpenFile.h"
#include "io/modules/ModuleHandle.h"
#include "io/files.h"

namespace LuaIO {

	/**
	 * The code below is taken from the lua source code for the 'io' module.
	 * The code below is meant to open regular files living on the file system.
	 *
	 */

	 /*
	 ** (comment from original code)
	 **
	 ** When creating file handles, always creates a 'closed' file handle
	 ** before opening the actual file; so, if there is a memory error, the
	 ** handle is in a consistent state.
	 */
	static luaL_Stream* newprefile(lua_State* L) {
		luaL_Stream* p = (luaL_Stream*)lua_newuserdatauv(L, sizeof(luaL_Stream), 0);
		p->closef = NULL;  /* mark file handle as 'closed' */
		luaL_setmetatable(L, LUA_FILEHANDLE);
		return p;
	}

	/*
	** function to close regular files
	*/
	static int io_fclose(lua_State* L) {
		luaL_Stream* p = ((luaL_Stream*)luaL_checkudata(L, 1, LUA_FILEHANDLE));
		int res = fclose(p->f);
		return luaL_fileresult(L, (res == 0), NULL);
	}

	static luaL_Stream* newfile(lua_State* L) {
		luaL_Stream* p = newprefile(L);
		p->f = NULL;
		p->closef = &io_fclose;
		return p;
	}

	static int l_checkmode(const char* mode) {
		if (mode == 0) return 0;
		return (*mode != '\0' && strchr("rwa", *(mode++)) != NULL &&
			(*mode != '+' || ((void)(++mode), 1)) &&  /* skip if char is '+' */
			(strspn(mode, "b") == strlen(mode)));  /* check extensions */
	}

	/**
	 * End of copied code.
	 */



	 /**
	  * The code below is for the custom io_open function to read from memory as if it was a file.
	  *
	  *
	  */


	int luaIOCustomOpenFilePointer(lua_State* L) {
		const std::string filename = luaL_checkstring(L, 1);
		const std::string mode = luaL_optstring(L, 2, "r");

		std::string errorMsg;
		FILE* result = getFilePointer(filename, mode, errorMsg);

		if (result != NULL) {
			lua_pushinteger(L, (DWORD) result);
			return 1;
		}

		return luaL_error(L, "Could not get file pointer to path '%s'. Error message: '%s'", filename.c_str(), errorMsg.c_str());
	}

	int luaIOCustomOpenFileDescriptor(lua_State* L) {
		const std::string filename = luaL_checkstring(L, 1);
		const int mode = luaL_checkinteger(L, 2);

		std::string errorMsg;
		int result = getFileDescriptor(filename, mode, errorMsg);

		if (result != -1) {
			lua_pushinteger(L, (DWORD)result);
			return 1;
		}

		return luaL_error(L, "Could not get file descriptor to path '%s'. Error message: '%s'", filename.c_str(), errorMsg.c_str());
	}

	int luaIOCustomOpen(lua_State* L) {
		const std::string filename = luaL_checkstring(L, 1);
		const std::string mode = luaL_optstring(L, 2, "r");

		std::string sanitizedPath;

		if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
			return luaL_error(L, ("Invalid path: " + filename + "\n reason: " + sanitizedPath).c_str());
		}

		std::string insidePath;
		ExtensionHandle* mh;
		if (Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, insidePath)) {

			try {
				mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
			}
			catch (ModuleHandleException e) {
				return luaL_error(L, e.what());
			}
		}
		else {

			std::string basePath;
			std::string extension;
			std::string insideExtensionPath;

			if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, insidePath)) {
				try {
					mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
				}
				catch (ModuleHandleException e) {
					return luaL_error(L, e.what());
				}
				
			}
			else {
				if (Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, insidePath)) {
					try {
						mh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
					}
					catch (ModuleHandleException e) {
						return luaL_error(L, e.what());
					}

				}
				else {
				

					// A regular file outside of the code module or modules directory

					luaL_Stream* p = newfile(L);
					const char* md = mode.c_str();  /* to traverse/check mode */
					luaL_argcheck(L, l_checkmode(md), 2, "invalid mode");

					p->f = fopen(sanitizedPath.c_str(), mode.c_str());
					return (p->f == NULL) ? luaL_fileresult(L, 0, sanitizedPath.c_str()) : 1;
				}

			}
		}

		// A file inside the code module or the modules directory

		if (mode != "r" && mode != "rb") {
			lua_pushnil(L);
			lua_pushstring(L, ("it is illegal to write to a module: " + sanitizedPath).c_str());
			return 2;
		}

		try {
			std::string errorMsg;
			FILE* f = mh->openFilePointer(insidePath, errorMsg);
			if (f == NULL) {
				lua_pushnil(L);
				lua_pushstring(L, errorMsg.c_str());
				return 2;
				// return luaL_error(L, errorMsg.c_str());
			}

			luaL_Stream* s = newfile(L);
			s->f = f;

			return (s->f == NULL) ? luaL_fileresult(L, 0, sanitizedPath.c_str()) : 1;
		}
		catch (ModuleHandleException e) {
			return luaL_error(L, e.what());
		}
		


	}
}
