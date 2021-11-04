/*****************************************************************//**
 * \file   InternalData.h
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 *********************************************************************/
#pragma once

#include <map>
#include <string>
#include "zip.h"
#include "MemoryModule.h"

namespace LuaIO {
	extern zip_t* internalDataZip;
	std::string readInternalFile(std::string path);
	bool initInternalData();

	HMEMORYMODULE loadInternalDLL(std::string path);
	FARPROC loadFunctionFromInternalDLL(std::string dllPath, std::string functionName);
}
