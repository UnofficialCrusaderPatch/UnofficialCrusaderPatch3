#pragma once

#ifdef UCPDLL_EXPORTS
#define UCP3_DLL    __declspec(dllexport)
#else
#define UCP3_DLL    __declspec(dllimport)
#endif

#include <string>




/**

	When logging messages, set the log level with this enum

	Use Verbosity_1 for DEBUG-level messages

	NOTE: this enum was copy-pasted from loguru.hpp
*/
enum ucp_NamedVerbosity : int
{
	// Used to mark an invalid verbosity. Do not log to this level.
	Verbosity_INVALID = -10, // Never do LOG_F(INVALID)

	// You may use Verbosity_OFF on g_stderr_verbosity, but for nothing else!
	Verbosity_OFF = -9, // Never do LOG_F(OFF)

	// Prefer to use ABORT_F or ABORT_S over LOG_F(FATAL) or LOG_S(FATAL).
	Verbosity_FATAL = -3,
	Verbosity_ERROR = -2,
	Verbosity_WARNING = -1,

	// Normal messages. By default written to stderr.
	Verbosity_INFO = 0,

	// Same as Verbosity_INFO in every way.
	Verbosity_0 = 0,

	// Verbosity levels 1-9 are generally not written to stderr, but are written to file.
	Verbosity_1 = +1,
	Verbosity_2 = +2,
	Verbosity_3 = +3,
	Verbosity_4 = +4,
	Verbosity_5 = +5,
	Verbosity_6 = +6,
	Verbosity_7 = +7,
	Verbosity_8 = +8,
	Verbosity_9 = +9,

	// Do not use higher verbosity levels, as that will make grepping log files harder.
	Verbosity_MAX = +9,
};

/**
	Call this function to log a message to the ucp console, and to log files
*/
UCP3_DLL void ucp_log(ucp_NamedVerbosity logLevel, std::string logMessage);



UCP3_DLL FILE* ucp_getFileHandleReadMode(std::string path);


/**
*
	IMPORTANT note for extension developers: do not run this function in your code!

	This function is reserved for the custom binkw32.dll that ucp ships to end-users.
	This binkw32.dll is responsible for initializing ucp at game runtime.

*/
UCP3_DLL void ucp_initialize();