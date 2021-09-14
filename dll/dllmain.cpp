#include "dllmain.h"
#include "Core.h"

DWORD entryFunction = 0x00591049;

void initialize() {
	Core::getInstance().initialize();
}

/**
 * This function contains assembly code and is called instead of the game entry point.
 * 
 */
__declspec(naked) void entryPointDetour() {
	__asm {
		call initialize;

		// jmp to the original entryPointFunction
		mov eax, entryFunction;
		jmp eax;
	}
}

HMODULE hModule = 0;

BOOL APIENTRY DllMain(HMODULE hMod, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	{

		hModule = hMod;

#ifdef WAIT_BEFORE_HOOK
		MessageBoxA(0, "ready?", "ready?", MB_OK);
#endif

		// Currently, we detour the entry point of the program to our code `_entryPointDetour()` right when this dll is loaded.
		// To do that, we need to figure out the address of the entry point.

		// We need to figure out where the entry function is.
		// This is a step by step process, first getting IMAGE_DOS_HEADER.e_lfanew, in PE executables, it is located at +0x3C
		int e_lfanew = *((int*)(0x00400000 + 0x3C));

		// Then we can compute where the AddressOfEntryPoint is:
		int* entryPointAddress = (int*)(0x00400000 + e_lfanew + 0x28);

		DWORD entryPoint = *entryPointAddress + 0x00400000; //0x00584026;

		// The entry point is calling another function. We need to know which function that is.

		// gynt: I checked for v1.41, and v1.3 and extreme, and this will work there. However it will not work in v1.1, because there is no call here. We need a normal hook.
		//if (*((BYTE*)(entryPoint)) != 0xE8) {
		//	MessageBoxA(0, "the format of this executable is unknown.", "UCP failed to load", MB_OK);
		//	//return TRUE;
		//}

		// We store the original function that would have been called.
		entryFunction = (*((int*)(entryPoint + 1)) + entryPoint) + 5; //0x00591049
		
		// The `CALL` instruction we modify is relative, so to jump to our function, a relative distance is computed.
		int distance = (int) (((DWORD)&entryPointDetour) - entryPoint) - 5; 

		// 0xE8 is a `CALL` assembly instruction. I am only setting the address that is in the call to not confuse CheatEngine.
		char bytes[4] = {0x90, 0x90, 0x90, 0x90 }; 
		memcpy(&bytes[0], &distance, 4);

		// The memory we want to modify is in a write-protected region, so we remove the protection.
		DWORD oldProtect;
		VirtualProtect((LPVOID)entryPoint, 5, PAGE_EXECUTE_READWRITE, &oldProtect);

		// Write the data.
		memcpy((void*)(entryPoint+1), &bytes[0], 4);

		// And reapply the protection.
		VirtualProtect((LPVOID)entryPoint, 5, oldProtect, &oldProtect);


	}
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}