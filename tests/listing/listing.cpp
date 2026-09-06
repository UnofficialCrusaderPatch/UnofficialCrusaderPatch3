#include "io/modules/ZipDirectoryListing.h"
#include <fstream>
#include <iostream>

namespace fs = std::filesystem;

void require(bool condition) {
	if (!condition) throw std::runtime_error("Listing regression failed");
}

template<class Function> void rejects(Function function) {
	bool rejected = false;
	try { function(); } catch (const std::exception&) { rejected = true; }
	require(rejected);
}

void makeZip(const fs::path& path, bool explicitDirectories) {
	zip_t* archive = zip_open(path.string().c_str(), 0, 'w');
	require(archive != nullptr);
	std::vector<std::string> names = {"definition.yml", "code/main.lua", "code/nested/data.bin",
		"code-other/outside.lua", "assets/file.zip", "empty/"};
	if (explicitDirectories) {
		names.insert(names.begin(), {"code/", "code/nested/", "assets/", "code-other/"});
		std::reverse(names.begin(), names.end());
	}
	for (const auto& name : names) {
		require(zip_entry_open(archive, name.c_str()) == 0);
		if (name.back() != '/') require(zip_entry_write(archive, "data", 4) == 0);
		require(zip_entry_close(archive) == 0);
	}
	zip_close(archive);
}

int main() {
	try {
		// This directory lives in CTest's isolated build directory, never a game install.
		const fs::path root = "listing-fixture";
		fs::create_directories(root / "code/nested");
		fs::create_directories(root / "code-other");
		fs::create_directories(root / "assets");
		fs::create_directories(root / "empty");
		for (const auto& name : {"definition.yml", "code/main.lua", "code/nested/data.bin",
			"code-other/outside.lua", "assets/file.zip"}) {
			std::ofstream(root / name) << "data";
		}
		makeZip("implicit.zip", false);
		makeZip("explicit.zip", true);
		int comparisons = 0;
		for (const auto& archivePath : {"implicit.zip", "explicit.zip"}) {
			zip_t* archive = zip_open(archivePath, 0, 'r');
			require(archive != nullptr);
			for (const auto& directory : {"", ".", "./", "code", "code/", "code\\nested\\",
				"code/nested", "code-other", "assets", "empty"}) {
				for (bool directories : {false, true}) {
					require(ExtensionListing::zip(archive, directory, directories) ==
						ExtensionListing::folder(root, directory, directories));
					++comparisons;
				}
			}
			require(ExtensionListing::zip(archive, "", true) ==
				std::vector<std::string>({"assets/", "code-other/", "code/", "empty/"}));
			require(ExtensionListing::zip(archive, "code", false) == std::vector<std::string>({"code/main.lua"}));
			require(ExtensionListing::zip(archive, "assets", false) == std::vector<std::string>({"assets/file.zip"}));
			require(ExtensionListing::zip(archive, "assets", true).empty());
			for (const auto& invalid : {"missing", "code/main.lua", "code-othe"}) {
				rejects([&] { ExtensionListing::zip(archive, invalid, false); });
				rejects([&] { ExtensionListing::folder(root, invalid, false); });
			}
			// Listing closes each ZIP entry; subsequent ordinary file access still works.
			require(zip_entry_open(archive, "code/main.lua") == 0);
			require(zip_entry_size(archive) == 4);
			require(zip_entry_close(archive) == 0);
			zip_close(archive);
		}
		for (const std::string invalid : {"../escape", "code/../escape", "/root", "C:/root", "\\\\server\\share"}) {
			rejects([&] { ExtensionListing::Children children(invalid, true); });
			rejects([&] { ExtensionListing::Children children("", true); children.add(invalid, false); });
		}
		ExtensionListing::Children deduplicated("", true);
		deduplicated.add("code/a.lua", false); deduplicated.add("code/b.lua", false);
		deduplicated.add("code/", true); deduplicated.add("code/deep/c.lua", false);
		require(deduplicated.result() == std::vector<std::string>({"code/"}));
		std::cout << comparisons << " real ZIP/folder comparisons passed, plus path and ZIP-read regressions\n";
		return 0;
	}
	catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
