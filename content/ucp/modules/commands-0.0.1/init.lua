local exports

local COMMAND_REGISTRY = {}

local convertStringToBytes = function(s)
    return table.pack(string.byte(s, 1, -1))
end

local chatDisplayParam1 = 0
local chatDisplayParam2 = 0

local startsWith = function(s, start)
    return string.sub(s, 1, string.len(start)) == start
end

local registerCommand = function(commandName, commandCallback)
    COMMAND_REGISTRY[commandName] = commandCallback
end

local displayChatText = function(text)
    local b = convertStringToBytes(text)
    table.insert(b, 0)
    core.writeBytes(0x01a1f240, b) -- DAT_ReceivedChatMessage
    exports.addChatMessageToDisplayList(0x191d768, chatDisplayParam1, chatDisplayParam2)
end

local onCommand = function(registers)
    local chatMessage = core.readString(0x01a1f240)

    if chatMessage:sub(1) ~= "/" then return registers end

    local handled = false

    for k, v in pairs(COMMAND_REGISTRY) do
        if startsWith(chatMessage, "/" .. k) then
            handled = true
            local success, errorMessage = pcall(v, chatMessage)
            if not success then
                local text = "Error: " .. errorMessage
                local b = convertStringToBytes(text)
                table.insert(b, 0)
                core.writeBytes(0x01a1f240, b) -- DAT_ReceivedChatMessage

                return registers
            end
            break
        end
    end

    if not handled then
        local text = "Unknown command: " .. chatMessage
        local b = convertStringToBytes(text)
        table.insert(b, 0)
        core.writeBytes(0x01a1f240, b) -- DAT_ReceivedChatMessage
    end

    return registers
end

exports = {
    enable = function(self, module_options, global_options)
        self.COMMAND_REGISTRY = COMMAND_REGISTRY

        core.detourCode(onCommand, 0x00489858, 5)

        core.writeCode(0x004b3172, { 0x90, 0x90 }) -- nop instructions to make chat available in all game modes.
        core.writeCode(0x004b3193, { 0xEB }) -- change a jnz to a jmp to display the chat window in single player games too!

        core.writeCode(0x004b30d7, { 0x90, 0x90 }) -- nop instructions to make VK_RETURN send a chat in all game modes.
        core.writeCode(0x004b30e4, { 0xEB }) -- change a jnz to a jmp to make VK_RETURN send a chat in all game modes.

        exports.addChatMessageToDisplayList = core.exposeCode(0x0047f6a0, 3, 1)

        self.registerCommand = registerCommand

        return true
    end,

    disable = function(self)
        return false, "not implemented"
    end,

    onCommand = onCommand,
    displayChatText = displayChatText,
}

return exports