-- imports
local AssemblyLambda = core.AssemblyLambda
local insertCode = core.insertCode
local writeCode = core.writeCode

-- AOBs
local DAT_MillisecLoopMainFunc = 0x165271C -- 0x165271C
local DAT_TickRate = 0x1FE7DC0 -- 0x1FE7DC0
local DAT_MillisecCarry = 0xDF4228 -- 0xDF4228

local speedCapEntry = 0x00487B88 -- 00487B88
local speedCapExit = 0x00487C15 -- 00487C15
local accuracyFix = 0x00487B53 -- 0x00487B53


local insertAssembly = function(address, patchSize, script, valueMapping, returnTo, original)
    local assemblyLambda = AssemblyLambda(script, valueMapping)
    insertCode(address, patchSize, {assemblyLambda}, returnTo, original)
end

-- exports
local exports = {}

exports.enable = function(self,config)

    -- enable increased accuracy
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
    local oriCode = {0x8B, 0x15, 0x1C, 0x27, 0x65, 0x01}
    writeCode(accuracyFix, oriCode)

    -- disable dynamic game speed cap
    local oriCode = {0x8B, 0x1D, 0xC8, 0x7D, 0xFE, 0x01}
    writeCode(speedCapEntry, oriCode)

end

return exports