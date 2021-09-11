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

namespace LuaIO {
	int luaLoadLibrary(lua_State* L);
	int luaScopedRequire(lua_State* L);
	int luaIOCustomOpen(lua_State* L);
	std::string fetchInternalData(std::string path);

}
