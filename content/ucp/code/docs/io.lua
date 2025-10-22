
---@module "ucpiolib"
local ucpiolib = {}

--- Same signature as vanilla lua but cannot escape game directory
---@param filename string
---@param mode? iolib.OpenMode
---@return file?
---@return string? err
function ucpiolib.open(filename, mode) end

--- Same signature but can escape game directory, use with caution
ucpiolib._open = ucpiolib.open

---@param path string
---@param parents boolean
---@return boolean? status
---@return string? err
function ucpiolib.mkdir(path, parents) end

---@param path string
---@param recurse boolean
---@return boolean? status
---@return string? err
function ucpiolib.remove(path, recurse) end

