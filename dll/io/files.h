#pragma once

#include <stdio.h>
#include <string>

FILE* getFilePointer(std::string filename, std::string mode, std::string& errorMsg);
FILE* getFilePointer(std::string filename, std::string mode, std::string& errorMsg, bool overridePathSanitization);
int getFileDescriptor(std::string filename, int mode, int perm, std::string& errorMsg);
int getFileDescriptor(std::string filename, int mode, int perm, std::string& errorMsg, bool overridePathSanitization);