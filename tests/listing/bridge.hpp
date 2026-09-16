#pragma once
#ifdef _WIN32
#include <windows.h>
#endif
#include "io/modules/ZipDirectoryListing.h"
#include <map>
#include <memory>
#include <regex>
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

// Only the surrounding backend services are substitutes. The four production
// Lua listing functions and both production Core path routers compile unchanged.
class ModuleHandleException : public std::runtime_error {
public:
	using std::runtime_error::runtime_error;
};

class Core {
public:
	std::filesystem::path UCP_DIR;
	static Core& getInstance() { static Core core; return core; }
	void log(int, const std::string&) {}
	bool sanitizePath(std::string path, std::string& result) {
		std::replace(path.begin(), path.end(), '\\', '/'); result = path; return !path.empty();
	}
	bool resolveAliasedPath(std::string& path) {
		if (path.rfind("test-alias/", 0) != 0) return false;
		path = "ucp/modules/sample-1.0.0/" + path.substr(11); return true;
	}
	bool pathIsInModuleDirectory(const std::string&, std::string&, std::string&, std::string&);
	bool pathIsInPluginDirectory(const std::string&, std::string&, std::string&, std::string&);
};

class ExtensionHandle {
	std::string root;
	zip_t* archive = nullptr;
public:
	ExtensionHandle(const std::string& path) : root(path) {
		if (!std::filesystem::is_directory(path)) {
			archive = zip_open((path + ".zip").c_str(), 0, 'r');
			if (!archive) throw ModuleHandleException("Cannot mount test archive");
		}
	}
	~ExtensionHandle() { if (archive) zip_close(archive); }
	std::vector<std::string> list(const std::string& path, bool directories) {
		try { return archive ? ExtensionListing::zip(archive, path, directories) : ExtensionListing::folder(root, path, directories); }
		catch (const std::exception& e) { throw ModuleHandleException(e.what()); }
	}
	std::vector<std::string> listFiles(const std::string& path) { return list(path, false); }
	std::vector<std::string> listDirectories(const std::string& path) { return list(path, true); }
};
using ModuleHandle = ExtensionHandle;

class ModuleHandleManager {
	std::map<std::string, std::unique_ptr<ExtensionHandle>> handles;
public:
	static ModuleHandleManager& getInstance() { static ModuleHandleManager manager; return manager; }
	ModuleHandle* getModuleHandle(const std::string& path, const std::string&) {
		if (!handles.count(path)) handles[path] = std::make_unique<ModuleHandle>(path);
		return handles[path].get();
	}
	ExtensionHandle* getExtensionHandle(const std::string& path, const std::string& name, bool) { return getModuleHandle(path, name); }
};

constexpr int Verbosity_WARNING = 1;
namespace LuaIO {
	int luaFilesList(lua_State*);
	int luaDirectoriesList(lua_State*);
	int luaListFiles(lua_State*);
	int luaListDirectories(lua_State*);
}
