/*****************************************************************//**
 * \file   LuaIO.h
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 *********************************************************************/
#pragma once

#include <string>
#include "lua.hpp"
#include "InternalData.h"

namespace LuaIO {
	int luaLoadLibrary(lua_State* L);
	int luaIOCustomOpen(lua_State* L);
	int luaListDirectories(lua_State* L);
	int luaWideCharToMultiByte(lua_State* L);
}
