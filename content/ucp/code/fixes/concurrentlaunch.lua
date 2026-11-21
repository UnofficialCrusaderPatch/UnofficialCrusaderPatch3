local concurrentLaunch = {}

-- In the native startup path, a failed mutex creation and a newly created mutex
-- both continue at the same instruction. A duplicate mutex is the only case
-- that falls through to the dialog and early exit.
local mutexCheck = "68 ? ? ? ? 53 53 FF 15 ? ? ? ? 8B E8 3B EB 74 ? FF 15 ? ? ? ? 3D B7 00 00 00 75 ? 55 FF 15 ? ? ? ?"
local mutexName = "Global\\FireflyStrongholdCrusadersExtreme"

function concurrentLaunch.allow()
  if not processedArg["ucp-allow-multiple-instances"] then return end

  local match = core.scanForAOB(mutexCheck)
  local duplicate = match and match ~= 0 and core.scanForAOB(mutexCheck, match + 1)
  if not match or match == 0 or (duplicate and duplicate ~= 0) then
    log(WARNING, "Multiple instances: the native startup check could not be located uniquely.")
    return
  end

  local failedCreationBranch = match + 17
  local alreadyRunningBranch = match + 30
  local function target(branch)
    local displacement = core.readByte(branch + 1) & 0xFF
    if displacement >= 128 then displacement = displacement - 256 end
    return branch + 2 + displacement
  end
  local nameAddress = core.readInteger(match + 1)
  if target(failedCreationBranch) ~= target(alreadyRunningBranch)
      or string.char(table.unpack(core.readBytes(nameAddress, #mutexName + 1))) ~= mutexName .. "\0" then
    log(WARNING, "Multiple instances: the native startup check has an unexpected layout.")
    return
  end

  -- Unconditionally follow the same continuation. Keep the native mutex handle.
  core.writeCode(alreadyRunningBranch, { 0xEB })
end

return concurrentLaunch
