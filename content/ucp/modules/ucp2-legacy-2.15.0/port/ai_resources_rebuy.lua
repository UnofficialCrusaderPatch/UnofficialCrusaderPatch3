local writeCode = core.writeCode
local AOBScan = core.AOBScan

-- /*
-- ENABLE ADJUSTABLE PERIODICAL RESTOCKING OF GOODS THAT ARE NEEDE FOR PRODUCTION
-- */
-- Extreme adresses:
-- 004cc010
-- 004cc02B
-- 004cc04E
--____NEW CHANGES: ai_noflour_maxtime, ai_noiron_maxtime, ai_nowood_maxtime
return {
    init = function(self, config)
        self.ai_noflour_maxtime = AOBScan("24 7E 0E 39 9E ? ? ? ? 75 06 89 86 ? ? ? ? 83 BE ? ? ? ? 48 7E 0E 39 9E ? ? ? ? 75 06 89 86")
        self.ai_noiron_maxtime = AOBScan("24 7E 15 39 9E ? ? ? ? 75 0D B8 02 00 00 00 89 86 ? ? ? ? EB 05 B8 02 00 00 00 83 BE ? ? ? ? 24")        
        self.ai_nowood_maxtime = AOBScan("24 7E 12 39 9E ? ? ? ? 75 0A C7 86 ? ? ? ? 05 00 00 00 83 BE ? ? ? ? 24 7E 15 39 9E")
    end,

    enable = function(self, config)
        if config.flour.enabled then
            writeCode(self.ai_noflour_maxtime, {config.flour.sliderValue})
        end
        
        if config.iron.enabled then
            writeCode(self.ai_noiron_maxtime, {config.iron.sliderValue})
        end
        
        if config.wood.enabled then
            writeCode(self.ai_nowood_maxtime, {config.wood.sliderValue})
        end
    end,

    disable = function(self, config)
        error("not implemented")
    end,
}
