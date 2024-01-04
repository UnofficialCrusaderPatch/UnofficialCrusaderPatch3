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
-- AI REBUILD STUFF
-- */ 
--____NEW CHANGE: ai_rebuild
return {

    init = function(self, config)
        -- 004F94DA + 7
        self.ai_rebuildwalls_edit = AOBScan("0C 0F 8C 93 00 00 00 A9 00 04 00 00 0F 85 88 00 00 00 85 C9 0F 85 80 00 00 00 A8 14 75 7C A9 81")
        -- 005161FB
        self.ai_rebuildtowers_edit = AOBScan("0F 85 9F 00 00 00 6A 32 55 56 B9 ? ? ? ? E8 ? ? ? ? 56 B9 ? ? ? ? E8 ? ? ? ? 56")
    end,

    enable = function(self, config)
        
        -- new DefaultHeader("ai_rebuild")
        local code = {
            0x01
        }
        writeCode(self.ai_rebuildwalls_edit, code)
        local theEnd = self.ai_rebuildtowers_edit + 2 + 4 + readInteger(self.ai_rebuildtowers_edit + 2)
        local dem = self.ai_rebuildtowers_edit + 6
        local code = {
            0x0F, 0x85, function(address, index, labels)
                local hook = {
                 -- quarry platform
                    0x66, 0x3D, 0x15, 0x00,  -- cmp ax, 15h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                 -- tower ruins
                    0x66, 0x3D, 0x56, 0x00,  -- cmp ax, 56h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x57, 0x00,  -- cmp ax, 57h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x58, 0x00,  -- cmp ax, 58h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x59, 0x00,  -- cmp ax, 59h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x4F, 0x00,  -- cmp ax, 4Fh
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                 -- engineer, tunnel & oil places
                    0x66, 0x3D, 0x35, 0x00,  -- cmp ax, 35h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x3B, 0x00,  -- cmp ax, 3Bh
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0x66, 0x3D, 0x33, 0x00,  -- cmp ax, 33h
                    0x0F, 0x84, function(index) return itob(getRelativeAddress(index, dem, -4)) end, 
                    0xe9, relTo(theEnd, -4)
                }
                local hookSize = calculateCodeSize(hook)
                local hookAddress = allocateCode(hookSize)
                writeCode(hookAddress, hook)
                return itob(getRelativeAddress(address, hookAddress, -4))
            end,
        }
        writeCode(self.ai_rebuildtowers_edit, code)
    end,

    disable = function(self, config)
        error("not implemented")
    end,

}
