local writeCode = core.writeCode
local writeBytes = core.writeBytes
local AOBScan = core.AOBScan
local compile = core.compile
local calculateCodeSize = core.calculateCodeSize
local allocate = core.allocate
local allocateCode = core.allocateCode
local getRelativeAddress = core.getRelativeAddress
local relTo = core.relTo
local relToLabel = core.relToLabel
local byteRelTo = core.byteRelTo
local readInteger = core.readInteger

local itob = utils.itob
local smallIntegerToBytes = utils.smallIntegerToBytes

--____NEW CHANGE: ai_addattack
return {

    init = function(self, config)
        if config.choice == 'absolute' then
            self.ai_addattack_enabled = true
            self.ai_addattack_value = config.choices.absolute.slider or 5
        elseif config.choice == 'relative' then
            self.ai_addattack_alt_enabled = true
            self.ai_addattack_alt_value = config.choices.relative.slider or 0
        elseif config.choice == nil or config.choice == '' then
        else
        end

        -- 004CDEDC
        self.ai_addattack_edit = AOBScan("7E 11 8D 0C C5 00 00 00 00 2B C8 01 8E ? ? ? ? EB 09 8D 14 80 01 96 ? ? ? ? B8 C8 00 00")
        -- 004CDE7C
        self.ai_addattack_alt_edit = AOBScan("53 57 8D 78 FF 0F BF 05 ? ? ? ? 99 B9 64 00 00 00 F7 F9 B9 ? ? ? ? 8B DA E8")
    end,

    enable = function(self, config)
        
        if self.ai_addattack_enabled == true then
            -- vanilla:
            -- additional attack troops = factor * attack number
            -- new SliderHeader("ai_addattack", true, 0, 250, 1, 5, 12)
            local code = {
            -- if (ai gold < 10000)
                0x7E, 0x7,  -- jle to 8
                0xB9,  -- mov ecx, value * 7/5 (vanilla = 7)
                itob(self.ai_addattack_value * (7//5)), 
                0xEB, 0x5,  -- jmp
                0xB9,  -- mov ecx, value (vanilla = 5)
                itob(self.ai_addattack_value), 
                0xF7, 0xE9,  -- imul ecx
                0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 
                0x01, 0x86,  -- mov [addtroops], eax instead of ecx
            }
        
            writeCode(self.ai_addattack_edit, code)
        end

        if self.ai_addattack_alt_enabled == true then
                
            -- alternative:
            -- additional attack troops = factor * initial attack troops * attack number
            -- new SliderHeader("ai_addattack_alt", false, 0.0, 3.0, 0.1, 0.0, 0.3)
            local attacknum = readInteger(self.ai_addattack_alt_edit + 0x2F) -- [0115F71C]
            local addtroops = readInteger(self.ai_addattack_alt_edit + 0x55) -- [0115F698]
            local code = {
                0x83, 0xE8, 0x1,  -- sub eax,01   => ai_index
                0x69, 0xC0, 0xA4, 0x02, 0x00, 0x00,  -- imul eax, 2A4 { 676 }  => ai_offset
                0x8B, 0x84, 0x28, 0xF4, 0x01, 0x00, 0x00,  -- mov eax,[eax+ebp+1F4]   => initial attack troops
                0x8B, 0x8E,  -- mov ecx,[esi+0115F71C]   => attack number
                itob(attacknum), 
                0xF7, 0xE9,  -- imul ecx   => attack number * initial attack troops
                0x69, 0xC0,  -- imul eax, value
                itob(self.ai_addattack_alt_value * 10), 
                0xB9, 0x0A, 0x00, 0x00, 0x00,  -- mov ecx, 0A { 10 }
                0xF7, 0xF9,  -- idiv ecx
                0x83, 0xC0, 0x5,  -- add eax, 5   => because in vanilla, attackNum was already 1 for first attack
                0x89, 0x86,  -- mov [esi+0115F698],eax   =>  addtroops = result
                itob(addtroops), 
                0xFF, 0x86,  -- inc [esi+0115F71C]  => attack number++
                itob(attacknum), 
                0xEB, 0x46,  -- jmp over nops
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
            }
            
            writeCode(self.ai_addattack_alt_edit, code)
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}