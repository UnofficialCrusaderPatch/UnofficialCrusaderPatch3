#pragma once
#include <framework.h>
#include <string>
namespace io {
    // Convert a wide Unicode string to an UTF8 string
    std::string utf8_encode(const std::wstring& wstr);

    // Convert an UTF8 string to a wide Unicode String
    std::wstring utf8_decode(const std::string& str);
}