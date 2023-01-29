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
#include "security/InternalData.h"

namespace LuaIO {
	int luaLoadLibrary(lua_State* L);
	int luaWideCharToMultiByte(lua_State* L);
}
