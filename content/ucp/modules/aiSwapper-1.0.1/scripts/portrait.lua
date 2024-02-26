local util = require("scripts.util")

local gmModule = modules.gmResourceModifier


--[[ IDs and Constants ]]--

local DATA_PATH_NORMAL_PORTRAIT = "portrait.png"
local DATA_PATH_SMALL_PORTRAIT = "portrait_small.png"

local GM_DATA = {
  GM_INDEX               = 46,
  FIRST_ICON_INDEX       = 522,
  FIRST_SMALL_ICON_INDEX = 700,
}

--[[ Module variables ]]--

local resourceIds = {}   -- contains table of tables with the structure aiIndex = {bigPicRes, smallPicRes}


--[[ Functions ]]--

local function freePortraitResource(index)
  if resourceIds[index] ~= nil then
    local oldResource = resourceIds[index]
    if oldResource.normal > -1 then
      gmModule:FreeGm1Resource(oldResource.normal)
    end
    if oldResource.small > -1 then
      gmModule:FreeGm1Resource(oldResource.small)
    end
    resourceIds[index] = nil -- removing resource id to prevent issues
  end
end

local function resetPortrait(index)
  gmModule:SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + index, -1, -1)
  gmModule:SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + index, -1, -1)
  freePortraitResource(index)
end

local function loadAndSetPortrait(indexToReplace, pathroot, aiName)
  local normalPortraitPath = util.getAiDataPath(pathroot, DATA_PATH_NORMAL_PORTRAIT)
  local smallPortraitPath = util.getAiDataPath(pathroot, DATA_PATH_SMALL_PORTRAIT)

  local portraitResourceIds = {
    normal = util.doesFileExist(normalPortraitPath) and gmModule:LoadResourceFromImage(normalPortraitPath) or -1,
    small  = util.doesFileExist(smallPortraitPath) and gmModule:LoadResourceFromImage(smallPortraitPath) or -1,
  }

  if portraitResourceIds.normal < 0 then
    log(WARNING, aiName .. " has no portrait.")
  else
    gmModule:SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_ICON_INDEX + indexToReplace, portraitResourceIds.normal, 0)
  end

  if portraitResourceIds.small < 0 then
    log(WARNING, aiName .. " has no small portrait.")
  else
    gmModule:SetGm(GM_DATA.GM_INDEX, GM_DATA.FIRST_SMALL_ICON_INDEX + indexToReplace, portraitResourceIds.small, 0)
  end

  freePortraitResource(indexToReplace)
  resourceIds[indexToReplace] = portraitResourceIds
end


return {
  resetPortrait      = resetPortrait,
  loadAndSetPortrait = loadAndSetPortrait,
}
