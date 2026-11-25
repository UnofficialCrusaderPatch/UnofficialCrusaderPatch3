
local fixes = {}

fixes.threading = require("fixes.threading")

fixes.gamedatapath = require("fixes.gamedatapath")

fixes.applyAll = function() 

  fixes.gamedatapath.setGameDataPathBasedOnCommandLine()

  fixes.threading.removeMusicThread()

end

return fixes