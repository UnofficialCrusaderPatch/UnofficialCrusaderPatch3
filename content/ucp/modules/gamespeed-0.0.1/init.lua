-- imports
local AssemblyLambda = core.AssemblyLambda
local insertCode = core.insertCode
local writeCode = core.writeCode

-- AOBs
local DAT_MillisecLoopMainFunc = 0x165271C -- 0x165271C
local DAT_TickRate = 0x1FE7DC0 -- 0x1FE7DC0
local DAT_MillisecCarry = 0xDF4228 -- 0xDF4228

local accuracyValue1 = 0x00487B43 -- 0x00487B43
local accuracyValue2 = accuracyValue1 - 0xF -- 0x00487B34
local accuracyFix = accuracyValue1 + 0x10 -- 0x00487B53
local speedCapEntry = accuracyValue1 + 0x45 -- 00487B88
local speedCapExit = accuracyValue1 + 0xD2 -- 00487C15


local insertAssembly = function(address, patchSize, script, valueMapping, returnTo, original)
    local assemblyLambda = AssemblyLambda(script, valueMapping)
    insertCode(address, patchSize, {assemblyLambda}, returnTo, original)
end

-- exports
local exports = {}

exports.enable = function(self,config)

    -- enable increased accuracy
    writeCode(accuracyValue1,{0x40, 0x42, 0x0F, 0x00}) -- F4240h = 3E8h * 3E8h
    writeCode(accuracyValue2,{0xC0, 0xBD, 0xF0, 0xFF}) -- FFF0BDC0

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