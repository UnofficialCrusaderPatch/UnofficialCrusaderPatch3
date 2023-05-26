#pragma once

#include <stdio.h>
#include <string>

FILE* getFileHandle(std::string filename, std::string mode, std::string& errorMsg);