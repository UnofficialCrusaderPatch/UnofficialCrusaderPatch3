-- local assemblyChanges = {
    -- "assembly/change-spearmen-run.lua",
    -- "assembly/change-responsive-gates.lua",
    -- "assembly/change-moat-visibility.lua",
    -- "assembly/change-free-trader-post.lua",
    -- "assembly/change-engineer-tent-no-deselect.lua",
    -- "assembly/change-increase-path-update-tick-rate.lua",
    -- "assembly/change-healer.lua",
-- }

-- local assemblyFixes = {
    -- "assembly/fix-ai-demolishing-inaccessible-buildings.lua",
    -- "assembly/fix-ai-ox-tether-spam.lua",
    -- "assembly/fix-ai-tower-engine-replenishment.lua",
    -- "assembly/fix-fletcher-bug.lua",
    -- "assembly/fix-baker-disappear-bug.lua",
    -- -- Not working yet
    -- -- "assembly/fix-ai-wood-buying.lua",
    -- "assembly/fix-ladderclimb.lua",
-- }

-- local changesV2 = {
    -- "assembly/change-fire-cooldown.lua",
    -- "assembly/o_extreme.lua",
    -- "assembly/o-gamespeed.lua",
    -- "assembly/fix-fireballista.lua",
    -- "assembly/change-ai-wall-defenses.lua",
    -- "assembly/change-ai-buywood.lua",

-- }

--writeCode(0x0053D3D9, {0xE9, table.unpack({0x11, 0x22, 0x33, 0x44})})

local portedFiles = {
"ai_access",
"ai_assaultswitch",
"ai_attacktarget",
"ai_attackwave",
"ai_buywood",
"ai_defense",
"ai_demolish",
"ai_fix_crusader_archers_pitch",
"ai_fix_laddermen_with_enclosed_keep",
"ai_nosleep",
"ai_rebuild",
"ai_recruitinterval",
"ai_tethers",
"ai_towerengines",
"fix_apple_orchard_build_size",
"o_armory_marketplace_weapon_order_fix",
"o_change_siege_engine_spawn_position_catapult",
"o_engineertent",
"o_fix_baker_disappear",
"o_fix_fletcher_bug",
"o_fix_ladderclimb",
"o_fix_moat_digging_unit_disappearing",
"o_freetrader",
"o_gamespeed",
"o_healer",
"o_increase_path_update_tick_rate",
"o_keys",
"o_moatvisibility",
"o_onlyai",
"o_override_identity_menu",
"o_responsivegates",
"o_restore_arabian_engineer_speech",
"o_seed_modification_possibility_title",
"o_shfy",
"o_stop_player_keep_rotation",
"o_xtreme",
"u_arabwall",
"u_arabxbow",
"u_fireballistafix",
"u_fix_applefarm_blocking",
"u_fix_lord_animation_stuck_movement",
"u_spearmen",
"u_spearmen_run",
"u_laddermen",
"u_tanner_fix",
}

local changes = {}

-- local cfg = require('cfg-converter')
-- local config = cfg.getCFG('ucp.cfg')

return {

    enable = function(self, config)
    
        log(DEBUG, "loading ucp changes")
        
        for change, opts in pairs(config) do
          if opts.enabled and opts.enabled == true then
            changes[change] = require("port/" .. change)
          end
        end
        
        for name, change in pairs(changes) do
          log(DEBUG, "initializing: " .. name)
          change:init(config[name])
        end
        
        for name, change in pairs(changes) do
          log(DEBUG, "enabling: " .. name)
          change:enable(config[name])
        end

    end,

    disable = function(self, config)
        return false, "not implemented"
    end,

}



