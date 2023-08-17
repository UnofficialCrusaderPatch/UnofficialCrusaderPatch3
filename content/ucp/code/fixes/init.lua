
local fixes = {}

fixes.threading = require("fixes.threading")

fixes.applyAll = function() 

  fixes.threading.removeMusicThread()

end

return fixes