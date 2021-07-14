local namespace = {
  enable = function(self) end,
  disable = function(self) end,

}

namespace.activateModalDialog = core.exposeCode(0x004a9ed0, 3, 1)

local function onDebugDialogCommand(command)
  local dialogID = command:match("^/debugDialog ([0-9]+)$")
  if dialogID == nil then
    modules["commands"].displayChatText("invalid command: " .. command .. " usage: ", "/debugDialog [dialogID]")
  else 
    namespace.activateModalDialog(0x01fe7c90, dialogID + 0, 0)
    modules["commands"].displayChatText("displaying: " .. dialogID)
  end

end

modules["commands"].registerCommand("debugDialog", onDebugDialogCommand)

return namespace