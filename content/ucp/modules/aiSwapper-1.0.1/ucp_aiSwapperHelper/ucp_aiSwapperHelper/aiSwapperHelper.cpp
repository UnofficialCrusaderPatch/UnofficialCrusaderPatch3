
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
    if (string)
    {
      map.try_emplace(key, string);
    }
  }
}

static void fillInFittingPathPair(std::unordered_map<int, std::string>& mapToSearchIn, const char** vanillaArray, int index, std::pair<const char*, bool>& pairToFill)
{
  auto iter{ mapToSearchIn.find(index) };
  pairToFill.second = iter != mapToSearchIn.end();
  if (pairToFill.second)
  {
    pairToFill.first = iter->second.c_str();
  }
  else
  {
    pairToFill.first = vanillaArray[index];
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

void AiMessagePrepareFake::getMessageFrom(AiType aiType, std::pair<const char*, bool>& pairToFill)
{
  fillInFittingPathPair(messageFromReplaced, aMessageFromArray, aiType, pairToFill);
}

void AiMessagePrepareFake::getBink(int index, std::pair<const char*, bool>& pairToFill)
{
  fillInFittingPathPair(binkReplaced, aiBinkArray, index, pairToFill);
}

void AiMessagePrepareFake::getSfx(int index, std::pair<const char*, bool>& pairToFill)
{
  fillInFittingPathPair(sfxReplaced, aiSfxArray, index, pairToFill);
}

int AiMessagePrepareFake::getSfxAndBinkIndex(AiType aiType, MessageType messageType)
{
  return (messageType - 1) * 0x11 + aiType;
}

void AiMessagePrepareFake::prepareMessage(AiMessagePrepareFake* that, const char* text, const std::pair<const char*, bool>& binkPair,
  const std::pair<const char*, bool>& sfxPair, int someIndex)
{
  PreparedMessage* current{ nullptr };

  if (*((int*)that) == 0)   // in this case, the thing is played directly
  {
    activeMessage.text = text;
    activeMessage.bink = binkPair.first;
    activeMessage.sound = sfxPair.first;
    current = &activeMessage;


    // empty queue here, since it is guarded as long as messages are present
    while (!preparedMessages.empty())
    {
      preparedMessages.pop();
    }
  }
  else
  {
    int preparedNum{ *((int*)that + 585) };
    if (preparedNum != 10)
    {
      PreparedMessage newMsg{ text, binkPair.first, sfxPair.first };
      preparedMessages.push(std::move(newMsg));
      current = &preparedMessages.back();
    }
    else
    {
      return; // no need to call it in this case
    }
  }

  // give the address as string, and transform it later in lua
  (that->*prepareAiMsgFunc)(current->text.c_str(),
    binkPair.second ? std::to_string((int)current->bink.c_str()).c_str() : current->bink.c_str(),
    sfxPair.second ? std::to_string((int)current->sound.c_str()).c_str() : current->sound.c_str(),
    someIndex);
}


void __thiscall AiMessagePrepareFake::detouredSetMessageForAi(int playerIndex, AiType aiType, MessageType messageType)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType))
  {
    return;
  }

  std::pair<const char*, bool> binkPair{"", false};
  std::pair<const char*, bool> sfxPair{"", false};
  getMessageFrom(aiType, sfxPair);

  prepareMessage(this, "", binkPair, sfxPair, playerIndex);

  int sfxAndBinkIndex{ getSfxAndBinkIndex(aiType, messageType) };

  getBink(sfxAndBinkIndex, binkPair);
  getSfx(sfxAndBinkIndex, sfxPair);

  prepareMessage(this,
    TextResourceModifierHeader::GetText(AI_MESSAGE_TEXT_INDEX, messageType - 34 + aiType * 34),
    binkPair, sfxPair, -playerIndex);
}

void __cdecl AiMessagePrepareFake::PlayMenuSelectSFX(AiType aiType, MessageType messageType)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType))
  {
    return;
  }

  // still needs transform to string ptr procedure
  std::pair<const char*, bool> sfxPair{ "", false };
  getSfx(getSfxAndBinkIndex(aiType, messageType), sfxPair);
  (objPtrForPlaySFX->*playSFXFunc)(sfxPair.second ? std::to_string((int)sfxPair.first).c_str() : sfxPair.first);
}




bool AiMessagePrepareFake::SetMessageFrom(AiType aiType, const char* filename)
{
  if (!isValidAiType(aiType))
  {
    return false;
  }

  placeInMapHelper(messageFromReplaced, aiType, filename);
  return true;
}

bool AiMessagePrepareFake::SetBink(AiType aiType, MessageType messageType, const char* filename)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType))
  {
    return false;
  }

  int index{ getSfxAndBinkIndex(aiType, messageType) };
  placeInMapHelper(binkReplaced, index, filename);
  return true;
}

bool AiMessagePrepareFake::SetSfx(AiType aiType, MessageType messageType, const char* filename)
{
  if (!isValidAiType(aiType) || !isValidMessageType(messageType))
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

  if (!lua_isinteger(L, 1) || !(lua_isstring(L, 3) || lua_isnoneornil(L, 3)))
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

  if (!(lua_isinteger(L, 1) && lua_isinteger(L, 2) && (lua_isstring(L, 3) || lua_isnoneornil(L, 3))))
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

  if (!(lua_isinteger(L, 1) && lua_isinteger(L, 2) && (lua_isstring(L, 3) || lua_isnoneornil(L, 3))))
  {
    luaL_error(L, "[aiSwapperHelper]: lua_SetSfx: Wrong input fields.");
  }

  bool res{ AiMessagePrepareFake::SetSfx(static_cast<AiType>(lua_tointeger(L, 1)), static_cast<MessageType>(lua_tointeger(L, 2)), lua_tostring(L, 3)) };
  lua_pushboolean(L, res);
  return 1;
}