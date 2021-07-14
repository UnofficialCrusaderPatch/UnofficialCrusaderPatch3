/*****************************************************************//**
 * \file   CompiledModules.h
 * \brief  This file contains the compiledModules declaration, which is a map of file paths and file content that is to be stored in DLL memory at compile time.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include <map>
#include <string>


namespace CompiledModules {
	extern const std::map<std::string, std::string> compiledModules;
}
