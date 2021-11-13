#pragma once

#ifdef UCPDLL_EXPORTS
#define UCP3_DLL    __declspec(dllexport)
#else
#define UCP3_DLL    __declspec(dllimport)
#endif

UCP3_DLL void initialize();
