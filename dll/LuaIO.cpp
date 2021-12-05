/*****************************************************************//**
 * \file   LuaIO.cpp
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 *********************************************************************/

#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include "Core.h"
#include "InternalData.h"
#include <regex>


//Required for the custom io_open function
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <cstdio>

namespace LuaIO {

	// When calling this in lua: the first argument should be a table with byte values in it (UTF16 characters, every two bytes being a single character)
	int luaWideCharToMultiByte(lua_State* L)
	{
		luaL_checktype(L, 1, LUA_TTABLE); // check if the first argument is a table
		int size = lua_rawlen(L, 1); // size of the table
		std::string buffer(size, 0);

		for (int i = 0; i < size; i++) {
			lua_rawgeti(L, -1, (i + 1)); // note: lua is 1-based. Pushes the value on the stack
			char value = (char)lua_tointeger(L, -1); // get the value into C++
			buffer[i] = value;
			lua_pop(L, 1); // pop the value from the stack, leaving the table on the stack for the next iteration.
		}

		int size_needed = WideCharToMultiByte(CP_UTF8, 0, (LPCWCH) &buffer[0], size/2, NULL, 0, NULL, NULL);
		std::string strTo(size_needed, 0);
		WideCharToMultiByte(CP_UTF8, 0, (LPCWCH) &buffer[0], size/2, &strTo[0], size_needed, NULL, NULL);

		lua_pushstring(L, strTo.c_str());
		return 1;
	}

	//This function was taken from: https://stackoverflow.com/a/2072890
	inline bool ends_with(std::string const& value, std::string const& ending)
	{
		if (ending.size() > value.size()) return false;
		return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
	}

	bool sanitizeRelativePath(const std::string &path, std::string &result) {
		std::string rawPath = path;

		//Assert non empty path
		if (rawPath.empty()) {
			result = "invalid path";
			return false;
		}



		std::filesystem::path sanitizedPath(rawPath);

		if (!std::filesystem::path(sanitizedPath).is_relative()) {
			result = "path has to be relative";
			return false;
		}

		if (std::filesystem::relative(std::filesystem::current_path() / sanitizedPath, std::filesystem::current_path()).string().find("..") == 0) {
			result = "path has remain in the game directory";
			return false;
		}
		
		result = sanitizedPath.string();
		return true;
	}


	// Only for filesystem files: unchecked path!
	int luaListFileSystemDirectories(lua_State* L) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		int count = 0;

		std::filesystem::path targetPath = rawPath;

		try {
			for (const auto& entry : std::filesystem::directory_iterator(targetPath)) {
				if (entry.is_directory()) {
					lua_pushstring(L, (entry.path().string() + "/").c_str());
					count += 1;
				}
			}
		}
		catch (std::filesystem::filesystem_error e) {
			return luaL_error(L, ("Cannot find the path: " + e.path1().string()).c_str());
		}

		return count;
	}

	// For internal files
	int luaInternalDirectoryIterator(lua_State* L) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		//Not sure sanitization is necessary, because zip files cannot really handle weird path names anyway...
		std::string sanitizedPath;
		if (!sanitizeRelativePath(rawPath, sanitizedPath)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		if (!initInternalData()) {
			return luaL_error(L, "could not initialize internal data");
		}

		int count = 0;

		std::filesystem::path haystack = std::filesystem::path(rawPath);

		int i, n = zip_entries_total(internalDataZip);
		for (i = 0; i < n; ++i) {
			zip_entry_openbyindex(internalDataZip, i);
			{
				const char* name = zip_entry_name(internalDataZip);
				int isdir = zip_entry_isdir(internalDataZip);
				// Only directories
				if (isdir) {
					// Only subdirectories of the directly requested path
					std::filesystem::path needle = std::filesystem::path(name);
					std::filesystem::path optionA = haystack.lexically_relative(needle);
					if (optionA.string() == "..") {
						lua_pushstring(L, name);
						count += 1;
					}
				}
				unsigned long long size = zip_entry_size(internalDataZip);
				unsigned int crc32 = zip_entry_crc32(internalDataZip);
			}
			zip_entry_close(internalDataZip);
		}

		return count;
	};


	int luaListDirectories(lua_State* L) {
		std::string rawPath = luaL_checkstring(L, 1);
		if (rawPath.empty()) return luaL_error(L, ("Invalid path: " + rawPath).c_str());

		std::string sanitizedPath;
		bool isInternal;
		if (!Core::getInstance().resolvePath(rawPath, sanitizedPath, isInternal)) {
			lua_pushnil(L);
			lua_pushstring(L, sanitizedPath.c_str()); //error message
			return 2;
		}

		if (isInternal) {
			return luaInternalDirectoryIterator(L);
		}
		else {
			lua_pushstring(L, sanitizedPath.c_str());
			lua_replace(L, 1); // Replace the path 
			return luaListFileSystemDirectories(L);
		}

		return luaListFileSystemDirectories(L);
	}

	FARPROC loadFunctionFromDLL(HMODULE handle, std::string name) {
		return GetProcAddress(handle, name.c_str());
	}

	HMODULE loadDLL(std::string path) {
		return LoadLibraryA(path.c_str());
	}

	int luaLoadLibrary(lua_State* L) {
		//Read path from the stack (first argument)
		if (lua_gettop(L) != 2) {
			return luaL_error(L, "expected two arguments");
		}
		std::string rawPath = lua_tostring(L, 1);
		std::string modName = lua_tostring(L, 2);

		if (!std::regex_match(modName, std::regex("[a-zA-Z0-9_]+"))) {
			return luaL_error(L, "invalid module name");
		}

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

#ifdef COMPILED_MODULES
		//if pointing to the ucp directory, use the UCP_DIR variable, "ucp/" is special
		if (sanitizedPath.rfind("ucp/", 0) == 0) {

			if ((sanitizedPath.rfind("ucp/plugins/", 0) == 0)) {
				// Allowed, move on
				return luaL_error(L, "plugins cannot contain dll files");
			}
			else {
				// Read from memory: do routine and RETURN!

				void* handle = (void*) loadInternalDLL(sanitizedPath);
				if (handle == NULL) {
					return luaL_error(L, ("Cannot load library: " + sanitizedPath).c_str());
				}

				lua_CFunction func = (lua_CFunction) loadFunctionFromInternalDLL(sanitizedPath, "luaopen_" + modName);
				if (func == NULL) {
					return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
				}

				luaL_requiref(L, modName.c_str(), func, 0);
			
				return 1;
			}

		}
		else {
			return luaL_error(L, "Only allowed to open DLLs inside the ucp directory");
		}
#else

		std::filesystem::path fullPath;
		if (sanitizedPath.rfind("ucp/", 0) == 0) {
			fullPath = Core::getInstance().UCP_DIR / sanitizedPath.substr(4);
		}
		else {
			fullPath = Core::getInstance().UCP_DIR / sanitizedPath;
		}
		if (!std::filesystem::exists(fullPath)) {
			lua_pushnil(L);
			lua_pushstring(L, "file does not exist"); //error message
			return 2;
		}

		std::filesystem::path stem = fullPath.stem();
		if (stem.string().rfind("-") != std::string::npos) {
			lua_pushnil(L);
			lua_pushstring(L, ("invalid dll file name: " + stem.string()).c_str());
			return 2;
		}

		HMODULE handle = loadDLL(fullPath.string());
		if (handle == NULL) {
			return luaL_error(L, ("Cannot load library: " + fullPath.string()).c_str());
		}

		lua_CFunction func = (lua_CFunction)loadFunctionFromDLL(handle, "luaopen_" + modName);
		if (func == NULL) {
			return luaL_error(L, ("Cannot find function: " + ("luaopen_" + modName)).c_str());
		}

		luaL_requiref(L, modName.c_str(), func, 0); // store in package.loaded
		
		// copy of module is left on the stack, return it
		return 1;
#endif // COMPILED_MODULES			

	}




	/**
	 * Only called by internal UCP3 lua code, not by modules or plugins.
	 *
	 * \param L
	 * \return
	 */
	int luaScopedRequire(lua_State* L) {
		//In COMPILED_MODULES mode
		//1. validate [a-zA-Z]+. format
		//1b. check cache existence
		//2. change . to /
		//3. prefix code/ to the path
		//4. look up in internal data
		//5. if does not exist, check with /init.lua appended
		//6. load the code
		//7. store in cache

		//Not in COMPILED_MODULES mode
		//1. validate [a-zA-Z]+. format
		//1b. check cache existence
		//2. change . to /
		//3. prefix code/ to the path
		//4. look up on the file system
		//5. load the code
		//6. store in cache

		if (lua_gettop(L) != 1) {
			return luaL_error(L, "'require' should be called with 1 argument");
		}

		std::string path = lua_tostring(L, 1);

		//First check is whether the path follows the "hello-world.how-are.you" paradigm
		std::cmatch res;
		std::regex re("^([a-zA-Z-]+)(?:\\.([a-zA-Z-]+))*$");
		if (!std::regex_match(path, re)) {
			return luaL_error(L, "invalid path");
		}

		//Check the cache if the file exists
		lua_getglobal(L, "package");
		lua_getfield(L, -1, "loaded");
		lua_getfield(L, -1, path.c_str());
		if (!lua_isnil(L, -1)) {
			lua_remove(L, -3); //Remove package
			lua_remove(L, -2); //Remove loaded
			return 1; //Return the cached file
		}
		lua_pop(L, 1); //remove the nil value
		lua_pop(L, 2); //pop package and loaded

		//Then convert all dots to path separators
		std::string slashPath = path;
		std::replace(slashPath.begin(), slashPath.end(), '.', '/');

		std::string codePath = "code/" + path;

#ifdef COMPILED_MODULES
		
		std::string code;
		std::string tryFile = readInternalFile("ucp/" + codePath + ".lua");
		if (tryFile.empty()) {
			std::string tryDirectory = readInternalFile("ucp/" + codePath + "/init.lua");
			if (tryDirectory.empty()) {
				return luaL_error(L, "file does not exist in internal data");
			}
			else {
				code = tryDirectory;
			}
		}
		else {
			code = tryFile;
		}

#else
		
		std::string resolvedPath;

		//Because all requires will be in the ucp/ subfolder, we add the slashPath to UCP_DIR.
		std::filesystem::path fullPath = Core::getInstance().UCP_DIR / codePath;

		//Test if it is a lua file
		std::filesystem::path filePath = fullPath.string() + ".lua";
		bool exists = std::filesystem::exists(filePath);
		if (!exists) {
			//Test if it is a directory. If it is, look for the init.lua file inside the directory.
			bool isDir = std::filesystem::is_directory(fullPath);

			if (isDir) {
				//Find the init.lua file in the folder
				std::filesystem::path dirPath = fullPath / "init.lua";
				if (!std::filesystem::exists(dirPath)) {
					return luaL_error(L, "init.lua file does not exist in folder");
				}

				resolvedPath = dirPath.string();
			}
			else {
				return luaL_error(L, "file does not exist");
			}
		}
		else {
			resolvedPath = filePath.string();
		}

		std::ifstream t(resolvedPath);
		std::stringstream buffer;
		buffer << t.rdbuf();

		std::string code = buffer.str();
#endif

		if (code.empty()) {
			return luaL_error(L, "no code to be executed");
		}
		
		if (luaL_loadbufferx(L, code.c_str(), code.size(), codePath.c_str(), "t") != LUA_OK) {
			std::string errorMsg = lua_tostring(L, -1);
			lua_pop(L, 1);
			return luaL_error(L, errorMsg.c_str());
		}

		// Only allow 1 return value
		if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
			std::string errorMsg = lua_tostring(L, -1);
			lua_pop(L, 1);
			return luaL_error(L, errorMsg.c_str());
		}

		// result is left on the stack
		// Now we store it in cache

		lua_getglobal(L, "package");
		lua_getfield(L, -1, "loaded");
		lua_pushvalue(L, -3); //Re add the result to the stack
		lua_setfield(L, -2, path.c_str());
		lua_pop(L, 2); //Pop loaded and package

		// result is left on the stack, so we return
		return 1;
	}


	/**
	 * The code below is taken from the lua source code for the 'io' module.
	 */

	/*
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


	FILE* setMemoryFileContents(MemoryStream m, std::string contents) {
		HANDLE write;
		CreatePipe(&m.read, &write, NULL, 10000000); //10 MB pipe

		DWORD written;
		WriteFile(write, contents.c_str(), contents.size(), &written, NULL);

		//We can close this already because this is the only time we write contents to it.
		CloseHandle(write);

		if (written != contents.size()) {
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

	int luaIOCustomOpen(lua_State* L) {
		const std::string filename = luaL_checkstring(L, 1);
		const std::string mode = luaL_optstring(L, 2, "r");

		std::string sanitizedPath;
		bool isInternal;

		if (!Core::getInstance().resolvePath(filename, sanitizedPath, isInternal)) {
			return luaL_error(L, ("Invalid path: " + sanitizedPath).c_str());
		}
		
		if (isInternal) {
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