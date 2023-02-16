#pragma once

#include <string>
#include <vector>
#include <filesystem>

bool sanitizeRelativePath(const std::string& path, std::string& result);

std::vector<unsigned char> HexToBytes(const std::string& hex);

bool getAppDataPath(std::filesystem::path& appDataPath);