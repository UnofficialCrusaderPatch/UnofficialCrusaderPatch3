import shutil
import pathlib
import subprocess

subprocess.run(["msbuild",
				  "-p:Configuration=Release",
				  "UCP3.sln"]).check_returncode()

if pathlib.Path("ucp-package").is_dir():
	shutil.rmtree(pathlib.Path("ucp-package"))
	
pathlib.Path("ucp-package").mkdir()
	
src = pathlib.Path("lua") / "ucp"
dst = pathlib.Path("ucp-package") / "ucp"
dst.mkdir()

src_modules = src / "modules"
dst_modules = dst / "modules"
dst_modules.mkdir()

src_binpath = pathlib.Path("Release")
dst_binpath = pathlib.Path("ucp-package")

# Copy dll files
for dll in src_binpath.glob("*.dll"):
	print(dll)
	shutil.copy(dll, dst_binpath / dll.relative_to(src_binpath))
	
# Rename dll.dll to binkw32_ucp.dll for the install script
(dst_binpath / "dll.dll").rename("binkw32_ucp.dll")

# Copy install script
shutil.copy("installer/rename-dlls.bat", "ucp-package/install-ucp.bat")

# Copy all files, except modules
for f in src.glob("*"):
	print(f)
	if f.is_file():
		shutil.copy(f, dst / f.relative_to(src))
	elif f.is_dir():
		if f == src_modules:
			continue
		shutil.copytree(f, dst / f.relative_to(src))
		
for m in src_modules.glob("*"):
	print(m)
	if (m / "ucp-module").is_dir():
		shutil.copytree(m / "ucp-module", dst / m.relative_to(src))
	else:
		shutil.copytree(m, dst / m.relative_to(src))
		
#all_files_except_modules_directory = [f for f in src.rglob("*") if not f.parent.startswith(str(src / "modules"))]

# except the files in modules if there is a ucp-module directory ucp/modules/example-module-0.0.1/ucp-module
# if so, only copy the contents of ucp-module

