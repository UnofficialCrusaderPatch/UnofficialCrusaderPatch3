
#ifndef LUA_LOG
#define LUA_LOG

// lua
#include "lua.hpp"

class LuaLog
{
public:

  // normal enum, to allow easier transform to int 
  enum LogLevel
  {
    LOG_NONE = 99, // for control stuff in the dll
    LOG_FATAL = -3,
    LOG_ERROR = -2,
    LOG_WARNING = -1,
    LOG_INFO = 0,
    LOG_DEBUG = 1,
  };

private:
  inline static lua_State* statePtr{};
  inline static int luaLogFuncIndex{};

public:

  static bool init(lua_State* L)
  {
    if (statePtr)
    {
      return true;  // already received, so hopefully this stays
    }

    lua_getglobal(L, "log");  // get log
    if (!lua_isfunction(L, -1))
    {
      lua_pop(L, 1);
      return false;
    }

    luaLogFuncIndex = luaL_ref(L, LUA_REGISTRYINDEX);
    statePtr = L;
    return true;
  }

  static void log(LogLevel level, const char* message)
  {
    if (statePtr)
    {
      lua_rawgeti(statePtr, LUA_REGISTRYINDEX, luaLogFuncIndex);
      lua_pushinteger(statePtr, level);
      lua_pushstring(statePtr, message);
      lua_call(statePtr, 2, 0);
    }
  }
};

#endif //LUA_LOG