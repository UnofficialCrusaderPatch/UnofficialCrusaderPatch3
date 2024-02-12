local HOOKS = {}
HOOKS.afterInit = {}

local function registerHookCallback(hook, f)
    if hook == "afterInit" then
        table.insert(HOOKS.afterInit, f)
    end
end

---In what environment is f executed?
local function fireCallbacksForHook(hook)
    for k, f in pairs(HOOKS[hook]) do
        f()
    end
end

---This is right before the windows messages loop
local afterInit = core.scanForAOB("e8 ? ? ? ? 39 1d ? ? ? ? 89 2d ? ? ? ? 89 1d ? ? ? ? 0f 85 ? ? ? ?")

local function onAfterInit(registers)
    log(DEBUG, "[hooks]: firing afterInit callbacks")

    local status, message = xpcall(fireCallbacksForHook, debug.traceback, "afterInit")
    if not status then
        log(WARNING, message)
    end

    return registers
end

core.detourCode(onAfterInit, afterInit + 5, 6)

return {
    registerHookCallback = registerHookCallback
}
