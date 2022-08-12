
#include "pch.h"

#include "textResourceModifierHeader.h"
#include "aiSwapperHelperInternal.h"


static void placeInMapHelper(std::unordered_map<int, std::string>& map, int key, const char* string)
{
  auto iter{ map.find(key) };
  if (iter != map.end())
  {
    if (string)
    {
      iter->second = string;
    }
    else
    {
      map.erase(iter);
    }
  }
  else
  {
    map.try_emplace(key, string);
  }
}

bool AiMessagePrepareFake::isValidAiType(AiType aiType)
{
  return !(aiType < 1 || aiType > 16);
}

bool AiMessagePrepareFake::isValidMessageType(MessageType messageType)
{
  return !(messageType < 1 || messageType > 34);
}

bool AiMessagePrepareFake::fitsInPreparedText(const char* filename)
{
  return std::strlen(filename) < 25;  // max length of bink or sound filename length
}

const char* AiMessagePrepareFake::getMessageFrom(AiType aiType)
{
  auto iter{ messageFromReplaced.find(aiType) };
  return iter != messageFromReplaced.end() ? iter->second.c_str() : aMessageFromArray[aiType + 1];
}

const char* AiMessagePrepareFake::getBink(int index)
{
  auto iter{ binkReplaced.find(index) };
  return iter != binkReplaced.end() ? iter->second.c_str() : aiBinkArray[index];
}

const char* AiMessagePrepareFake::getSfx(int index)
{
  auto iter{ sfxReplaced.find(index) };
  return iter != sfxReplaced.end() ? iter->second.c_str() : aiSfxArray[index];
}

int AiMessagePrepareFake::getSfxAndBinkIndex(AiType aiType, MessageType messageType)
{
  return (messageType - 1) * 0x11 + aiType;
}

void __thiscall AiMessagePrepareFake::detouredSetMessageForAi(int playerIndex, AiType aiType, MessageType messageType)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType))
  {
    return;
  }

  (this->*prepareAiMsgFunc)("", "", getMessageFrom(aiType), playerIndex);

  std::string text{ TextResourceModifierHeader::GetText(AI_MESSAGE_TEXT_INDEX, messageType - 34 + aiType * 34) };
  const char* textPtr{ nullptr };
  if (*((int*)this) == 0)   // in this case, the thing is played directly
  {
    preparedMessages[10].swap(text);
    textPtr = preparedMessages[10].c_str();
  }
  else
  {
    int preparedNum{ *((int*)this + 585) };
    if (preparedNum != 10)
    {
      preparedMessages[preparedNum].swap(text);
      textPtr = preparedMessages[preparedNum].c_str();
    }
    else
    {
      textPtr = "";
    }
  }

  int sfxAndBinkIndex{ getSfxAndBinkIndex(aiType, messageType) };
  (this->*prepareAiMsgFunc)(textPtr, getBink(sfxAndBinkIndex), getSfx(sfxAndBinkIndex), playerIndex);
}


bool AiMessagePrepareFake::SetMessageFrom(AiType aiType, const char* filename)
{
  if (!isValidAiType(aiType) || !fitsInPreparedText(filename))
  {
    return false;
  }

  placeInMapHelper(messageFromReplaced, aiType, filename);
  return true;
}

bool AiMessagePrepareFake::SetBink(AiType aiType, MessageType messageType, const char* filename)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType) || !fitsInPreparedText(filename))
  {
    return false;
  }

  int index{ getSfxAndBinkIndex(aiType, messageType) };
  placeInMapHelper(binkReplaced, index, filename);
  return true;
}

bool AiMessagePrepareFake::SetSfx(AiType aiType, MessageType messageType, const char* filename)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType) || !fitsInPreparedText(filename))
  {
    return false;
  }

  int index{ getSfxAndBinkIndex(aiType, messageType) };
  placeInMapHelper(sfxReplaced, index, filename);
  return true;
}

/* export LUA */

extern "C" __declspec(dllexport) int __cdecl lua_SetMessageFrom(lua_State * L)
{
  int n{ lua_gettop(L) };    /* number of arguments */
  if (n != 2)
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetMessageFrom: Invalid number of args.");
  }

  if (!lua_isinteger(L, 1) || !lua_isstring(L, 2))
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetMessageFrom: Wrong input fields.");
  }

  bool res{ AiMessagePrepareFake::SetMessageFrom(static_cast<AiType>(lua_tointeger(L, 1)), lua_tostring(L, 2)) };
  lua_pushboolean(L, res);
  return 1;
}

extern "C" __declspec(dllexport) int __cdecl lua_SetBink(lua_State * L)
{
  int n{ lua_gettop(L) };    /* number of arguments */
  if (n != 3)
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetBink: Invalid number of args.");
  }

  if (!(lua_isinteger(L, 1) && lua_isinteger(L, 2) && lua_isstring(L, 3)))
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetBink: Wrong input fields.");
  }

  bool res{ AiMessagePrepareFake::SetBink(static_cast<AiType>(lua_tointeger(L, 1)), static_cast<MessageType>(lua_tointeger(L, 2)), lua_tostring(L, 3)) };
  lua_pushboolean(L, res);
  return 1;
}

extern "C" __declspec(dllexport) int __cdecl lua_SetSfx(lua_State * L)
{
  int n{ lua_gettop(L) };    /* number of arguments */
  if (n != 3)
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetSfx: Invalid number of args.");
  }

  if (!(lua_isinteger(L, 1) && lua_isinteger(L, 2) && lua_isstring(L, 3)))
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetSfx: Wrong input fields.");
  }

  bool res{ AiMessagePrepareFake::SetSfx(static_cast<AiType>(lua_tointeger(L, 1)), static_cast<MessageType>(lua_tointeger(L, 2)), lua_tostring(L, 3)) };
  lua_pushboolean(L, res);
  return 1;
}