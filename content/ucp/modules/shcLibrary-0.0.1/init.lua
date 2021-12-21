-- Stronghold Crusader library
-- comment addresses are preferably v1.41 otherwise version must be annotated
-- AOBs must work in all game versions defined in definition.yml

local AOBScan = core.AOBScan
local readInteger = core.readInteger

local exports = {}
local library = {}

exports.enable = function()

    -- SEC
    library.SEC_CurrentPlayerSlotID = readInteger(core.scanForAOB("8B 04 BD ? ? ? ? 8B 15 ? ? ? ? 83 C9 FF") + 9) -- 0x1a275dc
    library.SEC_Units = readInteger(core.scanForAOB("83 EC 14 53 8B 5C 24 20 69 DB ? ? ? ?") + 0x4e) - 0x8c -- 0x138854C

    -- DATA
    library.DAT_UnitProcessorClass_UnitCountPlusOne = readInteger(core.scanForAOB("B9 ? ? ? ? E8 ? ? ? ? 69 F6 ? ? ? ? 0F BF B6 ? ? ? ?") + 1) -- 0x1387f38

end

exports.disable = function() end

exports.getLibrary = function() return library end

return exports