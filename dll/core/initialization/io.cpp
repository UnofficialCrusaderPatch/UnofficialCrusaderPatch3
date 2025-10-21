#include <core/initialization/io.h>

#include "lua/LuaPathExists.h"
#include "lua/LuaCustomOpenFile.h"
#include "lua/LuaLoadLibrary.h"
#include "lua/yaml/LuaYamlParser.h"
#include "lua/yaml/LuaYamlDumper.h"
#include "lua/Preload.h"
#include "lua/LuaTempFile.h"

void addIOFunctions(lua_State* L) {
	lua_pushglobaltable(L);

	lua_pushcfunction(L, LuaIO::luaLoadLibrary);
	lua_setfield(L, -2, "loadLibrary");


	lua_getfield(L, -1, "io");

	lua_pushcfunction(L, LuaIO::luaIOCustomOpen);
	lua_setfield(L, -2, "open");

	lua_pushcfunction(L, LuaIO::luaIOCustomOpenFilePointer);
	lua_setfield(L, -2, "openFilePointer");

	lua_pushcfunction(L, LuaIO::luaIOCustomOpenFileDescriptor);
	lua_setfield(L, -2, "openFileDescriptor");

	lua_pushcfunction(L, LuaIO::luaPathExists);
	lua_setfield(L, -2, "exists");

	lua_pushcfunction(L, LuaIO::luaCreateWriteProtectedTempFile);
	lua_setfield(L, -2, "createWriteProtectedTempFile");

	lua_pushcfunction(L, LuaIO::luaIOCustomWriteProtectedTempFileOpen);
	lua_setfield(L, -2, "openWriteProtectedTempFile");

	// Create ucrt subtable
	lua_newtable(L);

	lua_pushinteger(L, (DWORD)&_read); lua_setfield(L, -2, "_read"); //
	lua_pushinteger(L, (DWORD)&_close); lua_setfield(L, -2, "_close"); //
	lua_pushinteger(L, (DWORD)&_open); lua_setfield(L, -2, "_open"); //
	lua_pushinteger(L, (DWORD)&_write); lua_setfield(L, -2, "_write"); //
	lua_pushinteger(L, (DWORD)&_flushall); lua_setfield(L, -2, "_flushall"); //
	lua_pushinteger(L, (DWORD)&_lseek); lua_setfield(L, -2, "_lseek"); //
	lua_pushinteger(L, (DWORD)&_tell); lua_setfield(L, -2, "_tell"); //
	lua_pushinteger(L, (DWORD)&_fileno); lua_setfield(L, -2, "_fileno"); //
	lua_pushinteger(L, (DWORD)&_fsopen); lua_setfield(L, -2, "_fsopen"); //

	lua_pushinteger(L, (DWORD)&fopen); lua_setfield(L, -2, "fopen"); //
	lua_pushinteger(L, (DWORD)&fclose); lua_setfield(L, -2, "fclose"); //
	lua_pushinteger(L, (DWORD)&fread); lua_setfield(L, -2, "fread"); //
	lua_pushinteger(L, (DWORD)&fread_s); lua_setfield(L, -2, "fread_s"); //
	lua_pushinteger(L, (DWORD)&fwrite); lua_setfield(L, -2, "fwrite");
	lua_pushinteger(L, (DWORD)&fseek); lua_setfield(L, -2, "fseek"); //
	lua_pushinteger(L, (DWORD)&ftell); lua_setfield(L, -2, "ftell"); //
	lua_pushinteger(L, (DWORD)&fflush); lua_setfield(L, -2, "fflush"); //
	lua_pushinteger(L, (DWORD)&fgetpos); lua_setfield(L, -2, "fgetpos"); //
	lua_pushinteger(L, (DWORD)&fsetpos); lua_setfield(L, -2, "fsetpos"); //
	lua_pushinteger(L, (DWORD)&getwc); lua_setfield(L, -2, "getwc"); //

	// Set the table
	lua_setfield(L, -2, "ucrt");


	lua_pop(L, 1); // Pop the io table


	// Create Yaml table
	lua_createtable(L, 0, 2);

	lua_pushcfunction(L, LuaYamlParser::luaParseYamlContent);
	lua_setfield(L, -2, "parse");
	lua_pushcfunction(L, LuaYamlParser::luaParseYamlContent);
	lua_setfield(L, -2, "eval"); // FOr backwards compatilibity

	lua_pushcfunction(L, LuaYamlDumper::luaDumpLuaTable);
	lua_setfield(L, -2, "dump");

	// store table as a global yaml table
	lua_setglobal(L, "yaml");
	//lua_pop(L, 1);

	/**
	 * The code below is also possible.
	lua_pushcfunction(L, LuaIO::luaScopedRequire);
	lua_setfield(L, -2, "require"); //Overriding the global require

	* But we can also do this: */
	if (luaL_loadbufferx(L, ucp_code_pre.c_str(), ucp_code_pre.size(), "@ucp/code/pre.lua", "t") != LUA_OK) {
		std::cout << "ERROR in loading pre.lua" << lua_tostring(L, -1) << std::endl;
		lua_pop(L, 1);
	}
	else {
		if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
			std::cout << "ERROR in executing pre.lua: " << lua_tostring(L, -1) << std::endl;
			lua_pop(L, 1);
		};
	}

	lua_pop(L, 1); //Pop the global table
}