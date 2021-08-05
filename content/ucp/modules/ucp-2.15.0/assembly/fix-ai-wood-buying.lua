local writeCode = core.writeCode
local scanForAOB = core.scanForAOB


-- 0x00457DF4
local hook1Address = scanForAOB("3B 9E ? ? ? ? 7E 58 8B 44 24 10 5F 89 9E ? ? ? ? 5E 5D 5B 83 C4 18 C2 0C 00")
local offset = hook1Address + 2

-- allocate 12 bytes and hook with 6 bytes at hook1Address
local newCodeAddress = assemblyHook(hook1Address, 12, 6)

writeCode(newCodeAddress, {
    0x81, 0xC3, 0x02, 0x00, 0x00, 0x00, -- add ebx,02
    0x3B, 0x9E, offset -- cmp ebx, DWORD PTR[esi+offset]
})