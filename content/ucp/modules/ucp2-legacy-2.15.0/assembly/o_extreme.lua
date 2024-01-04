local writeCode = core.writeCode
local readBytes = core.readBytes
local AOBScan = core.AOBScan

return {

    init = function(self, config)
        if config.o_xtreme.o_xtreme[1] then
            self.extreme_bar_1 = AOBScan("B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 53 B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 53 B9 ? ? ? ? E8 ? ? ? ? B9")
            self.extreme_bar_2 = AOBScan("A1 ? ? ? ? 85 C0 74 12 83 F8 63 74 0D 83 3D ? ? ? ? 00 0F 85 F2 00 00 00 A1")
        end
    end,

    enable = function(self, config)
        if config.o_xtreme.o_xtreme[1] then
            self.o1 = readBytes(self.extreme_bar_1, 10)

            local nops = {}
            for i = 1, 10 do
                table.insert(nops, 0x90)
            end
            writeCode(self.extreme_bar_1, nops)

            self.o2 = readBytes(self.extreme_bar_2, 1)

            writeCode(self.extreme_bar_2, { 0xC3 })
        end
    end,

    disable = function(self, config)
        writeCode(self.extreme_bar_1, self.o1)
        writeCode(self.extreme_bar_2, self.o2)
    end,


}