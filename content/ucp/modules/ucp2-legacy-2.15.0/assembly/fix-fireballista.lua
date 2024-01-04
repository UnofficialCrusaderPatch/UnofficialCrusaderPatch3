local byteRelTo = core.byteRelTo
local writeCode = core.writeCode
local insertCode = core.insertCode
local AOBScan = core.AOBScan

return {
    init = function(self, config)
        self.u_fireballistatunneler = AOBScan("83 F8 25 75 4C") + 13
        self.u_fireballistamonk = AOBScan("04 04 02 02 02 04 04 04 04 04 04 04 04 04 04 04 04 04 03 04 04 02 02 02 02 04 04 04 04 04 04 04")
    end,
    enable = function(self, config)
        local hookCode = {
            0x83, 0xF8, 5, -- cmp eax, 5
            0x9C, -- pushf
            0x83, 0xc0, 0xea, -- add eax, 0xffffffea
            0x9d, --popf
            0x75, byteRelTo("label_1", -2 + 1), -- jne 5
            0xB8, 0x05, 0x00, 0x00, 0x00, -- mov eax, 0x5
            "label_1",
            0x83, 0xF8, 0x25, -- cmp eax, 0x25
        }
        self.hookAddress = insertCode(self.u_fireballistatunneler, 6, hookCode)

        self.patch = writeCode(self.u_fireballistamonk, { 0x00 })
    end,

    disable = function(self, config)
    end,

}