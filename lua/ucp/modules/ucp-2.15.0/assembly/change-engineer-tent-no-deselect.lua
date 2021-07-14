
local writeCode = core.writeCode
local scanForAOB = core.scanForAOB

-- 0x0044612B
writeCode(scanForAOB("89 2D ? ? ? ? 5D 5B 83 C4 08 C3 57 55 B9 ? ? ? ? C7 05 ? ? ? ? 02 00 00 00 E8"), {0x90, 0x90, 0x90, 0x90, 0x90, 0x90})