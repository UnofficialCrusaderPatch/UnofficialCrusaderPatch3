
local fixes = {}

fixes.threading = require("fixes.threading")

fixes.gamedatapath = require("fixes.gamedatapath")

fixes.multipleinstances = require("fixes.multipleinstances")

fixes.applyAll = function() 

  fixes.gamedatapath.setGameDataPathBasedOnCommandLine()

  fixes.multipleinstances.allowWhenRequested()

  fixes.threading.removeMusicThread()

end

return fixes