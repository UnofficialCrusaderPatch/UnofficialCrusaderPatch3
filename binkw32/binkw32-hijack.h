/*******************************************************************
 * \file   binkw32-hijack.h
 * \brief  This code is for resolving the hijacked functions to the real dll.
 *
 * When the original game code calls any fake function from this file, it will load the original library and just call the real functions.
 * Note the exports.def for correctly naming the exported functions
 *
 * \author gynt
 *********************************************************************/

#pragma once

#include <iostream>


static void InitBinkw32Pointers(void);

struct binkw32_dll
{
	FARPROC BinkClose;
	FARPROC BinkCopyToBuffer;
	FARPROC BinkDDSurfaceType;
	FARPROC BinkDoFrame;
	FARPROC BinkNextFrame;
	FARPROC BinkOpen;
	FARPROC BinkOpenMiles;
	FARPROC BinkPause;
	FARPROC BinkSetSoundSystem;
	FARPROC BinkSetVolume;
	FARPROC BinkWait;

	void LoadOriginalLibrary()
	{
		HMODULE realLib = LoadLibrary(L"binkw32_real.dll");
		if (!realLib)
		{
			MessageBox(0, L"Can't load binkw32_real.dll\n", L"Error", MB_OK);
			std::cout << "Can't load binkw32_real.dll\n";
			std::cerr << "Can't load binkw32_real.dll\n";
			return;
		}

		BinkClose = GetProcAddress(realLib, "_BinkClose@4");

		BinkCopyToBuffer = GetProcAddress(realLib, "_BinkCopyToBuffer@28");

		BinkDDSurfaceType = GetProcAddress(realLib, "_BinkDDSurfaceType@4");

		BinkDoFrame = GetProcAddress(realLib, "_BinkDoFrame@4");

		BinkNextFrame = GetProcAddress(realLib, "_BinkNextFrame@4");

		BinkOpen = GetProcAddress(realLib, "_BinkOpen@8");

		BinkOpenMiles = GetProcAddress(realLib, "_BinkOpenMiles@4");

		BinkPause = GetProcAddress(realLib, "_BinkPause@8");

		BinkSetSoundSystem = GetProcAddress(realLib, "_BinkSetSoundSystem@8");

		BinkSetVolume = GetProcAddress(realLib, "_BinkSetVolume@12");

		BinkWait = GetProcAddress(realLib, "_BinkWait@4");

	}
} binkw32;

extern "C" __declspec(naked) void __stdcall _BinkClose(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkClose]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkCopyToBuffer(int, int, int, int, int, int, int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkCopyToBuffer]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkDDSurfaceType(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkDDSurfaceType]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkDoFrame(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkDoFrame]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkNextFrame(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkNextFrame]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkOpen(int, int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkOpen]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkOpenMiles(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkOpenMiles]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkPause(int, int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkPause]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkSetSoundSystem(int, int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkSetSoundSystem]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkSetVolume(int, int, int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkSetVolume]
	}
}
extern "C" __declspec(naked) void __stdcall _BinkWait(int)
{
	__asm
	{
		call InitBinkw32Pointers;
		jmp[binkw32.BinkWait]
	}
}
