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

	HMEMORYMODULE loadDLLFromZip(std::string path, zip_t* z);
	HMEMORYMODULE loadInternalDLL(std::string path);
	FARPROC loadFunctionFromMemoryDLL(HMEMORYMODULE handle, std::string functionName);
	FARPROC loadFunctionFromInternalDLL(std::string dllPath, std::string functionName);
}
