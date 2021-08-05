local namespace = {}

namespace.SCANS = {
    ["SFX_ADDRESS_ARRAY"] = core.readInteger(core.scanForAOB("83 C6 3A 56 B9 ? ? ? ? E8 ? ? ? ? 5E 5F C2 08 00") + 5),
    ["PLAY_SFX"] = (function()
        local temp0 = core.scanForAOB("83 C6 3A 56 B9 ? ? ? ? E8 ? ? ? ? 5E 5F C2 08 00") + 10
        return temp0 + core.readInteger(temp0) + 4
    end)(),
    ["PLAY_SFX_AT_LOCATION"] = (function()
        local temp0 = core.scanForAOB("6A 40 50 51 B9 ? ? ? ? 66 89 ? ? ? ? 00 E8 ? ? ? ? 5F 5E 5D 5B") + 17
        return temp0 + core.readInteger(temp0) + 4
    end)(),
}

namespace.SOUND_EFFECT = require('sounds')

namespace.playSFX_internal = core.exposeCode(namespace.SCANS["PLAY_SFX"], 2, 1)
namespace.playSFXAtLocation_internal = core.exposeCode(namespace.SCANS["PLAY_SFX_AT_LOCATION"], 4, 1)

-- Plays an SFX by id.
function namespace.playSFX(soundID)
    namespace.playSFX_internal(namespace.SCANS["SFX_ADDRESS_ARRAY"], soundID)
end

-- Plays an SFX by id.
function namespace.playSFXAtLocation(x, y, soundID)
    namespace.playSFXAtLocation_internal(namespace.SCANS["SFX_ADDRESS_ARRAY"], x, y, soundID)
end

return namespace