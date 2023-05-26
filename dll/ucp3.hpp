

#include "ucp3.h"
#include <string>

inline FILE* ucp_getFileHandle(std::string path, std::string mode, std::string &errorMsg) {
	FILE* result = ucp_getFileHandle(path.c_str(), mode.c_str());
	errorMsg = ucp_getLastErrorMessage();

	return result;
}

inline void ucp_log(ucp_NamedVerbosity logLevel, std::string logMessage) {
	return ucp_log(logLevel, logMessage.c_str());
}