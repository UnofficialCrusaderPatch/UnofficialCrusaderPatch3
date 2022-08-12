#pragma once

#include <lua.h>
#include <array>
#include <unordered_map>

/* classes, structs and enums */


enum AiType : int
{
  RAT         = 1,
  SNAKE       = 2,
  PIG         = 3,
  Wolf        = 4,
  SALADIN     = 5,
  CALIPH      = 6,
  SULTAN      = 7,
  RICHARD     = 8,
  FREDERICK   = 9,
  PHILLIP     = 10,
  WAZIR       = 11,
  EMIR        = 12,
  NIZAR       = 13,
  SHERIFF     = 14,
  MARSHAL     = 15,
  ABBOT       = 16,
};


enum MessageType : int
{
  UNKNOWN_1       = 0,
  TAUNT_1         = 1,
  TAUNT_2         = 2,
  TAUNT_3         = 3,
  TAUNT_4         = 4,
  ANGER_1         = 5,
  ANGER_2         = 6,
  PLEAD           = 7,
  NERVOUS_1       = 8,
  NERVOUS_2       = 9,
  VICTORY_1       = 10,
  VICTORY_2       = 11,
  VICTORY_3       = 12,
  VICTORY_4       = 13,
  REQUEST         = 14,
  THANKS          = 15,
  ALLY_DEATH      = 16,
  CONGRATS        = 17,
  BOAST           = 18,
  HELP            = 19,
  EXTRA           = 20,
  UNKNOWN_2       = 21,
  UNKNOWN_3       = 22,
  SIEGE           = 23,
  NO_ATTACK_1     = 24,
  NO_ATTACK_2     = 25,
  NO_HELP_1       = 26,
  NO_HELP_2       = 27,
  NO_SENT         = 28,
  SENT            = 29,
  TEAM_WINNING    = 30,
  TEAM_LOSING     = 31,
  HELP_SENT       = 32,
  WILL_ATTACK     = 33,
};


struct AiMessagePrepareFake
{

  using PrepareAiMsgFunc = void (AiMessagePrepareFake::*)(const char* text, const char* binkFilename, const char* sfxFilename, int someIndex);

  inline static PrepareAiMsgFunc prepareAiMsgFunc{ nullptr };

  inline static char** aMessageFromArray{ nullptr };
  inline static char** aiSfxArray{ nullptr };
  inline static char** aiBinkArray{ nullptr };

  // funcs

  // no safety
  static bool SetMessageFrom(AiType aiType, const char* filename);
  static bool SetBink(AiType aiType, MessageType messageType, const char* filename);
  static bool SetSfx(AiType aiType, MessageType messageType, const char* filename);

  // "this" will not be this class
  void __thiscall detouredSetMessageForAi(int playerIndex, AiType aiType, MessageType messageType);

private:

  inline static constexpr int AI_MESSAGE_TEXT_INDEX{ 231 };

  inline static std::unordered_map<int, std::string> sfxReplaced{};
  inline static std::unordered_map<int, std::string> binkReplaced{};
  inline static std::unordered_map<int, std::string> messageFromReplaced{};

  inline static std::array<std::string, 11> preparedMessages{}; // only the text string is not saved

  static bool isValidAiType(AiType aiType);
  static bool isValidMessageType(MessageType messageType);
  static bool fitsInPreparedText(const char* filename);

  static const char* getMessageFrom(AiType aiType);
  static const char* getBink(int index);
  static const char* getSfx(int index);
  static int getSfxAndBinkIndex(AiType aiType, MessageType messageType);
};

/* LUA */

extern "C" __declspec(dllexport) int __cdecl lua_SetMessageFrom(lua_State * L);
extern "C" __declspec(dllexport) int __cdecl lua_SetBink(lua_State * L);
extern "C" __declspec(dllexport) int __cdecl lua_SetSfx(lua_State * L);