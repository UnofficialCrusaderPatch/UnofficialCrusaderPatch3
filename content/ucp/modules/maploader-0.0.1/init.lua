return {
    enable = function(self, config)
        --The idea is to have a sub selection of maps on startup. It will make the game run faster. Perhaps point the game to a custom folder to load maps?
        for k, v in pairs(config) do
          modules.files:setIterationOption(k, v)
        end
    end,
    disable = function()  end
}