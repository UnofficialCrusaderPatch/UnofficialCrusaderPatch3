#include <string>

#include "fasm.h"
#include "windows.h"

#include "core/Core.h"
#include "MemoryModule.h"
#include "io/modules/ModuleHandle.h"

constexpr int FASM_BUFFER_SIZE = 1000 * 64;

int fasmState = 0;
unsigned char buffer[FASM_BUFFER_SIZE];

typedef DWORD (__stdcall* func_Assemble)(void* lpSource, void* lpMemory, int cbMemorySize, short nPassesLimit, void* hDisplayPipe);
func_Assemble fasm_Assemble = 0;

struct FASM_STATE {
	DWORD condition;
	union {
		DWORD output_length;
		DWORD error_code;
	};
	union {
		DWORD output_data;
		DWORD error_line;
	};
};

struct LINE_HEADER {
	DWORD file_path;
	DWORD line_number;
	union {
		DWORD file_offset;
		DWORD macro_calling_line;
	};
	DWORD macro_line;
};


/** General errorsand conditions */

DWORD FASM_OK = 0; // FASM_STATE points to output
DWORD FASM_WORKING = 1;
DWORD FASM_ERROR = 2; // FASM_STATE contains error code
DWORD FASM_INVALID_PARAMETER = -1;
DWORD FASM_OUT_OF_MEMORY = -2;
DWORD FASM_STACK_OVERFLOW = -3;
DWORD FASM_SOURCE_NOT_FOUND = -4;
DWORD FASM_UNEXPECTED_END_OF_SOURCE = -5;
DWORD FASM_CANNOT_GENERATE_CODE = -6;
DWORD FASM_FORMAT_LIMITATIONS_EXCEDDED = -7;
DWORD FASM_WRITE_FAILED = -8;
DWORD FASM_INVALID_DEFINITION = -9;

/** Error codes for FASM_ERROR condition */

DWORD FASMERR_FILE_NOT_FOUND = -101;
DWORD FASMERR_ERROR_READING_FILE = -102;
DWORD FASMERR_INVALID_FILE_FORMAT = -103;
DWORD FASMERR_INVALID_MACRO_ARGUMENTS = -104;
DWORD FASMERR_INCOMPLETE_MACRO = -105;
DWORD FASMERR_UNEXPECTED_CHARACTERS = -106;
DWORD FASMERR_INVALID_ARGUMENT = -107;
DWORD FASMERR_ILLEGAL_INSTRUCTION = -108;
DWORD FASMERR_INVALID_OPERAND = -109;
DWORD FASMERR_INVALID_OPERAND_SIZE = -110;
DWORD FASMERR_OPERAND_SIZE_NOT_SPECIFIED = -111;
DWORD FASMERR_OPERAND_SIZES_DO_NOT_MATCH = -112;
DWORD FASMERR_INVALID_ADDRESS_SIZE = -113;
DWORD FASMERR_ADDRESS_SIZES_DO_NOT_AGREE = -114;
DWORD FASMERR_DISALLOWED_COMBINATION_OF_REGISTERS = -115;
DWORD FASMERR_LONG_IMMEDIATE_NOT_ENCODABLE = -116;
DWORD FASMERR_RELATIVE_JUMP_OUT_OF_RANGE = -117;
DWORD FASMERR_INVALID_EXPRESSION = -118;
DWORD FASMERR_INVALID_ADDRESS = -119;
DWORD FASMERR_INVALID_VALUE = -120;
DWORD FASMERR_VALUE_OUT_OF_RANGE = -121;
DWORD FASMERR_UNDEFINED_SYMBOL = -122;
DWORD FASMERR_INVALID_USE_OF_SYMBOL = -123;
DWORD FASMERR_NAME_TOO_LONG = -124;
DWORD FASMERR_INVALID_NAME = -125;
DWORD FASMERR_RESERVED_WORD_USED_AS_SYMBOL = -126;
DWORD FASMERR_SYMBOL_ALREADY_DEFINED = -127;
DWORD FASMERR_MISSING_END_QUOTE = -128;
DWORD FASMERR_MISSING_END_DIRECTIVE = -129;
DWORD FASMERR_UNEXPECTED_INSTRUCTION = -130;
DWORD FASMERR_EXTRA_CHARACTERS_ON_LINE = -131;
DWORD FASMERR_SECTION_NOT_ALIGNED_ENOUGH = -132;
DWORD FASMERR_SETTING_ALREADY_SPECIFIED = -133;
DWORD FASMERR_DATA_ALREADY_DEFINED = -134;
DWORD FASMERR_TOO_MANY_REPEATS = -135;
DWORD FASMERR_SYMBOL_OUT_OF_SCOPE = -136;
DWORD FASMERR_USER_ERROR = -140;
DWORD FASMERR_ASSERTION_FAILED = -141;

const char * fasmPath = "ucp/code/vendor/fasm/fasm.dll";

//TODO: implement in memory dll opening
int luaAssemble(lua_State* L) {

	if (fasmState < 0) {
		return luaL_error(L, "fasm cannot be used");
	}

	if (fasmState == 0) {
		std::string path;
		bool isInternal;
		if (!Core::getInstance().resolvePath(fasmPath, path, isInternal)) {
			return luaL_error(L, "could not resolve fasm dll path");
		}

		try {
			ModuleHandle* mh = ModuleHandleManager::getInstance().getLatestCodeHandle();

			std::string dllPath = "vendor/fasm/fasm.dll";
			void* handle = mh->loadLibrary(dllPath);
			if (handle == NULL) {
				fasmState = -1;
				return luaL_error(L, "could not find dll fasm.dll");
			}
			FARPROC r = mh->loadFunctionFromLibrary(handle, "fasm_Assemble");
			if (r == 0) {
				fasmState = -2;
				return luaL_error(L, "could not find function fasm_Assemble or dll fasm");
			}
			fasm_Assemble = (func_Assemble)r;

			fasmState = 1;
		}
		catch (ModuleHandleException e) {
			fasmState = -3;
			return luaL_error(L, e.what());
		}

	}

	DWORD result = fasm_Assemble((void*)luaL_checkstring(L, 1), buffer, FASM_BUFFER_SIZE, 100, NULL);
	FASM_STATE* state = (struct FASM_STATE*) buffer;

	if (result == FASM_OK) {
		lua_pushlstring(L, (const char*) state->output_data, state->output_length);
		return 1;
	}
	else {
		if (result == FASM_ERROR) {
			return luaL_error(L, ("error in script: " + std::to_string((int) state->error_code)).c_str());
		}
		return luaL_error(L, ("assembling script failed: " + std::to_string(result)).c_str());
	}

}
