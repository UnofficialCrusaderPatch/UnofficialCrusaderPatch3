
local DAT_GamePausedLogical = 0x01fea054

local DAT_MatchTime = 0x01fe7da8

local CountDown = core.allocate(4)
core.writeInteger(CountDown, -1)

local code = {
  0x83, 0x3D, CountDown, 0x00,                                  -- CMP        dword ptr [CountDown],0x0
  0x74, 0x04,                                                   -- JE         pause
  0x7E, 0x13,                                                   -- JLE        end
  0xEB, 0x0A,                                                   -- JMP        decrement
                                                                -- pause:
  0xC7, 0x05, DAT_GamePausedLogical, 0x01, 0x00, 0x00, 0x00,    --  MOV        dword ptr [0x01fea054],0x1
                                                                -- decrement:
  0x83, 0x2D, CountDown, 0x01,                                  --  SUB        dword ptr [CountDown],0x1
                                                                -- end:
  0x83, 0x05, DAT_MatchTime, 0x01                               --  ADD        dword ptr [0x01fe7da8],0x1
}

-- detourLocation = createDetourWithReturn(0x0045ce58, #code+3+3, 7)
local detourLocation = core.insertCode(0x0045ce58, 7, code)

-- writeCode(detourLocation, code)

local onPauseAfter = function (command)
  local ticks = command:match("^/pauseAfter ([0-9]+)$")
  if ticks == nil then
    modules["commands"].displayChatText("invalid command: " .. command .. " usage: ", "/pauseAfter [0-Infinity]")
  else 
    core.writeInteger(CountDown, ticks)
    modules["commands"].displayChatText("pauseAfter: the game will pause after " .. ticks .. " ticks")
  end
end

modules["commands"].registerCommand("pauseAfter", onPauseAfter)