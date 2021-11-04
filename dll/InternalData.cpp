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
#include "dllmain.h"

#include "MemoryModule.h"


namespace LuaIO {

	const std::string ucp_code_pre = R"V0G0N(
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

)V0G0N";

	//https://stackoverflow.com/questions/2933295/embed-text-file-in-a-resource-in-a-native-windows-application
	bool LoadFileInResource(int name, int type, DWORD& size, const char*& data)
	{
		//HMODULE handle = ::GetModuleHandle(NULL); // returns crusader exe handle
		HMODULE handle = hModule;
		HRSRC rc = ::FindResource(handle, MAKEINTRESOURCE(name),
			MAKEINTRESOURCE(type));

		if (rc == 0) {
			return false;
		}
		else {
			HGLOBAL rcData = ::LoadResource(handle, rc);
			size = ::SizeofResource(handle, rc);
			if (rcData == 0) {
				return false;
			}
			else {
				data = static_cast<const char*>(::LockResource(rcData));
				return true;
			}
			
		}
		return false;
	}

	bool internalDataInitialized = false;
	const char* internalData = NULL;
	DWORD internalDataSize = 0;
	zip_t* internalDataZip = NULL;

	bool initInternalData() {
		if (internalDataInitialized == false) {
			internalDataInitialized = LoadFileInResource(IDR_INTERNALDATAFILE, LUAIDF, internalDataSize, internalData);
		}

		if (!internalDataInitialized) {
			return false;
		}

		if (internalDataZip == NULL) {
			internalDataZip = zip_stream_open(internalData, internalDataSize, 0, 'r');
		}

		if (internalDataZip == NULL) {
			return false;
		}

		return true;
	}

	/**
	 * Don't forget to free the result after use.
	 * 
	 * \param path
	 * \return 
	 */
	std::string readInternalFile(std::string path) {
		if (path == "ucp/code/pre.lua") {
			return ucp_code_pre;
		}

		if (!initInternalData()) return std::string();

		char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(internalDataZip, path.c_str()) != 0) {
			return std::string();
		}

		zip_entry_read(internalDataZip, (void**)& buf, &bufsize);
		zip_entry_close(internalDataZip);

		//Blasphemy! Alternative: std::unique_ptr with a custom deleter to call free.
		std::string result(buf, bufsize);
		free(buf);

		return result;
	};

	std::map<std::string, HMEMORYMODULE> dllMap;

	HMEMORYMODULE loadInternalDLL(std::string path) {
		std::map<std::string, HMEMORYMODULE>::iterator it;

		it = dllMap.find(path);
		if (it != dllMap.end()) {
			return it->second;
		}

		if (!initInternalData()) return 0;
		unsigned char* buf = NULL;
		size_t bufsize = 0;

		if (zip_entry_open(internalDataZip, path.c_str()) != 0) {
			return 0;
		}

		zip_entry_read(internalDataZip, (void**)& buf, &bufsize);
		zip_entry_close(internalDataZip);

		HMEMORYMODULE handle = MemoryLoadLibrary((void*) buf, (size_t) bufsize);
		free(buf);

		if (handle == NULL)
		{
			MessageBoxA(0, ("Cannot load dll from memory: " + path).c_str(), "ERROR", MB_OK);
			return 0;
		}

		dllMap[path] = handle;
		
		return handle;
	}

	FARPROC loadFunctionFromInternalDLL(std::string dllPath, std::string functionName) {
		HMEMORYMODULE handle = loadInternalDLL(dllPath);
		if (handle == 0) return 0;

		return MemoryGetProcAddress(handle, functionName.c_str());
	}



}