#pragma once

#include <stdio.h>
#include <string>

FILE* getFilePointer(const std::string &filename, const std::string &mode, std::string& errorMsg);
FILE* getFilePointer(const std::string &filename, const std::string &mode, std::string& errorMsg, bool overridePathSanitization);
int getFileDescriptor(const std::string &filename, const int mode, const int perm, std::string& errorMsg);
int getFileDescriptor(const std::string &filename, const int mode, const int perm, std::string& errorMsg, const bool overridePathSanitization);
int getFileSize(const std::string& filename, std::string& errorMsg);
int getFileContents(const std::string& filename, void* buffer, int size, std::string& errorMsg);