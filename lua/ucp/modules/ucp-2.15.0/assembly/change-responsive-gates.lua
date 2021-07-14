
local writeCode = core.writeCode
local scanForAOB = core.scanForAOB

-- Gates closing distance to enemy = 200
-- 0x422ACC + 2
writeCode(scanForAOB("C8 00 00 00 7C 61 8B 4C 24 28 8B 44 24 2C 83 C6 01 83 C0 02 83 C5 04 3B F1 89 44 24 2C 7C 83 66"), {0x8C, 0x00, 0x00, 0x00})

-- Gates closing time after enemy leaves = 1200
-- 0x422B35 + 7 (ushort)
writeCode(scanForAOB("B0 04 80 BF ? ? ? ? 00 75 CE 6A 00 C6 87 ? ? ? ? 0A 66 C7 87 ? ? ? ? 0A 00 6A 00 EB"), {0x64, 0x00})