return {
    enable = function(self)
        self.skirmish = require("skirmish.lua")
        self.skirmish.initialized = false

        modules.ui.getMenus()[20] = self.skirmish
    end


}