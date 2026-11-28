---@class UserDataInterface
---@field version string
local UserDataInterface = {}

---@return file? handle
---@return string? err
function UserDataInterface:open(path, mode) end

---@return boolean? status
---@return string? err
function UserDataInterface:mkdir(path, parents) end

---@return boolean? status
---@return string? err
function UserDataInterface:remove(path, recurse) end

---Rename a file or folder, replacing an existing target file. The folders holding both paths must resolve inside the extension's folder.
---@return boolean? status
---@return string? err
function UserDataInterface:rename(from, to) end

---Set the (new) version of this user data
---@param version string
function UserDataInterface:setVersion(version) end

---@class PreUserDataInterface
---@field interface fun():UserDataInterface

---@type PreUserDataInterface
 ---@diagnostic disable-next-line: return-type-mismatch
userdata = {interface = function() return {} end,}