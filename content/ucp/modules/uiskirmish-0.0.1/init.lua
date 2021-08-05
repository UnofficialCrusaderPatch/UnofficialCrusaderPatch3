return {
    enable = function(self)
        self.skirmish = require("skirmish.lua")
        self.skirmish.initialized = false

        modules.ui.menus[20] = self.skirmish
    end


}