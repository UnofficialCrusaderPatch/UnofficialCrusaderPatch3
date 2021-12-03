local writeCode = core.writeCode

local modifyJMP1 = 0x0057C29A -- 0057C29A
local modifyJMP2 = 0x0057C2A2 -- 0057C2A2
local modifyJMP3 = 0x0057C3F4 -- 0057C3F4
local modifyJMP4 = 0x0057C400 -- 0057C400
local modifyJMP5 = 0x004700AC -- 004700AC

local exports = {}

exports.enable = function()
    writeCode(modifyJMP1, {0x90, 0x90}, false)
    writeCode(modifyJMP2, {0xEB}, false)
    writeCode(modifyJMP3, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90}, false)
    writeCode(modifyJMP4, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90}, false)
    writeCode(modifyJMP5, {0x90, 0x90}, false)
end

exports.disable = function()
    writeCode(modifyJMP1, {0x75, 0x08}, false)
    writeCode(modifyJMP2, {0x75}, false)
    writeCode(modifyJMP3, {0x0F, 0x85, 0xDD, 0x02, 0x00, 0x00}, false)
    writeCode(modifyJMP4, {0x0F, 0x84, 0xD1, 0x02, 0x00, 0x00}, false)
    writeCode(modifyJMP5, {0x75, 0xE3}, false)
end

return exports