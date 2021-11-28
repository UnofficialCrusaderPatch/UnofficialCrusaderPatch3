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

-- /*
-- AI RECRUIT INTERVALS
-- */
-- AI_OFFSET = AI_INDEX * 169
-- recruit interval: 023FC8E8 + AI_OFFSET * 4 + 164
-- start of game offsets?
-- rat offset: 0xA9  => 1, 1, 1
-- snake offset: 0x152 => 1, 0, 1
-- pig offset: 0x1FB => 1, 1, 4
-- wolf offset: 0x2A4 => 4, 1, 4
-- saladin offset: 0x34D => 1, 1, 1
-- kalif offset: 0x3F6 => 0, 1, 0
-- sultan offset: 0x49F  => 8, 8, 4
-- richard offset: 0x548  => 1, 1, 1
-- frederick offset: 0x5F1  => 4, 1, 4
-- philipp offset: 0x69A  => 4, 4, 4
-- wazir offset: 0x743  => 1, 1, 1
-- emir offset: 0x7EC  => 0, 1, 0
-- nizar offset: 0x895  => 4, 8, 1
-- sheriff offset: 0x93E  => 4, 1, 4
-- marshal offset: 0x9E7  => 1, 1, 4
-- abbot offset: 0xA90  => 1, 1, 1
-- +4, normal2
-- +8, turned up?
-- disable sleeping phase for AI recruitment during attacks
-- this is no good, because the AI sends newly recruited troops instantly forth
-- while an attack is still going on, ending in streams of single soldiers
-- 004D3BF6 jne 2E, skips some comparisons
-- BinBytes.Change("ai_recruitsleep", ChangeType.Balancing, false, 0x75, 0x2E),
-- /*
-- AI RECRUITMENT ATTACK LIMITS
-- */ 
-- attack start troops: 023FC8E8 + AI_OFFSET * 4 + 1F4
-- rat => 20
-- snake => 30
-- pig => 10
-- wolf => 40
-- saladin => 50
-- kalif => 15
-- sultan => 10
-- richard => 20
-- frederick => 30
-- philipp => 10
-- wazir => 40
-- emir => 30
-- nizar => 40
-- sheriff => 50
-- marshal => 10
-- abbot => 50
-- sets the recruitment interval to 1 for all AIs
-- 004D3B41 mov eax, 1
--____NEW CHANGE: ai_recruitinterval
return {

    init = function(self, config)
        self.ai_recruitinterval_edit = AOBScan("8B 84 AA 64 01 00 00 8B E8 F7 DD 1B ED 83 C5 02 84 C9 89 6C 24 1C 74 07 83 C5 01 89 6C 24 1C 8B")
    end,

    enable = function(self, config)
        
        local code = {
            0xB8, 0x01, 0, 0, 0, 0x90, 0x90
        }
        writeCode(self.ai_recruitinterval_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
