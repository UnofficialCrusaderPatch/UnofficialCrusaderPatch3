/*****************************************************************//**
 * \file   console.h
 * \brief  Code to run the console window
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include <iostream>

void RunUserInputLoop();
void ConsoleThread();
void initializeConsole();
void teardownConsole();

void logToConsole(const int verbosity, const std::string& message);