#pragma once

#include <string>
#include "io/modules/ModuleHandle.h"


ExtensionHandle* getLoadedExtensionForName(const std::string& name);
ExtensionHandle* getExtensionHandleForPath(const std::string& filename, std::string& pathInsideExtension, std::string& errorMsg);