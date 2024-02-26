
#include "pch.h"

// lua
#include "lua.hpp"

#include "textResourceModifierHeader.h"
#include "aiSwapperHelperInternal.h"

// lua module load
extern "C" __declspec(dllexport) int __cdecl luaopen_aiSwapperHelper(lua_State *L)
{
  if (!TextResourceModifierHeader::initModuleFunctions())
  {
    luaL_error(L, "[aiSwapperHelper]: Failed to initialize text modifier API.");
  }

  lua_newtable(L); // push a new table on the stack

  // simple replace
  // get member func ptr, source: https://github.com/microsoft/Detours/blob/master/samples/member/member.cpp
  auto memberFuncPtr{&AiMessagePrepareFake::detouredSetMessageForAi};
  lua_pushinteger(L, *(DWORD *)&memberFuncPtr);
  lua_setfield(L, -2, "funcAddress_DetouredSetMessageForAi");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::prepareAiMsgFunc);
  lua_setfield(L, -2, "address_PrepareAiMsgFunc");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::aMessageFromArray);
  lua_setfield(L, -2, "address_AMessageFromArray");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::aiBinkArray);
  lua_setfield(L, -2, "address_AiBinkArray");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::aiSfxArray);
  lua_setfield(L, -2, "address_AiSfxArray");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::PlayMenuSelectSFX);
  lua_setfield(L, -2, "funcAddress_PlayMenuSelectSFX");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::playSFXFunc);
  lua_setfield(L, -2, "address_PlaySFXFunc");

  // address
  lua_pushinteger(L, (DWORD)&AiMessagePrepareFake::objPtrForPlaySFX);
  lua_setfield(L, -2, "address_ObjPtrForPlaySFX");

  // return lua funcs

  lua_pushcfunction(L, lua_SetMessageFrom);
  lua_setfield(L, -2, "lua_SetMessageFrom");
  lua_pushcfunction(L, lua_SetSfx);
  lua_setfield(L, -2, "lua_SetSfx");
  lua_pushcfunction(L, lua_SetBink);
  lua_setfield(L, -2, "lua_SetBink");

  return 1;
}
