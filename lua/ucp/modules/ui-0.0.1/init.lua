local exports = {}

local menus = {}

local currentMenuID = nil

exports.getCurrentMenuID = function()
  return currentMenuID
end

exports.setCurrentMenuID = function(value)
  currentMenuID = value
end

exports.switchToMenu_hook = function (this, menuID, param_2)
  --print("switchToMenu(", this, ", ", menuID, ", ", param_2, ")")
 
  
  if menus[menuID] then
    if not menus[menuID].initialized then
      menus[menuID].onInit()
    else
      menus[menuID].onShow()
    end
  end
  
  currentMenuID = menuID
  
  return exports.switchToMenu(this, menuID, param_2)
end

exports.enable = function(self)
    exports.switchToMenu = core.hookCode(exports.switchToMenu_hook, data.common.SCANS["SWITCH_TO_MENU_FN"], 3, 1, 5)
    -- switchToMenu(0x1fe7d10, menuID, param_2)
    --exposeCode("switchToMenu", 4633408, 3, 1)
  end

exports.disable = function(self)
  
  end

exports.menus = menus


return exports