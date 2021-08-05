local writeCode = core.writeCode
local readSmallInteger = core.readSmallInteger
local smallIntegerToBytes = utils.smallIntegerToBytes
local AOBScan = core.AOBScan

return {

    init = function(self, config)
        local address = AOBScan("66 C7 84 30 D8 02 00 00 D0 07 0F B7 80 ? ? ? ? 66 3D 1E 00 89 4C 24 18 75 05 8D 5F 09 EB 25")

        self.target_address = address + 8
        self.originalValue = readSmallInteger(self.target_address)

    end,

    enable = function(self, config)
        -- o_firecooldown={ o_firecooldown={False;2000} }
        if config.o_firecooldown.o_firecooldown[1] then
            local value = config.o_firecooldown.o_firecooldown[2]
            writeCode(self.target_address, smallIntegerToBytes(value))
        else
            writeCode(self.target_address, smallIntegerToBytes(self.originalValue))
        end
    end,

    disable = function(self, config)
        writeCode(self.target_address, smallIntegerToBytes(self.originalValue))
    end,

}