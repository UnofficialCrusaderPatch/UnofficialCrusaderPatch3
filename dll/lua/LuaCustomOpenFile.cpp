
#include "LuaCustomOpenFile.h"


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

	struct MemoryStream : public luaL_Stream {
		HANDLE read;
	};


	static int MemoryStream_fclose(lua_State* L) {
		MemoryStream* p = ((MemoryStream*)luaL_checkudata(L, 1, LUA_FILEHANDLE));
		int res = fclose(p->f);
		if (p->read != INVALID_HANDLE_VALUE) {
			CloseHandle(p->read);
		}
		return luaL_fileresult(L, (res == 0), NULL);
	}


	static MemoryStream* newMemoryFile(lua_State* L) {
		MemoryStream* p = (MemoryStream*)lua_newuserdatauv(L, sizeof(MemoryStream), 0);
		p->closef = NULL;  /* mark file handle as 'closed' */
		luaL_setmetatable(L, LUA_FILEHANDLE);

		p->read = INVALID_HANDLE_VALUE;
		p->f = NULL;
		p->closef = &MemoryStream_fclose;

		return p;
	}

	/**
	char buff[] = "hello world!";

	//One option
	void createMemoryFile() {
		HANDLE h = CreateFileMapping(INVALID_HANDLE_VALUE,
			NULL,
			PAGE_READWRITE,
			0,
			10000000,
			NULL);

		DWORD written;
		WriteFile(h, buff, strlen(buff), &written, NULL);

		int fd = _open_osfhandle((intptr_t) h, _O_RDONLY);
		FILE* f = _fdopen(fd, "r");

		fclose(f);

		// To clean up the file:
		CloseHandle(h);
	}
	 */



	FILE* setBinaryMemoryFileContents(MemoryStream m, const char* contents, size_t length) {
		HANDLE write;
		CreatePipe(&m.read, &write, NULL, 10000000); //10 MB pipe

		DWORD written;
		WriteFile(write, contents, length, &written, NULL);

		//We can close this already because this is the only time we write contents to it.
		CloseHandle(write);

		if (written != length) {
			throw "";
		}

		int fd = _open_osfhandle((intptr_t)m.read, _O_RDONLY);
		if (fd == -1) {
			throw "";
		}

		FILE* f = _fdopen(fd, "r");
		if (f == 0) {
			throw "";
		}

		return f;
	}

	FILE* setMemoryFileContents(MemoryStream m, std::string contents) {
		return setBinaryMemoryFileContents(m, contents.c_str(), contents.size());
	}


	int luaIOCustomOpen(lua_State* L) {
		const std::string filename = luaL_checkstring(L, 1);
		const std::string mode = luaL_optstring(L, 2, "r");

		std::string sanitizedPath;

		if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
			return luaL_error(L, ("Invalid path: " + filename).c_str());
		}

		bool isInternal;

		std::string extension;
		std::string insideExtensionPath;

		if (Core::getInstance().pathIsInModule(sanitizedPath, extension, insideExtensionPath)) {

			if (Core::getInstance().modulesZipMap.count(extension) == 1) {

				if (mode != "r" && mode != "rb") {
					lua_pushnil(L);
					lua_pushstring(L, ("tried to write to a zipped file: " + sanitizedPath).c_str());
					return 2;
				}


				zip_t* z = Core::getInstance().modulesZipMap.at(extension);

				char* buf = NULL;
				size_t bufsize = 0;

				if (zip_entry_open(z, insideExtensionPath.c_str()) != 0) {
					lua_pushnil(L);
					lua_pushstring(L, ("file does not exist in extension zip: " + sanitizedPath).c_str());
					return 2;
				}

				zip_entry_read(z, (void**)&buf, &bufsize);
				zip_entry_close(z);


				MemoryStream* p = newMemoryFile(L);
				p->f = setBinaryMemoryFileContents(*p, buf, bufsize);

				free(buf);


				return (p->f == NULL) ? luaL_fileresult(L, 0, sanitizedPath.c_str()) : 1;
			}
			else if (Core::getInstance().modulesDirMap.count(extension) == 1) {
				if (!Core::getInstance().modulesDirMap.at(extension)) {
					return luaL_error(L, ("Unexpected error when reading: " + sanitizedPath).c_str());
				}

				// Pass through!

			}
			else {
				lua_pushnil(L);
				lua_pushstring(L, ("file does not exist because extension does not exist: " + sanitizedPath).c_str());
				return 2;
			}


		}

		if (!Core::getInstance().resolvePath(filename, sanitizedPath, isInternal)) {
			return luaL_error(L, ("Invalid path: " + sanitizedPath).c_str());
		}

		if (isInternal) {

			if (mode != "r" && mode != "rb") {
				lua_pushnil(L);
				lua_pushstring(L, ("tried to write a zipped file: " + sanitizedPath).c_str());
				return 2;
			}

			std::string contents = readInternalFile(sanitizedPath);

			if (contents.empty()) {
				lua_pushnil(L);
				lua_pushstring(L, ("file does not exist internally: " + sanitizedPath).c_str());
				return 2;
			}

			MemoryStream* p = newMemoryFile(L);
			p->f = setMemoryFileContents(*p, contents);

			return (p->f == NULL) ? luaL_fileresult(L, 0, sanitizedPath.c_str()) : 1;
		}

		luaL_Stream* p = newfile(L);
		const char* md = mode.c_str();  /* to traverse/check mode */
		luaL_argcheck(L, l_checkmode(md), 2, "invalid mode");

		p->f = fopen(sanitizedPath.c_str(), mode.c_str());
		return (p->f == NULL) ? luaL_fileresult(L, 0, sanitizedPath.c_str()) : 1;

	}
}
