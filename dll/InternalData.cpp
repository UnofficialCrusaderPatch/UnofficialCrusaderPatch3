/*****************************************************************//**
 * \file   InternalData.cpp
 * \brief  
 * 
 * \author gynt
 * \date   September 2021
 *********************************************************************/

#include <windows.h>
#include "InternalData.h"
#include "internal-data-def.h"

namespace LuaIO {

	struct ZipFileEntry {
		char fileName[1020];
		unsigned long pointer;
	};

	struct ZipFile {
		int entryCount;
		ZipFileEntry* entries;
		unsigned char* data;
	};

	//https://stackoverflow.com/questions/2933295/embed-text-file-in-a-resource-in-a-native-windows-application
	void LoadFileInResource(int name, int type, DWORD& size, const char*& data)
	{
		HMODULE handle = ::GetModuleHandle(NULL);
		HRSRC rc = ::FindResource(handle, MAKEINTRESOURCE(name),
			MAKEINTRESOURCE(type));

		if (rc == 0) {
			size = 0;
			data = 0;
			return;
		}
		else {
			HGLOBAL rcData = ::LoadResource(handle, rc);
			size = ::SizeofResource(handle, rc);
			data = static_cast<const char*>(::LockResource(rcData));
		}

	}


	void readFileEntries() {
		ZipFile file;

		
		DWORD size = 0;
		const char* data = NULL;
		LoadFileInResource(IDR_INTERNALDATAFILE, LUAIDF, size, data);
		/* Access bytes in data - here's a simple example involving text output*/
		// The text stored in the resource might not be NULL terminated.
		char* buffer = new char[size + 1];
		::memcpy(buffer, data, size);
		buffer[size] = 0; // NULL terminator
		::printf("Contents of text file: %s\n", buffer); // Print as ASCII text
		delete[] buffer;
		return 0;
	};

	

	const std::map<std::string, std::string> internalData = {
		//Literal data will go here.
		{"ucp/code/pre.lua", 
R"V0G0N(
require = function(path)

	if package.loaded[path] then return package.loaded[path] end	

	local sanitizedPath = "ucp/code/" .. path:gsub("[.]", "/")
	local filePath = sanitizedPath .. ".lua"
	local folderPath = sanitizedPath .. "/init.lua"
	
	local f, message = io.open(filePath, "r")
	if not f then 
		f, message2 = io.open(folderPath, "r")
		if not f then
			error(message .. "\n" .. message2)
		end
	end

	local contents = f:read("*all")
	local func = load(contents, sanitizedPath, "t", _G)
	local status, result = pcall(func)

	if not status then
		error(result)
	end

	package.loaded[path] = result
	
	return result
end
)V0G0N"},
	};
}