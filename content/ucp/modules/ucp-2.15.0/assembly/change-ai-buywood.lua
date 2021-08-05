
return {
    init = function(self, config)
        self.ai_buywood = core.AOBScan("3B 9E ? ? ? ? 7E 58 8B 44 24 10 5F 89 9E ? ? ? ? 5E 5D 5B 83 C4 18 C2 0C 00")
        self.offset = core.readInteger(self.ai_buywood + 2)
    end,
    enable = function(self, config)
        self.hook = core.insertCode(self.ai_buywood, 6, {
            0x83, 0xC3, 0x02, -- add ebx, 2
            0x3B, 0x9E, self.offset,
        })
    end,
    disable = function(self, config)

    end,
}