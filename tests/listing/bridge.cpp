#include "bridge.hpp"
#include <fstream>
#include <iostream>

int main() {
	try {
		const std::filesystem::path fixture = "bridge-fixture";
		for (const std::string storage : {"folder", "zip"}) {
			for (const std::string kind : {"modules", "plugins"}) {
				const auto root = fixture / storage / kind / "sample-1.0.0";
				std::filesystem::create_directories(root.parent_path());
				if (storage == "folder") {
					std::filesystem::create_directories(root / "code/nested");
					std::ofstream(root / "definition.yml") << "data";
					std::ofstream(root / "code/main.lua") << "data";
					std::ofstream(root / "code/nested/file.bin") << "data";
				}
				else {
					auto archive = zip_open((root.string() + ".zip").c_str(), 0, 'w');
					if (!archive) throw std::runtime_error("Cannot create fixture");
					for (const char* name : {"definition.yml", "code/main.lua", "code/nested/file.bin"}) {
						if (zip_entry_open(archive, name) != 0 || zip_entry_write(archive, "data", 4) != 0 || zip_entry_close(archive) != 0)
							throw std::runtime_error("Cannot write fixture");
					}
					zip_close(archive);
				}
			}
		}
		lua_State* state = luaL_newstate();
		luaL_openlibs(state);
		lua_register(state, "files", LuaIO::luaFilesList);
		lua_register(state, "directories", LuaIO::luaDirectoriesList);
		lua_register(state, "oldFiles", LuaIO::luaListFiles);
		lua_register(state, "oldDirectories", LuaIO::luaListDirectories);
		for (const std::string storage : {"folder", "zip"}) {
			// The physical UCP root differs from the virtual prefix in every case.
			Core::getInstance().UCP_DIR = fixture / storage;
			const char* script = R"lua(
for _,kind in ipairs({'modules','plugins'}) do
 local root='ucp/'..kind..'/sample-1.0.0'
 for _,suffix in ipairs({'','/'}) do
  assert(table.concat(files(root..suffix),',')==root..'/definition.yml')
  assert(table.concat(directories(root..suffix),',')==root..'/code/')
  assert(oldFiles(root..suffix)==root..'/definition.yml')
  assert(oldDirectories(root..suffix)==root..'/code/')
 end
 for _,suffix in ipairs({'code','code/'}) do
  assert(table.concat(files(root..'/'..suffix),',')==root..'/code/main.lua')
  assert(table.concat(directories(root..'/'..suffix),',')==root..'/code/nested/')
  assert(oldFiles(root..'/'..suffix)==root..'/code/main.lua')
  assert(oldDirectories(root..'/'..suffix)==root..'/code/nested/')
 end
 for _,api in ipairs({files,directories,oldFiles,oldDirectories}) do
  assert(not pcall(api,root..'/missing'))
  assert(not pcall(api,root..'/missing%with%format'))
 end
end
assert(table.concat(files('test-alias/code/'),',')=='ucp/modules/sample-1.0.0/code/main.lua')
assert(table.concat(directories('test-alias/'),',')=='ucp/modules/sample-1.0.0/code/')
assert(oldFiles('test-alias/code/')=='ucp/modules/sample-1.0.0/code/main.lua')
assert(oldDirectories('test-alias/')=='ucp/modules/sample-1.0.0/code/')
)lua";
			if (luaL_dostring(state, script) != LUA_OK) throw std::runtime_error(lua_tostring(state, -1));
		}
		lua_close(state);
		std::cout << "104 production Lua listing assertions passed for ZIP/folder modules/plugins, roots, aliases and errors\n";
		return 0;
	}
	catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
