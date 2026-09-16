
#include "debugging/DebugMemoryAllocation.h"

#include <iostream>   
#include <sstream> 

namespace debugging {

	lua_State* LS;

	lua_Alloc original;

	void* debuggingRealloc(void* ud, void* ptr, size_t osize, size_t nsize) {
		std::stringstream before;
		before << "realloc(" << std::hex << ptr << ", " << std::hex << osize << ", " << std::hex << nsize << ")";
		Core::getInstance().log(3, before.str());

		//lua_Debug lb;
		//if (lua_getstack(LS, 0, &lb) == 1) {
		//	int dr = lua_getinfo(LS, "S", &lb);
		//	if (dr != 0) {
		//		std::stringstream luadebug;
		//		luadebug << "debug: what: " << lb.what << " linedefined: " << lb.linedefined << " source: " << lb.source << " short source: " << lb.short_src;
		//		Core::getInstance().log(3, luadebug.str());
		//	}
		//	else {
		//		std::stringstream luadebug;
		//		luadebug << "debug: failed: " << dr;
		//		Core::getInstance().log(3, luadebug.str());
		//	}
		//}

		void* result = original(ud, ptr, osize, nsize);

		std::stringstream after;
		after << "realloc(" << std::hex << ptr << ", " << std::hex << osize << ", " << std::hex << nsize << ") => " << std::hex << result;
		Core::getInstance().log(3, after.str());

		return result;
	}

	lua_Alloc debug = debuggingRealloc;

	void registerDebuggingMemoryAllocator(lua_State* L) {
		LS = L;

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