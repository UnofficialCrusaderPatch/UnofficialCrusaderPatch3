
local onGameModeCommand = function (command)
  local mode = command:match("^/gamemode ([0-9]+)$")
  if mode then
    core.writeInteger(0x01fe7d78, mode + 0)
  else
    print("invalid command: ", command)
  end
end

modules["commands"].registerCommand("gamemode", onGameModeCommand)