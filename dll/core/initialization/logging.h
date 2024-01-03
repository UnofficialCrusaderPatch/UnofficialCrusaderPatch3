#pragma once

#include <lua.hpp>
#include <string>


void initializeLogger(int logLevel, int consoleLogLevel);

void deinitializeLogger();

void loguruVLOG_F(int logLevel, std::string message);

void addLoggingFunctions(lua_State* L);