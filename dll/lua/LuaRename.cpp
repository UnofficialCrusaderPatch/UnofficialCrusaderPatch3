#include "lua/LuaRename.h"

#include <string>
#include <filesystem>

namespace LuaIO {
	// Whether the canonical path is the canonical folder or lies inside it
	static bool isWithin(const std::filesystem::path& folder, const std::filesystem::path& path) {
		const std::filesystem::path relative = path.lexically_relative(folder);
		return !relative.empty() && *relative.begin() != "..";
	}

	// The entry that a rename of path acts on: its last name in its link-resolved parent folder,
	// or an empty path when path does not end in a name
	static std::filesystem::path resolveEntry(const std::filesystem::path& path) {
		const std::filesystem::path entry = path.has_filename() ? path : path.parent_path();
		const std::filesystem::path name = entry.filename();
		if (name.empty() || name == "." || name == "..") return {};
		return std::filesystem::canonical(entry.parent_path()) / name;
	}

	// rename(folder, from, to): the folders holding both entries must resolve inside the existing folder
	int luaRename(lua_State* L) {
		std::string folder = luaL_checkstring(L, 1);
		std::string from = luaL_checkstring(L, 2);
		std::string to = luaL_checkstring(L, 3);
		try {
			const std::filesystem::path current = std::filesystem::current_path();
			const std::filesystem::path root = std::filesystem::canonical(current / folder);
			const std::filesystem::path source = resolveEntry(current / from);
			const std::filesystem::path target = resolveEntry(current / to);
			if (source.empty() || target.empty() || !isWithin(root, source.parent_path()) || !isWithin(root, target.parent_path())) {
				lua_pushnil(L);
				lua_pushfstring(L, "cannot rename path '%s' to '%s', reason: the paths must stay inside '%s'", from.c_str(), to.c_str(), folder.c_str());
				return 2;
			}
			std::filesystem::rename(source, target);
		}
		catch (std::filesystem::filesystem_error err) {
			lua_pushnil(L);
			lua_pushfstring(L, "cannot rename path '%s' to '%s', reason: %s", from.c_str(), to.c_str(), err.what());
			return 2;
		}

		lua_pushboolean(L, true);

		return 1;
	}
}
