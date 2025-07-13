#include <string>

#include "fasm.h"
#include "windows.h"

#include "core/Core.h"
#include "MemoryModule.h"
#include "io/modules/ModuleManager.h"

constexpr int BUFFER_SIZE = 1000 * 64;

int fasmState = 0;
unsigned char buffer[BUFFER_SIZE];

typedef int (__stdcall* func_Assemble)(void* lpSource, void* lpMemory, int cbMemorySize, short nPassesLimit, void* hDisplayPipe);
func_Assemble fasm_Assemble = 0;

enum FasmCondition : int
{
	OK = 00,
	WORKING = 01,
	FERROR = 02,
	INVALID_PARAMETER = -1,
	OUT_OF_MEMORY = -2,
	STACK_OVERFLOW = -3,
	SOURCE_NOT_FOUND = -4,
	UNEXPECTED_END_OF_SOURCE = -5,
	CANNOT_GENERATE_CODE = -6,
	FORMAT_LIMITATIONS_EXCEEDED = -7,
	WRITE_FAILED = -8,
};

enum FasmError : int
{
	FILE_NOT_FOUND = -101,
	ERROR_READING_FILE = -102,
	INVALID_FILE_FORMAT = -103,
	INVALID_MACRO_ARGUMENTS = -104,
	INCOMPLETE_MACRO = -105,
	UNEXPECTED_CHARACTERS = -106,
	INVALID_ARGUMENT = -107,
	ILLEGAL_INSTRUCTION = -108,
	INVALID_OPERAND = -109,
	INVALID_OPERAND_SIZE = -110,
	OPERAND_SIZE_NOT_SPECIFIED = -111,
	OPERAND_SIZES_DO_NOT_MATCH = -112,
	INVALID_ADDRESS_SIZE = -113,
	ADDRESS_SIZES_DO_NOT_AGREE = -114,
	DISALLOWED_COMBINATION_OF_REGISTERS = -115,
	LONG_IMMEDIATE_NOT_ENCODABLE = -116,
	RELATIVE_JUMP_OUT_OF_RANGE = -117,
	INVALID_EXPRESSION = -118,
	INVALID_ADDRESS = -119,
	INVALID_VALUE = -120,
	VALUE_OUT_OF_RANGE = -121,
	UNDEFINED_SYMBOL = -122,
	INVALID_USE_OF_SYMBOL = -123,
	NAME_TOO_LONG = -124,
	INVALID_NAME = -125,
	RESERVED_WORD_USED_AS_SYMBOL = -126,
	SYMBOL_ALREADY_DEFINED = -127,
	MISSING_END_QUOTE = -128,
	MISSING_END_DIRECTIVE = -129,
	UNEXPECTED_INSTRUCTION = -130,
	EXTRA_CHARACTERS_ON_LINE = -131,
	SECTION_NOT_ALIGNED_ENOUGH = -132,
	SETTING_ALREADY_SPECIFIED = -133,
	DATA_ALREADY_DEFINED = -134,
	TOO_MANY_REPEATS = -135,
	SYMBOL_OUT_OF_SCOPE = -136,
	USER_ERROR = -140,
	ASSERTION_FAILED = -141,
};

typedef struct _FasmLineHeader {
	char* file_path;
	int line_number;
	union {
		int file_offset;
		int macro_offset_line;
	};
	_FasmLineHeader* macro_line;
} LINE_HEADER;

typedef struct _FasmState {
	FasmCondition condition;
	union {
		FasmError error_code;
		int output_length;
	};
	union {
		__int8* output_data;
		_FasmLineHeader* error_data;
	};
} STATE;


std::map<FasmError, const char *> niceErrorNames = {

	/** General errorsand conditions */

	//{0, "OK"}, // STATE points to output
	//{1, "WORKING"},
	//{2, "ERROR"}, // STATE contains error code
	//{-1, "INVALID_PARAMETER"},
	//{-2, "OUT_OF_MEMORY"},
	//{-3, "STACK_OVERFLOW"},
	//{-4, "SOURCE_NOT_FOUND"},
	//{-5, "UNEXPECTED_END_OF_SOURCE"},
	//{-6, "CANNOT_GENERATE_CODE"},
	//{-7, "FORMAT_LIMITATIONS_EXCEDDED"},
	//{-8, "WRITE_FAILED"},
	//{-9, "INVALID_DEFINITION"},

	/** Error codes for ERROR condition */

	{FasmError::FILE_NOT_FOUND, "FILE_NOT_FOUND"},
	{FasmError::ERROR_READING_FILE, "ERROR_READING_FILE"},
	{FasmError::INVALID_FILE_FORMAT, "INVALID_FILE_FORMAT"},
	{FasmError::INVALID_MACRO_ARGUMENTS, "INVALID_MACRO_ARGUMENTS"},
	{FasmError::INCOMPLETE_MACRO, "INCOMPLETE_MACRO"},
	{FasmError::UNEXPECTED_CHARACTERS, "UNEXPECTED_CHARACTERS"},
	{FasmError::INVALID_ARGUMENT, "INVALID_ARGUMENT"},
	{FasmError::ILLEGAL_INSTRUCTION, "ILLEGAL_INSTRUCTION"},
	{FasmError::INVALID_OPERAND, "INVALID_OPERAND"},
	{FasmError::INVALID_OPERAND_SIZE, "INVALID_OPERAND_SIZE"},
	{FasmError::OPERAND_SIZE_NOT_SPECIFIED, "OPERAND_SIZE_NOT_SPECIFIED"},
	{FasmError::OPERAND_SIZES_DO_NOT_MATCH, "OPERAND_SIZES_DO_NOT_MATCH"},
	{FasmError::INVALID_ADDRESS_SIZE, "INVALID_ADDRESS_SIZE"},
	{FasmError::ADDRESS_SIZES_DO_NOT_AGREE, "ADDRESS_SIZES_DO_NOT_AGREE"},
	{FasmError::DISALLOWED_COMBINATION_OF_REGISTERS, "DISALLOWED_COMBINATION_OF_REGISTERS"},
	{FasmError::LONG_IMMEDIATE_NOT_ENCODABLE, "LONG_IMMEDIATE_NOT_ENCODABLE"},
	{FasmError::RELATIVE_JUMP_OUT_OF_RANGE, "RELATIVE_JUMP_OUT_OF_RANGE"},
	{FasmError::INVALID_EXPRESSION, "INVALID_EXPRESSION"},
	{FasmError::INVALID_ADDRESS, "INVALID_ADDRESS"},
	{FasmError::INVALID_VALUE, "INVALID_VALUE"},
	{FasmError::VALUE_OUT_OF_RANGE, "VALUE_OUT_OF_RANGE"},
	{FasmError::UNDEFINED_SYMBOL, "UNDEFINED_SYMBOL"},
	{FasmError::INVALID_USE_OF_SYMBOL, "INVALID_USE_OF_SYMBOL"},
	{FasmError::NAME_TOO_LONG, "NAME_TOO_LONG"},
	{FasmError::INVALID_NAME, "INVALID_NAME"},
	{FasmError::RESERVED_WORD_USED_AS_SYMBOL, "RESERVED_WORD_USED_AS_SYMBOL"},
	{FasmError::SYMBOL_ALREADY_DEFINED, "SYMBOL_ALREADY_DEFINED"},
	{FasmError::MISSING_END_QUOTE, "MISSING_END_QUOTE"},
	{FasmError::MISSING_END_DIRECTIVE, "MISSING_END_DIRECTIVE"},
	{FasmError::UNEXPECTED_INSTRUCTION, "UNEXPECTED_INSTRUCTION"},
	{FasmError::EXTRA_CHARACTERS_ON_LINE, "EXTRA_CHARACTERS_ON_LINE"},
	{FasmError::SECTION_NOT_ALIGNED_ENOUGH, "SECTION_NOT_ALIGNED_ENOUGH"},
	{FasmError::SETTING_ALREADY_SPECIFIED, "SETTING_ALREADY_SPECIFIED"},
	{FasmError::DATA_ALREADY_DEFINED, "DATA_ALREADY_DEFINED"},
	{FasmError::TOO_MANY_REPEATS, "TOO_MANY_REPEATS"},
	{FasmError::SYMBOL_OUT_OF_SCOPE, "SYMBOL_OUT_OF_SCOPE"},
	{FasmError::USER_ERROR, "USER_ERROR"},
	{FasmError::ASSERTION_FAILED, "ASSERTION_FAILED"},
};

const char * fasmPath = "ucp/code/vendor/fasm/fasm.dll";

//TODO: implement in memory dll opening
int luaAssemble(lua_State* L) {

	if (fasmState < 0) {
		return luaL_error(L, "fasm cannot be used");
	}

	if (fasmState == 0) {
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

	const char* script = luaL_checkstring(L, 1);
	int result = fasm_Assemble((void*) script, buffer, BUFFER_SIZE, 100, NULL);
	STATE* state = (STATE*) buffer;

	if (result == FasmCondition::OK) {
		lua_pushlstring(L, (const char*) state->output_data, state->output_length);
		return 1;
	}
	else {
		Core::getInstance().log(Verbosity_INFO, "\n" + std::string(script));
		if (result == FasmCondition::FERROR) {
			return luaL_error(L, ("error in script: " + std::string(niceErrorNames.at(state->error_code)) + " (" + std::to_string((int)state->error_code) + ") at line: " + std::to_string((int)state->error_data->line_number)).c_str());
		}
		return luaL_error(L, ("assembling script failed: " + std::to_string(result)).c_str());
	}

}
