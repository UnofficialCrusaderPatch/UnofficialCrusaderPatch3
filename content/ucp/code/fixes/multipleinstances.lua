-- --ucp-allow-multiple-instances lets this game start while another game is running.
-- WinMain creates the mutex "Global\FireflyStrongholdCrusadersExtreme" and exits if it already
-- exists. The "already exists" branch is changed to continue like the "created" branch. The
-- handle stays open, so games started without the flag still find the mutex.
local namespace = {}

local FLAG = "ucp-allow-multiple-instances"

-- push <name>; push ebx; push ebx; call [CreateMutexA]; mov ebp, eax
-- cmp ebp, ebx; je <continue>               (CreateMutexA failed)
-- call [GetLastError]; cmp eax, 0xB7; jne <continue>   (ERROR_ALREADY_EXISTS)
-- push ebp; call [CloseHandle]              (start of the "already running" exit)
local CHECK_AOB = "68 ? ? ? ? 53 53 FF 15 ? ? ? ? 8B E8 3B EB 74 ? FF 15 ? ? ? ? 3D B7 00 00 00 75 ? 55 FF 15"
local MUTEX_NAME = "Global\\FireflyStrongholdCrusadersExtreme"
local OFFSET_NAME_POINTER = 1
local OFFSET_FAILED_BRANCH = 17 -- 74 rel8
local OFFSET_EXISTS_BRANCH = 30 -- 75 rel8
local JMP_SHORT = 0xEB

---@return boolean true when the flag was passed with a true value
function namespace.isRequested()
  return processedArg[FLAG] == true
end

local function shortBranchTarget(address)
  local displacement = core.readByte(address + 1) & 0xFF
  if displacement >= 0x80 then displacement = displacement - 0x100 end
  return address + 2 + displacement
end

---Locate and verify the single-instance check.
---@return number|nil address of the "mutex already existed" branch, or nil
---@return string|nil reason when the check was not found or did not verify
function namespace.locate()
  local found, match = pcall(core.AOBScan, CHECK_AOB)
  if not found then
    return nil, "the check was not found"
  end

  local name = core.readString(core.readInteger(match + OFFSET_NAME_POINTER))
  if name ~= MUTEX_NAME then
    return nil, string.format("the check uses an unexpected mutex name: %s", tostring(name))
  end

  local failedBranch = match + OFFSET_FAILED_BRANCH
  local existsBranch = match + OFFSET_EXISTS_BRANCH
  if shortBranchTarget(failedBranch) ~= shortBranchTarget(existsBranch) then
    return nil, "the check's branches do not continue at the same place"
  end

  return existsBranch, nil
end

function namespace.allowWhenRequested()
  if not namespace.isRequested() then return end

  local existsBranch, reason = namespace.locate()
  if existsBranch == nil then
    log(WARNING, string.format(
      "[fixes/multipleinstances]: --%s was passed, but %s. The game keeps its single-instance check.",
      FLAG, reason))
    return
  end

  core.writeCode(existsBranch, { JMP_SHORT }, false)
  log(INFO, "[fixes/multipleinstances]: this game may start while another game is running")
end

return namespace
