/*****************************************************************//**
 * \file   CompiledLua.h
 * \brief  This file allows compiled lua code to be stored in DLL memory at compile time, improving safety of the system.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include "CompiledModules.h"

namespace CompiledModules {
	
	void registerProxyFunctions();
	void runCompiledModule(std::string name);
}

