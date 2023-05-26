#include "ucp3.h"
#include "core/Core.h"
#include "io/modules/ModuleHandle.h"
#include "io/files.h"

std::string errorMsg;

void ucp_initialize() {
	if (!Core::getInstance().isInitialized) {
		Core::getInstance().initialize();
	}
	else {
		MessageBoxA(NULL, "Cannot initialize UCP Core twice", "FATAL", MB_OK);
		ucp_log(Verbosity_FATAL, "Cannot initialize UCP Core twice");
	}
 	
}

void ucp_log(ucp_NamedVerbosity logLevel, const char * logMessage) {
	Core::getInstance().log(logLevel, logMessage);
}

FILE* ucp_getFileHandle(const char * filename, const char * mode) {
	return getFileHandle(filename, mode, errorMsg);
}

const char * ucp_getLastErrorMessage() {
	return errorMsg.c_str();
}