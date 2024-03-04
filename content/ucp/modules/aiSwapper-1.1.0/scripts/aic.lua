local util = require("scripts.util")

local aicModule = modules.aicloader


--[[ IDs and Constants ]]--

local DATA_PATH_CHARACTER = "character.json"


--[[ Functions ]]--

local function resetAIC(indexToReset)
  aicModule:resetAIC(indexToReset + 1) -- uses ai ids
end

local function setAIC(indexToReplace, pathroot, aiName, loadedCharacterJson)
  if loadedCharacterJson == nil then
    local loadedJson, err = util.loadDataFromJSON(util.getAiDataPath(pathroot, DATA_PATH_CHARACTER))
    if not loadedJson then
      log(WARNING, string.format("Could not load character file of AI '%s': %s", aiName, err))
      return
    end
    loadedCharacterJson = loadedJson
  end

  if not loadedCharacterJson.aic then
    log(WARNING, string.format("Could not load AIC data of AI '%s': No aic data found.", aiName))
    return
  end

  aicModule:overwriteAIC(indexToReplace + 1, loadedCharacterJson.aic) -- uses ai ids
  return loadedCharacterJson
end


return {
  resetAIC = resetAIC,
  setAIC   = setAIC,
}
