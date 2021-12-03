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

-- new DefaultHeader("o_fast_placing_all", false)
-- {
-- // 00445D8C
-- new BinaryEdit("o_fast_placing")
-- {
-- new BinSkip(3),
-- new BinBytes(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
-- new BinSkip(9),
-- new BinAddress("timeGetTime", 6),
-- // reverse assembler optimization
-- new BinHook(10)
-- {
-- 0x83, 0xF8, 0x63, // cmp eax,0x63
-- 0x0F, 0x84, new BinRefTo("SkipSpeedCap"), // je SkipSpeedCap
-- // original code
-- 0x8B, 0x35, new BinRefTo("timeGetTime", false)// mov esi,ds:timeGetTime
-- },
-- new BinSkip(22),
-- // reduce multiplayer speed cap
-- new BinBytes(0x64),
-- new BinSkip(20),
-- new BinLabel("SkipSpeedCap")
-- },
-- }
-- Fix broken map sending mechanic
--____NEW CHANGE: o_fix_map_sending
return {

    init = function(self, config)
        -- 00489CE9
        self.o_fix_map_sending_edit = AOBScan("6A 00 68 D0 07 00 00 8D 44 24 14")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("o_fix_map_sending")
        local code = {
            0xE0, 0x03,  -- sent map name size; before: 7D0h
        }
        writeCode(self.o_fix_map_sending_edit + 0 + 3, code)
        local code = {
            0xE0, 0x03, 
        }
        writeCode(self.o_fix_map_sending_edit + 0 + 3 + 2 + 134, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
