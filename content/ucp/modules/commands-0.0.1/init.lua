local exports

local COMMAND_REGISTRY = {}

local convertStringToBytes = function(s)
    return table.pack(string.byte(s, 1, -1))
end

local convertStringToNullTerminatedBytes = function(s)
    local r = convertStringToBytes(s)
    table.insert(r, 0)
    return r
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

local activateModalDialog = core.exposeCode(0x004a9ed0, 3, 1)

local onCommand = function(registers)
    local chatMessage = core.readString(0x01a1f240)

    if chatMessage:sub(1, 1) ~= "/" then
        activateModalDialog(0x01fe7c90, -1, 0) -- close the chat modal
        return registers
    end

    local handled = false

    for k, v in pairs(COMMAND_REGISTRY) do
        if startsWith(chatMessage, "/" .. k) then
            handled = true
            local success, keepModalOpen = pcall(v, chatMessage)

            if not success then
                log(WARNING, "[commands]: error in processing command: " .. chatMessage .. "\nerror: " .. closeModal)
                core.writeBytes(0x01a1f240, convertStringToNullTerminatedBytes("[commands]: error in processing command: " .. chatMessage .. "\nerror: " .. closeModal)) -- DAT_ReceivedChatMessage
                activateModalDialog(0x01fe7c90, -1, 0) -- close the chat modal
            else
                if not keepModalOpen then
                    activateModalDialog(0x01fe7c90, -1, 0) -- close the chat modal
                end
            end

            return registers
            -- core.writeBytes(0x01a1f240, b) -- DAT_ReceivedChatMessage
        end
    end

    if not handled then
        local text = "Unknown command: " .. chatMessage
        local b = convertStringToBytes(text)
        table.insert(b, 0)
        core.writeBytes(0x01a1f240, b) -- DAT_ReceivedChatMessage

        activateModalDialog(0x01fe7c90, -1, 0) -- close the chat modal
    end

    return registers
end

-- namespace

exports = {
    enable = function(self, module_options, global_options)
        self.COMMAND_REGISTRY = COMMAND_REGISTRY

        core.detourCode(onCommand, 0x00489858, 5)

        core.writeCode(0x004b3172, { 0x90, 0x90 }) -- nop instructions to make chat available in all game modes.
        core.writeCode(0x004b3193, { 0xEB }) -- change a jnz to a jmp to display the chat window in single player games too!

        core.writeCode(0x004b30d7, { 0x90, 0x90 }) -- nop instructions to make VK_RETURN send a chat in all game modes.
        core.writeCode(0x004b30e4, { 0xEB }) -- change a jnz to a jmp to make VK_RETURN send a chat in all game modes.

        core.writeCode(0x004b315d, {
            0x90, 0x90, 0x90, 0x90,
            0x90, 0x90, 0x90, 0x90,
            0x90, 0x90, 0x90, 0x90, 0x90}) -- wipe 13 bytes to prevent automatic closing of chat modal

        exports.addChatMessageToDisplayList = core.exposeCode(0x0047f6a0, 3, 1)

        self.registerCommand = registerCommand

        self.registerCommand("help", function(command)
            local commands = {}
            for k, v in pairs(COMMAND_REGISTRY) do
                table.insert(commands, k)
            end
            table.sort(commands)
            local result = ""
            for k, command in pairs(commands) do
                result = result .. ", " .. command
            end
            displayChatText("available commands: " .. result)
        end)

        return true
    end,

    disable = function(self)
        return false, "not implemented"
    end,

    onCommand = onCommand,
    displayChatText = displayChatText,
}

return exports