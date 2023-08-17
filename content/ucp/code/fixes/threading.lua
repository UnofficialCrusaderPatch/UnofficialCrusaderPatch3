

local namespace = {}

namespace.removeMusicThread = function()
  --[[ Fix issue with non-deterministic RNG ]]

  -- Clear out the original call to timeSetEvent which created a thread non-safety
  core.writeCode(core.AOBScan("6A 01 57 68 ? ? ? ?"), {0x90, 0x90, 0x90, 0x90, 
                                                       0x90, 0x90, 0x90, 0x90,
                                                       0x90, 0x90, 0x90, 0x90,
                                                       0x90, 0x90, 0x90, 0x90,
                                                       0x90,})

  -- Find the callback function 'SndSystemTimeCallbackAddress' that was originally set in timeSetEvent and called by winmm.dll
  local SndSystemTimeCallbackAddress = core.AOBScan("83 ? ? ? ? ? ? 75 65 83 ? ? ? ? ? ?")

  -- Create code to call this callback function from a custom location
  local SndSystemTimeCallback_injectionCode = { 
    0x51, -- push ecx
    
    0x6a, 0x00, 
    0x6a, 0x00, 
    0x6a, 0x00, 
    0x6a, 0x00, 
    0x6a, 0x00, -- call has 5 arguments it does not use, so I push 0's
    
    core.callTo(SndSystemTimeCallbackAddress),
    0x59, -- pop ecx
  }

  -- Injection location 1: right before sounds are updated
  local soundRelatedMethod1Address = core.AOBScan("83 ? ? ? ? ? ? 53 8B D9 74 05")
  local soundRelatedMethod1HookSize = 7

  core.insertCode(soundRelatedMethod1Address, soundRelatedMethod1HookSize, SndSystemTimeCallback_injectionCode, nil, "after")

  -- Injection location 2: the reason the thread exists is likely because the start up menu needs some music.
  -- Therefore we also call the function at "drawLoadingBar". Note that calling SndSystemTimeCallbackAddress
  -- is safe, it just checks if some audio needs to be buffered, so we can't call it too often (only too little, not hearing music because the buffer is empty)
  local drawLoadingBarAddress = core.AOBScan("FF ? ? ? ? ? 8B C8 2B ? ? ? ? ? 83 F9 1E 7E 7F")
  local drawLoadingBarHookSize = 6

  core.insertCode(drawLoadingBarAddress, drawLoadingBarHookSize, SndSystemTimeCallback_injectionCode, nil, "after")
   
end
 
return namespace