
local assemblyChanges = {
  "assembly/change-spearmen-run.lua",
  "assembly/change-responsive-gates.lua",
  "assembly/change-moat-visibility.lua",
  "assembly/change-free-trader-post.lua",
  "assembly/change-engineer-tent-no-deselect.lua",
  "assembly/change-increase-path-update-tick-rate.lua",
  "assembly/change-healer.lua",
}

local assemblyFixes = {
  "assembly/fix-ai-demolishing-inaccessible-buildings.lua",
  "assembly/fix-ai-ox-tether-spam.lua",
  "assembly/fix-ai-tower-engine-replenishment.lua",
  "assembly/fix-fletcher-bug.lua",
  "assembly/fix-baker-disappear-bug.lua",
  -- Not working yet
  -- "assembly/fix-ai-wood-buying.lua",
  "assembly/fix-ladderclimb.lua",
}

local changesV2 = {
  "assembly/change-fire-cooldown.lua",
  "assembly/o_extreme.lua",
  "assembly/o-gamespeed.lua",
  "assembly/fix-fireballista.lua",
  "assembly/change-ai-wall-defenses.lua",
  "assembly/change-ai-buywood.lua",
  
}

--writeCode(0x0053D3D9, {0xE9, table.unpack({0x11, 0x22, 0x33, 0x44})})

local cfg = require('cfg-converter.lua')
local config = cfg.getCFG('ucp.cfg')

return {

  enable = function(self, module_options, global_options)

    print("loading assembly changes")

    for index, file in ipairs(assemblyChanges) do
      if DEBUG then
        print("loading "..file)
      end
      require(file)
    end

    print("loading assembly fixes")

    for index, file in ipairs(assemblyFixes) do
      if DEBUG then
        print("loading "..file)
      end
      require(file)
    end
    
    for index, file in ipairs(changesV2) do
      if DEBUG then
        print("loading "..file)
      end
      local change = require(file)
      change:init(config)
      change:enable(config)
    end

    return true
  end,

  disable = function(self, module_options, global_options)
    return false, "not implemented"
  end,

}



