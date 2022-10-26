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

--____NEW CHANGE: ai_housing
return {

    init = function(self, config)
        if config.build_housing.enabled then
            self.build_housing_enabled = true
            self.build_housing_value = config.build_housing.sliderValue or 0
        end

        if config.campfire_housing.enabled then
            self.campfire_housing_enabled = true
            self.campfire_housing_value = config.campfire_housing.sliderValue or 0 
        end

        if config.delete_housing.enabled then
            self.delete_housing_enabled = true
        end
        
        self.ai_buildhousing_edit = AOBScan("83 F9 0C 7E E6")
        self.ai_deletehousing_edit = AOBScan("75 06 33 C0 5F C2 04 00 8B 88")
    end,

    enable = function(self, config)
        
        if self.build_housing_enabled then
            
            -- new SliderHeader("build_housing", true, 0, 100, 1, 0, 5)
            local code = {
                0xE9, function(address, index, labels)
                    local hook = { -- the first 5 bytes are an if condition that just checks if the first house has been built yet
                        0x81, 0xE9, itob(self.build_housing_value),  -- the value of the slider header gets put into the location of new BinInt32Value()
                        0xe9, relTo(self.ai_buildhousing_edit + 5, -4)
                    }
                    local hookSize = calculateCodeSize(hook)
                    local hookAddress = allocateCode(hookSize)
                    writeCode(hookAddress, hook)
                    return itob(getRelativeAddress(address, hookAddress, -4))
                end,
            }
            writeCode(self.ai_buildhousing_edit, code)
            local code = {
                0x7F, 0xDE, 
            }
            writeCode(self.ai_buildhousing_edit + 5 + 6, code)
            local code = {
                0x90, 0x90, 
            }
            writeCode(self.ai_deletehousing_edit, code)
        end

        if self.campfire_housing_enabled then
            
            -- new SliderHeader("campfire_housing", true, 0, 25, 1, 5, 10)
            local code = {
                0x7D, 0x08, 
            }
            writeCode(self.ai_buildhousing_edit + 0 + 11, code)
            -- skip everything until we come to the campfire logic comparison
            local code = {
                0xB9, itob(self.campfire_housing_value),  -- replace the 5 with the user input value from the slider header
            }
            writeCode(self.ai_buildhousing_edit + 0 + 11 + 2 + 8, code)
            local code = {
                0x7C, 0xC7, 
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 
            }
            writeCode(self.ai_buildhousing_edit + 0 + 11 + 2 + 8 + 5 + 8, code)
            local code = {
                0x90, 0x90, 
            }
            writeCode(self.ai_deletehousing_edit, code)

        end

        if self.delete_housing_enabled then
            -- new DefaultHeader("delete_housing")
            local code = {
                0x90, 0x90, 
            }
            writeCode(self.ai_deletehousing_edit, code)
        end

    end,

    disable = function(self, config)
        error("not implemented")
    end,

}