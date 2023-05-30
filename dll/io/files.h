#pragma once

#include <stdio.h>
#include <string>

FILE* getFilePointer(std::string filename, std::string mode, std::string& errorMsg);
int getFileDescriptor(std::string filename, int mode, std::string& errorMsg);