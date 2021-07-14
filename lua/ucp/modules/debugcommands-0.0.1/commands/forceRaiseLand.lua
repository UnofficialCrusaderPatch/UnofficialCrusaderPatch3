
local namespace = {}

local RaiseLandValue = nil

local onRaiseLand = function (registers)
  if RaiseLandValue ~= nil then
    local tile = core.readInteger(0x01997fb8) + core.readInteger(0x02337300+(4*3*core.readInteger(0x01997fbc)))
    local height = core.readByte(0x01d32c38 + tile)
    registers.EDX = RaiseLandValue - height
  end
  return registers
end

core.detourCode(onRaiseLand, 0x00481368, 0x7)

local onForceRaiseLand = function (command)
  local height = command:match("^/forceRaiseLand ([0-9]+)$")
  if height == nil then
    modules["commands"].displayChatText("invalid command: " .. command)
    modules.commands.displayChatText(" usage: ".. "/forceRaiseLand [0-Infinity]")
  else
    RaiseLandValue = height
    modules["commands"].displayChatText("forceRaiseLand: force raise land to " .. height)
  end

end

modules["commands"].registerCommand("forceRaiseLand", onForceRaiseLand)