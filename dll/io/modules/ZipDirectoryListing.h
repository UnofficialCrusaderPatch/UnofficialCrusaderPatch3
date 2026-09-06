#pragma once

#include "io/modules/DirectoryListing.h"
#include "zip.h"
#include <limits>

namespace ExtensionListing {

inline std::vector<std::string> zip(zip_t* archive, const std::string& path, bool directories) {
	Children children(path, directories);
	const auto count = zip_entries_total(archive);
	if (count < 0 || count > (std::numeric_limits<int>::max)()) throw std::runtime_error("Cannot list extension ZIP entries");
	for (int i = 0; i < count; ++i) {
		if (zip_entry_openbyindex(archive, i) != 0) throw std::runtime_error("Cannot open extension ZIP entry");
		try {
			const char* name = zip_entry_name(archive);
			const int directory = zip_entry_isdir(archive);
			if (name == nullptr || directory < 0) throw std::runtime_error("Cannot inspect extension ZIP entry");
			children.add(name, directory != 0);
		}
		catch (...) {
			zip_entry_close(archive);
			throw;
		}
		if (zip_entry_close(archive) != 0) throw std::runtime_error("Cannot close extension ZIP entry");
	}
	return children.result();
}

}
