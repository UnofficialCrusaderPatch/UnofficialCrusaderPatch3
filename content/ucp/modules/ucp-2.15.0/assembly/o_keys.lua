local parts = {
    o_keys_savefunc = {

        init = function(self, config, root)
            self.o_keys_savefunc = AOBScan("8B 44 24 04 F7 D8 1B C0 83 E0 0E 83 C0 20 6A 0E B9 ? ? ? ? A3 ? ? ? ? E8 ? ? ? ? C7")
            self.self = self.o_keys_savefunc + 17
            self.c1 = self.o_keys_savefunc + 22
            self.func = readInteger(self.o_keys_savefunc + 27) + (self.o_keys_savefunc + 27) -- relative address
            self.savefunc = readInteger(self.o_keys_savefunc + 50) + (self.o_keys_savefunc + 50) -- relative address
        end,

        enable = function(self, config, root)
            local code = {
                0x8B, 0x44, 0x24, 0x04, -- mov eax, [esp+4]
                0xA3, self.c1, -- mov [c1], eax
                0xB9, self.self, -- mov ecx, self
                0x6A, 0x0E, -- push E
                0xE8, relTo(self.func), -- call func
                0xE9, relTo(self.savefunc), -- jmp to save
            }
            local codeSize = calculateCodeSize(code)
            self.DoSave = allocateCode(codeSize)
            writeCode(self.DoSave, compile(code, self.DoSave))

        end,

        disable = function(self, config, root)
        end,

    },
    o_keys_savename = {

        init = function(self, config, root)
            self.o_keys_savename = AOBScan("83 79 04 00 75 03 33 C0 C3 8B 01 69 C0 ? ? ? ? 8D 84 08 ? ? ? ? C3")
            self.namebool = allocate(1, true)
            local namedata = string.byte("Quicksave", 1, -1)
            table.insert(namedata, 0)
            self.name = allocate(#namedata)
            writeBytes(self.name, namedata)
        end,

        enable = function(self, config, root)
            local code = {
                0x80, 0x3D, self.namebool, 0x00, -- cmp byte ptr [namebool], 0
                0x74, 0x06, -- je to ori code
                0xB8, self.name, -- mov eax, quicksave
                0xC3, -- ret
                -- ori code:
                0x83, 0x79, 0x04, 0x00, 0x75, 0x03, 0x33, 0xC0, 0xC3,
            }
            self.binhook = insertCode(self.o_keys_savename, 9, code)
        end,

        disable = function(self, config, root)
        end,

    },
    o_keys_s = {
        init = function(self, config, root)
            self.address = scanForAOB("A1 ? ? ? ? 8B 0C 85 ? ? ? ? 3B CB 74 2B 8B C1 69 C0 2C 03 00 00 0F BF 88")
            self.ctrl = self.address + 0x106
        end,

        enable = function(self, config, root)
            self.writeCode(self.address, compile({
                0x39, 0x1D, self.ctrl, -- cmp [ctrlpressed], ebx = 0
                0x0F, 0x84, 0xFA, 0xF3, 0xFF, 0xFF, -- jmp to move if equal

                0xC6, 0x05, root.o_keys_savename.namebool, 0x01,

                0x6A, 0x20, -- push 0x20
                0xE8, relTo(root.o_keys_savefunc.DoSave, -5 + 1), -- call save func


                0xC6, 0x05, root.o_keys_savename.namebool, 0x00,

                0x58, -- pop eax
                0xEB, 0x53 -- jmp to default/end 4B3BD3
            }))
        end,

        disable = function(self, config, root)

        end,

    },
    o_keys_loadname = {
        init = function(self, config, root)
            self.address = AOBScan("8B 44 24 04 3D F4 01 00 00 7C 05 33 C0 C2 04 00 69 C0 ? ? ? ? 8D 84 08 ? ? ? ? C2 04 00")
            self.someoffset = self.address + 25

        end,

        enable = function(self, config, root)
            self.hook = insertCode(self.address, 9, {
                0x80, 0x3D, root.o_keys_savename.namebool, 0x00, -- cmp byte ptr [namebool], 0
                0x74, 0x08, -- je to ori code
                0xB8, root.o_keys_savename.name, -- mov eax, quicksave
                0xC2, 0x04, 0x00, -- ret

                -- ori code:
                0x8B, 0x44, 0x24, 0x04, 0x3D, 0xF4, 0x01, 0x00, 0x00,

            })
        end,

        disable = function(self, config, root)

        end,

    },
    o_keys_l = {
        init = function(self, config, root)
            self.address = AOBScan("39 1D ? ? ? ? 75 63 8B 0D ? ? ? ? 8B C1 69 C0 F4 39 00 00 8B 80 ? ? ? ? 3B C3")
            self.somevar = self.address + 0x02
            self.default = readInteger(self.address + 0x20) + (self.address + 0x20) -- relative address
        end,

        enable = function(self, config, root)
            self.hook = insertCode(self.address, 6, {
                0x39, 0x1D, root.o_keys_s.ctrl, -- cmp [ctrlpressed], ebx = 0
                0x74, 0x1B, -- je to ori code

                0xC6, 0x05, root.o_keys_savename.namebool, 0x01,

                0x6A, 0x1F, -- push 0x1F
                0xE8, relTo(root.o_keys_savefunc.DoSave, -5 + 1), -- call save func

                0xC6, 0x05, root.o_keys_savename.namebool, 0x00,

                0x58, -- pop eax

                0xE9, relTo(self.default, -5 + 1), -- jump awayy

                -- ori code
                0x39, 0x1D, self.somevar,

            })
        end,

        disable = function(self, config, root)

        end,

    },
    o_keys_down = {
        init = function(self, config, root)
            self.address = AOBScan("10 11 12 28 13 28 14 15 16 28 28 17 18 19 28 1A 1B 28 1C 1D 28 1E 1F 20 28 21 28 28 28 28 28 22")
        end,

        enable = function(self, config, root)
            writeCode(self.address, { 0x09 })
            writeCode(self.address + 1 + 2, { 0x0B })
            writeCode(self.address + 1 + 2 + 1 + 0x03 + 0x0E + 1, { 0x0A })
        end,

        disable = function(self, config, root)

        end,

    },
    o_keys_up = {},
    o_keys_menu = {},
}

return {

    init = function(self, config)
        for k, part in pairs(parts) do
            part:init(config, self)
        end
    end,

    enable = function(self, config)
        for k, part in pairs(parts) do
            part:enable(config, self)
        end
    end,

    disable = function(self, config)
        for k, part in pairs(parts) do
            part:disable(config, self)
        end
    end,

}