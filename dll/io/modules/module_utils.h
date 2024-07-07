#pragma once

#include <string>
#include "io/modules/ModuleManager.h"


ExtensionHandle* getLoadedExtensionForName(const std::string& name);
ExtensionHandle* getExtensionHandleForPath(const std::string& filename, std::string& pathInsideExtension, std::string& errorMsg);