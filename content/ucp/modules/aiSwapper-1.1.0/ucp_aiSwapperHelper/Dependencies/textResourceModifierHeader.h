
#ifndef TEXT_RESOURCE_MODIFIER_HEADER
#define TEXT_RESOURCE_MODIFIER_HEADER

#include <lua.hpp>

#include <ucp3.h>

namespace TextResourceModifierHeader
{
  // Cpp API
  using FuncTextReceiver = void(__stdcall *)(const char *transformedString, void *misc);

  using FuncSetText = bool(__stdcall *)(int offsetIndex, int numInGroup, const char *utf8Str);
  using FuncGetText = const char *(__stdcall *)(int offsetIndex, int numInGroup);
  using FuncTransformText = void(__stdcall *)(const char *utf8Str, FuncTextReceiver receiver, void *misc);
  using FuncGetLanguage = const char *(__stdcall *)();

  inline constexpr char const *NAME_VERSION{"0.3.0"};
  inline constexpr char const *NAME_MODULE{"textResourceModifier"};
  inline constexpr char const *NAME_LIBRARY{"textResourceModifier.dll"};

  inline constexpr char const *NAME_SET_TEXT{"_SetText@12"};
  inline constexpr char const *NAME_GET_TEXT{"_GetText@8"};
  inline constexpr char const *NAME_TRANSFORM_TEXT{"_TransformText@12"};
  inline constexpr char const *NAME_GET_LANGUAGE{"_GetLanguage@0"};

  inline FuncSetText SetText{nullptr};
  inline FuncGetText GetText{nullptr};
  inline FuncTransformText TransformText{nullptr};
  inline FuncGetLanguage GetLanguage{nullptr};

  // returns true if the function variables of this header were successfully filled
  inline bool initModuleFunctions()
  {
    GetLanguage = (FuncGetLanguage)ucp_getProcAddressFromLibraryInModule(NAME_MODULE, NAME_LIBRARY, NAME_GET_LANGUAGE);
    TransformText = (FuncTransformText)ucp_getProcAddressFromLibraryInModule(NAME_MODULE, NAME_LIBRARY, NAME_TRANSFORM_TEXT);
    GetText = (FuncGetText)ucp_getProcAddressFromLibraryInModule(NAME_MODULE, NAME_LIBRARY, NAME_GET_TEXT);
    SetText = (FuncSetText)ucp_getProcAddressFromLibraryInModule(NAME_MODULE, NAME_LIBRARY, NAME_SET_TEXT);

    return SetText && GetText && TransformText && GetLanguage;
  }
}

#endif // TEXT_RESOURCE_MODIFIER_HEADER