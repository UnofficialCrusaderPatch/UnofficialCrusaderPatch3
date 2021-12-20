-- imports
local scanForAOB = core.scanForAOB
local readInteger = core.readInteger
local AssemblyLambda = core.AssemblyLambda
local insertCode = core.insertCode
local writeCode = core.writeCode

-- AOBs
local base = scanForAOB("B8 E8 03 00 00 99 F7 FE 3B FB") -- 0x00487B42

local DAT_MillisecLoopMainFunc = readInteger(base + 0x13) -- 0x165271C
local DAT_TickRate = readInteger(scanForAOB("8B 0D ? ? ? ? 8B 15 ? ? ? ? 89 0D ? ? ? ? 52") + 2) -- 0x1FE7DC0
local DAT_MillisecCarry = readInteger(base + 0x19) -- 0xDF4228

local accuracyValue1 = base + 1 -- 0x00487B43
local accuracyValue2 = base - 0xE -- 0x00487B34
local accuracyFix = base + 0x11 -- 0x00487B53
local speedCapEntry = base + 0x46 -- 0x00487B88
local speedCapExit = base + 0xD3 -- 0x00487C15


local insertAssembly = function(address, patchSize, script, valueMapping, returnTo, original)
    local assemblyLambda = AssemblyLambda(script, valueMapping)
    insertCode(address, patchSize, {assemblyLambda}, returnTo, original)
end

-- exports
local exports = {}

exports.enable = function(self,config)

    -- enable increased accuracy
    writeCode(accuracyValue1,{0x40, 0x42, 0x0F, 0x00}) -- F4240h = 3E8h * 3E8h = 1000 * 1000
    writeCode(accuracyValue2,{0xC0, 0xBD, 0xF0, 0xFF}) -- FFF0BDC0h = - 1000 * 1000

    local script = [[
        imul edx,0x3E8
    ]]
    insertAssembly(accuracyFix, 6, script, {}, nil, "before")

    -- enable dynamic game speed cap
    local script = [[
        mov eax,cap
        mul dword [ticksLastLoop]
        cdq
        mov esi,dword [timeLastLoop]
        add esi,1
        div esi
        mov edx,eax
        imul edx,ecx
        sub edx,ecx
        cmp edi,edx

        jle calculateNumberOfGameTicks

        pop edi
        pop esi
        mov dword [carry],0
        add eax,1
        pop ebp
        pop ebx
        retn 4
    ]]
    
    local varDict = {
        cap                         = config.capMillisecForOneFrame,
        ticksLastLoop               = DAT_TickRate,
        timeLastLoop                = DAT_MillisecLoopMainFunc,
        calculateNumberOfGameTicks  = speedCapExit,
        carry                       = DAT_MillisecCarry,
    }
    insertAssembly(speedCapEntry, 0, script, varDict) -- does not return

end

exports.disable = function()
    -- disable increased accuracy
    writeCode(accuracyValue1,{0xE8, 0x03, 0x00, 0x00}) -- 0x3E8
    writeCode(accuracyValue2,{0x18, 0xFC, 0xFF, 0xFF}) -- 0xFFFFFC18
    local oriCode = {0x8B, 0x15, 0x1C, 0x27, 0x65, 0x01}
    writeCode(accuracyFix, oriCode)

    -- disable dynamic game speed cap
    local oriCode = {0x8B, 0x1D, 0xC8, 0x7D, 0xFE, 0x01}
    writeCode(speedCapEntry, oriCode)

end

return exports