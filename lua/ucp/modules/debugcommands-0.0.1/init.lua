

local commandFiles = {
  "commands/gamemode.lua",
  "commands/inspectState.lua",
  "commands/pauseAfter.lua",
  "commands/forceRaiseLand.lua",
  "commands/playAs.lua",
  "commands/debugDialog.lua"
}


return {
  enable = function(self)
    for k, v in pairs(commandFiles) do
      print("loading: " .. v)
      require(v)
    end
  end,
  
  disable = function(self)
  
  end,
}

