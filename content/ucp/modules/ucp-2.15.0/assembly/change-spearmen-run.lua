
local writeCode = core.writeCode
local scanForAOB = core.scanForAOB

-- 0x0055E07E
writeCode(scanForAOB("74 13 C7 86 ? ? ? ?  81 00 00 00 66 89 86 ? ? ? ? EB 0D 89 86 ? ? ? ? 66 89 BE"), {0x90, 0x90}) -- remove je