#include "debugging/DebugExecutionLogger.h"
#include "core/Core.h"
#include <sstream>

#include "debugging/DebugSettings.h"

namespace debugging {
	void logExecution(lua_State* L, lua_Debug* ar) {
		lua_getinfo(L, "S", ar);
		std::stringstream luadebug;
		luadebug << "debug: what: " << ar->what << " line: " << ar->currentline << " short source: " << ar->short_src;
		Core::getInstance().log(3, luadebug.str());

		if (DebugSettings::getInstance().aggressiveGC) {
			std::stringstream luadebug2;
			luadebug2 << "debug: collecting garbage";
			lua_gc(L, LUA_GCCOLLECT);
			Core::getInstance().log(3, luadebug2.str());
		}
	}

}
