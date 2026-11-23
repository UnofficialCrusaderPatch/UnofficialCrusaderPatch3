#pragma once

#include <lua.hpp>
#include <string>


// logFileSuffix is inserted before ".log" in both log file names ("" keeps ucp3.log and ucp3-error-log.log)
void initializeLogger(int logLevel, int consoleLogLevel, const std::string& logFileSuffix);

void deinitializeLogger();

void loguruVLOG_F(int logLevel, std::string message);

void addLoggingFunctions(lua_State* L);