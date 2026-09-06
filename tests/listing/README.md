# Mounted extension directory listings

`ucp.internal.io.files()` and `directories()` must return usable virtual paths
for both folder and ZIP extensions. For example, listing
`ucp/modules/example-1.0.0/code/` returns
`ucp/modules/example-1.0.0/code/main.lua` and/or
`ucp/modules/example-1.0.0/code/nested/`, as appropriate. Root paths work with
or without a trailing slash. Returned directories end in `/`.

The old Lua bridge supplied a full virtual path to ZIP handlers that compared it
with archive-relative entry names. Those handlers also required explicit folder
entries and used a reversed relative-path comparison. This could give empty or
incomplete results for a valid extension, preventing reliable traversal for
replay compatibility checks and other consumers.

All extension handles now take and return extension-relative paths. Both current
and deprecated Lua APIs add the virtual prefix after resolving the extension.
Folder listing uses the handle's actual root, including a relocated UCP directory.
Shared ZIP traversal derives immediate folders from nested entries, deduplicates
them and sorts results. A ZIP file inside an extension is a file, not another
mounted extension. Missing subdirectories and invalid paths raise errors rather
than looking like a verified empty directory. This change does not compute replay
fingerprints or alter extension mounting/security decisions.

Run the standalone regression suite with:

```sh
cmake -S tests/listing -B build-listing
cmake --build build-listing --config Release
ctest --test-dir build-listing -C Release --output-on-failure
```

The suite compiles the production listing helpers against pinned upstream zip
0.2.0, creates real ZIP archives with and without explicit directories, and
compares 40 listings with real filesystem folders. It also checks direct-child
boundaries, stable ordering, duplicate parents, empty folders, ordinary nested
ZIP files, missing/file paths, invalid paths, and subsequent ZIP reads. CI runs
on Windows and Linux; Windows includes the same Windows headers before the
helpers as the DLL does.

These standalone tests do not build the complete UCP DLL or execute its Lua
bridge in the game. A full backend build and an in-game traversal smoke test
remain required before deploying this runtime change. The recorder must not
treat an old backend's empty ZIP listing as proof of matching extension contents.
