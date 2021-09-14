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
namespace LuaIO {
	extern zip_t* internalDataZip;
	std::string readInternalFile(std::string path);
	bool initInternalData();
}
