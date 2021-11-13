/*******************************************************************
 * \file   binkw32-hijack.cpp
 * \brief  This code is for resolving the hijacked functions to the real dll. 
 * 
 * When the original game code calls any fake function from this file, it will load the original library and just call the real functions.
 * Note the exports.def for correctly naming the exported functions
 * 
 * \author gynt
 *********************************************************************/

#include "framework.h"

#include <mutex>

#include "binkw32-hijack.h"

static std::once_flag inited;

static void Binkw32HijackFirstCall()
{

	binkw32.LoadOriginalLibrary();
}

static void InitBinkw32Pointers()
{
	std::call_once(inited, []() { Binkw32HijackFirstCall(); });
}