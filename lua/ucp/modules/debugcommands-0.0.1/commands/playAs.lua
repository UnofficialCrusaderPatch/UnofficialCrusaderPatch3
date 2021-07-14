
local onPlayAs = function (command)
  local playerID = command:match("^/playAs ([0-9])$")
  if playerID == nil then
    modules["commands"].displayChatText("invalid command: " .. command .. " usage: ", "/playAs [playerID]")
  else 
    core.writeInteger(0x01a275dc, playerID)
    modules["commands"].displayChatText("playing As: player " .. playerID)
  end
end

modules["commands"].registerCommand("playAs", onPlayAs)