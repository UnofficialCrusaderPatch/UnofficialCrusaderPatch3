
local fixes = {}

fixes.threading = require("fixes.threading")

fixes.gamedatapath = require("fixes.gamedatapath")
fixes.concurrentLaunch = require("fixes.concurrentlaunch")

fixes.applyAll = function() 

  fixes.gamedatapath.setGameDataPathBasedOnCommandLine()

  fixes.concurrentLaunch.allow()
  fixes.threading.removeMusicThread()

end

return fixes