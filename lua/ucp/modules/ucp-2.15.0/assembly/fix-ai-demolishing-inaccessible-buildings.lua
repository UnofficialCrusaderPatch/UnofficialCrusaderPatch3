
local writeCode = core.writeCode
local scanForAOB = core.scanForAOB


-- 0x004242C3
writeCode(scanForAOB("75 07 66 C7 06 03 00 EB 12 83 F8 02 75 07 66 C7 06 03 00 EB 06 66 83 3E 03 75 14 0F BF 56 20 0F"), {0xEB})