/*****************************************************************//**
 * \file   Core.h
 * \brief  This is where the core framework is written. It uses a singleton paradigm.
 * 
 * \author gynt
 *********************************************************************/
#pragma once

#include "framework.h"
#include "RuntimePatchingSystem.h"
#include "console.h"



class Core
{

public:
	static Core& getInstance()
	{
		static Core    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}

private:
	Core() {};

public:

	Core(Core const&) = delete;
	void operator=(Core const&) = delete;

	HANDLE consoleThread = 0;

	void initialize();

};