
#include "debugging/DebugMemoryAllocation.h"

#include <iostream>   
#include <sstream> 

namespace debugging {

	lua_Alloc original;

	void* debuggingRealloc(void* ud, void* ptr, size_t osize, size_t nsize) {
		std::stringstream before;
		before << "realloc(" << std::hex << ptr << ", " << std::hex << osize << ", " << std::hex << nsize << ")";
		Core::getInstance().log(3, before.str());

		void* result = original(ud, ptr, osize, nsize);

		std::stringstream after;
		after << "realloc(" << std::hex << ptr << ", " << std::hex << osize << ", " << std::hex << nsize << ") => " << std::hex << result;
		Core::getInstance().log(3, after.str());

		return result;
	}

	lua_Alloc debug = debuggingRealloc;

	void registerDebuggingMemoryAllocator(lua_State* L) {
		lua_Alloc current = lua_getallocf(L, NULL);
		if (current == debug) {
			Core::getInstance().log(-3, "debug memory allocator already registered");
			return;
		}
		original = current;
		Core::getInstance().log(-1, "debugging memory allocator set!");
		lua_setallocf(L, debug, NULL);
	}
}