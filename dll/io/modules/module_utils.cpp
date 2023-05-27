
#include "io/modules/module_utils.h"

/** 
 Argument should be the extension name without the versioning!

 This function works because the lua sides loads all extensions in the right order, before executing any scripts of each extension (in the same order)
 Later loaded extensions therefore can reference earlier loaded extensions.
*/
ExtensionHandle* getLoadedExtensionForName(const std::string& extensionName) {
	return ModuleHandleManager::getInstance().loadedExtensionHandle(extensionName);
}

ExtensionHandle* getExtensionHandleForPath(const std::string& filename, std::string &pathInsideExtension, std::string &errorMsg) {

	std::string sanitizedPath;

	if (!Core::getInstance().sanitizePath(filename, sanitizedPath)) {
		errorMsg = ("Invalid path: " + filename + "\n reason: " + sanitizedPath);
		return NULL;
	}

	ExtensionHandle* mh = NULL;
	if (Core::getInstance().pathIsInInternalCodeDirectory(sanitizedPath, pathInsideExtension)) {

		try {
			mh = ModuleHandleManager::getInstance().getLatestCodeHandle();
			return mh;
		}
		catch (ModuleHandleException e) {
			errorMsg = e.what();
			return NULL;
		}
	}
	else {

		std::string basePath;
		std::string extension;

		if (Core::getInstance().pathIsInModuleDirectory(sanitizedPath, extension, basePath, pathInsideExtension)) {

			try {
				mh = ModuleHandleManager::getInstance().getModuleHandle(basePath, extension);
				return mh;
			}
			catch (ModuleHandleException e) {
				errorMsg = e.what();
				return NULL;
			}

		}
		else {


			if (Core::getInstance().pathIsInPluginDirectory(sanitizedPath, extension, basePath, pathInsideExtension)) {

				try {
					mh = ModuleHandleManager::getInstance().getExtensionHandle(basePath, extension, false);
					return mh;
				}
				catch (ModuleHandleException e) {
					errorMsg = e.what();
					return NULL;
				}

			}
			else {

				// A regular file outside of the code module or modules directory

				errorMsg = "no extension handle required for this path";
				return NULL;
			}

		}
	}



}