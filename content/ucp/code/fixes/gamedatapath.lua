local namespace = {}

local stringPreAddressAOB = "B8 ? ? ? ? C7 44 24 20 0F 00 00 00"
local configPathInUsePreAddressAOB = "80 ? ? ? ? ? ? 8B F9 0F 84 8F 00 00 00"

namespace.setGameDataPathBasedOnCommandLine = function()
  local ugdp = processedArg['ucp-game-data-path']
  if ugdp == nil or ugdp == '' then return end

  if type(ugdp) ~= "string" then log(WARNING, string.format("game data path is not a valid string: %s", tostring(ugdp))) end

  if ugdp:len() >= 499 then log(WARNING, string.format("game data path could not be set because it is too long: %s / 499", ugdp:len())) end

  local stringPreAddress = core.scanForAOB(stringPreAddressAOB)
  if stringPreAddress == nil then log(WARNING, string.format("game data path could not be set because AOB could not be found: %s", stringPreAddressAOB)) end

  local configPathInUsePreAddress = core.scanForAOB(configPathInUsePreAddressAOB)
  if configPathInUsePreAddress == nil then log(WARNING, string.format("game data path could not be set because AOB could not be found: %s", configPathInUsePreAddressAOB)) end

  local stringAddress = core.readInteger(stringPreAddress + 1)
  local configPathInUseAddress = core.readInteger(configPathInUsePreAddress + 2)

  core.writeString(stringAddress, ugdp .. '\0')
  core.writeByte(configPathInUseAddress, 0x01)

  log(INFO, string.format("game data path is now: %s", ugdp))
end

return namespace