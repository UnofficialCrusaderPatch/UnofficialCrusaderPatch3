local writeCode = core.writeCode
local AOBScan = core.AOBScan
local compile = core.compile
local calculateCodeSize = core.calculateCodeSize
local allocateCode = core.allocateCode
local itob = utils.itob
local getRelativeAddress = core.getRelativeAddress
local relTo = core.relTo
local byteRelTo = core.byteRelTo

--[[
  /*
   *  EXTENDED GAME SPEED 
   */ 

  new Change("o_gamespeed", ChangeType.Other)
  {
      new DefaultHeader("o_gamespeed")
      {
          // 4B4748
          new BinaryEdit("o_gamespeed_up")
          {
              CMP(EAX, 10000),      // cmp eax, 10000

              JMP(GREATERTHANEQUALS, 0x19), // jge to end

              MOV(EDI, EAX),              // mov edi, eax

              CMP(EAX, 200),     // cmp eax, 200
              new BinHook("label1", 0x0F, 0x8C)                // jl hook
              {
                  CMP(EAX, 90), // cmp eax, 90
                  JMP(LESS, 0x03),       // jl to end
                  ADD(EDI, 5), // add edi, 5
              },
              ADD(EDI, 0x5F),        // add edi, 95
              new BinLabel("label1"),
              ADD(EDI, 5),       // add edi, 5
              JMP(UNCONDITIONAL, 0x75),              // jmp to gamespeed_down set value
              new BinBytes(0x90, 0x90, 0x90, 0x90),
          },

          // 004B47C2
          new BinaryEdit("o_gamespeed_down")
          {
              JMP(LESSTHANEQUALS, 0x1B), // jle to end

              MOV(EDI, EAX),              // mov edi, eax

              CMP(EAX, 200),     // cmp eax, 200
              new BinHook("label2", 0x0F, 0x8E)                // jle hook
              {
                  CMP(EAX, 0x5A), // cmp eax, 90
                  JMP(LESSTHANEQUALS, 0x03),       // jle to end
                  SUB(EDI, 0x05), // sub edi, 5
              },
              SUB(EDI, 0x5F),        // sub edi, 95
              new BinLabel("label2"),
              SUB(EDI, 5),        // sub edi, 5
              new BinBytes(0x90, 0x90),
          }
      }
  },
--]]

return {

    init = function(self, config)
        self.o_gamespeed_up = AOBScan("83 F8 5A 0F 8D ? ? ? ? 83 C0 05 83 F8 5A A3 ? ? ? ? 7E 0A C7 05 ? ? ? ? 5A 00 00 00")
        self.o_gamespeed_down = AOBScan("0F 8E 0B F4 FF FF 83 E8 05 BF 14 00 00 00 3B C7 A3 ? ? ? ? 7D 8F 89 3D ? ? ? ? EB 87 3D")
    end,

    enable = function(self, config)
        local code_up = {
            0x3D, 0x10, 0x27, 0x00, 0x00, -- cmp eax, 10000
            0x7D, byteRelTo("end", -2 + 1), -- 0x7D, 0x19, -- jge end
            0x89, 0xc7, -- mov edi, eax
            0x3d, 0xc8, 0x00, 0x00, 0x00, -- cmp eax, 200
            0x0f, 0x8c, function(address, index, labels)
                -- jl hook
                local hook = {
                    0x83, 0xf8, 0x5a, -- cmp eax, 0x5A
                    0x7C, byteRelTo("endOfHook", -2 + 1), -- 0x7C, 0x03, -- jl endOfHook; jump 3 bytes
                    0x83, 0xc7, 0x05, -- add edi, 0x05
                    "endOfHook",
                    0xe9, relTo(labels["label1"], -5 + 1), -- jmp label1,  'labels["label1"]' is the absolute address of label1; JMP (0xe9) does 5 bytes "too many", so we need to adjust 4 of them.
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook) -- compiled by writeCode
                return itob(getRelativeAddress(address, hookAddress, -6 + 2)) -- return the relative address for the 'jl hook' statement; ; JL (0x0f, 0x8c) does 6 bytes too many, so we need to adjust 4 of them.
            end,
            0x83, 0xC7, 0x5F, -- add edi, 95
            "label1",
            0x83, 0xc7, 0x05, -- add edi, 5
            0xEB, 0x75, -- jmp to gamespeed_down set value
            0x90, 0x90, 0x90, 0x90, -- nop nop nop nop
            "end"
        }
        writeCode(self.o_gamespeed_up, code_up)

        local code_down = {
            0x7E, byteRelTo("end", -2 + 1), -- 0x7E, 0x1B, -- jle end
            0x89, 0xc7, -- mov edi, eax
            0x3D, 0xC8, 0x00, 0x00, 0x00, -- cmp eax, 200
            0x0F, 0x8E, function(address, index, labels)
                -- jle hook
                local hook = {
                    0x83, 0xf8, 0x5a, -- cmp eax, 90
                    0x7E, byteRelTo("endOfHook", -2 + 1), -- 0x7E, 0x03, -- jle endOfHook; jump 3 bytes
                    0x83, 0xEF, 0x05, -- sub edi, 0x05
                    "endOfHook",
                    0xe9, relTo(labels["label2"], -5 + 1),
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook) -- compiled by writeCode
                return itob(getRelativeAddress(address, hookAddress, -6 + 2))
            end,
            0x83, 0xEF, 0x5F, -- sub edi, 95
            "label2",
            0x83, 0xEF, 0x05, -- sub edi, 5
            0x90, 0x90, -- nop nop
            "end"
        }
        writeCode(self.o_gamespeed_down, code_down)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}