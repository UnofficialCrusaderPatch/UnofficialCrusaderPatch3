
local changes = {
  ["ai_access"] = "port/ai_access.lua",
  ["ai_addattack"] = "port/ai_addattack.lua",
  ["ai_assaultswitch"] = "port/ai_assaultswitch.lua",
  ["ai_attacklimit"] = "port/ai_attacklimit.lua",
  ["ai_attacktarget"] = "port/ai_attacktarget.lua",
  ["ai_attackwave"] = "port/ai_attackwave.lua",
  ["ai_buywood"] = "port/ai_buywood.lua",
  ["ai_defense"] = "port/ai_defense.lua",
  ["ai_demolish"] = "port/ai_demolish.lua",
  ["ai_fix_crusader_archers_pitch"] = "port/ai_fix_crusader_archers_pitch.lua",
  ["ai_fix_laddermen_with_enclosed_keep"] = "port/ai_fix_laddermen_with_enclosed_keep.lua",
  ["ai_housing"] = "port/ai_housing.lua",
  ["ai_nosleep"] = "port/ai_nosleep.lua",
  ["ai_rebuild"] = "port/ai_rebuild.lua",
  ["ai_recruitinterval"] = "port/ai_recruitinterval.lua",
  ["ai_recruitstate_initialtimer"] = "port/ai_recruitstate_initialtimer.lua",
  ["ai_tethers"] = "port/ai_tethers.lua",
  ["ai_towerengines"] = "port/ai_towerengines.lua",
  ["fix_apple_orchard_build_size"] = "port/fix_apple_orchard_build_size.lua",
  ["o_armory_marketplace_weapon_order_fix"] = "port/o_armory_marketplace_weapon_order_fix.lua",
  ["o_change_siege_engine_spawn_position_catapult"] = "port/o_change_siege_engine_spawn_position_catapult.lua",
  ["o_default_multiplayer_speed"] = "port/o_default_multiplayer_speed.lua",
  ["o_disable_border_scrolling"] = "port/o_disable_border_scrolling.lua",
  ["o_engineertent"] = "port/o_engineertent.lua",
  ["o_fast_placing"] = "port/o_fast_placing.lua",
  ["o_firecooldown"] = "port/o_firecooldown.lua",
  ["o_fix_baker_disappear"] = "port/o_fix_baker_disappear.lua",
  ["o_fix_fletcher_bug"] = "port/o_fix_fletcher_bug.lua",
  ["o_fix_ladderclimb"] = "port/o_fix_ladderclimb.lua",
  ["o_fix_map_sending"] = "port/o_fix_map_sending.lua",
  ["o_fix_moat_digging_unit_disappearing"] = "port/o_fix_moat_digging_unit_disappearing.lua",
  ["o_fix_rapid_deletion_bug"] = "port/o_fix_rapid_deletion_bug.lua",
  ["o_freetrader"] = "port/o_freetrader.lua",
  ["o_gamespeed"] = "port/o_gamespeed.lua",
  ["o_healer"] = "port/o_healer.lua",
  ["o_increase_path_update_tick_rate"] = "port/o_increase_path_update_tick_rate.lua",
  ["o_keys"] = "port/o_keys.lua",
  ["o_moatvisibility"] = "port/o_moatvisibility.lua",
  ["o_onlyai"] = "port/o_onlyai.lua",
  ["o_override_identity_menu"] = "port/o_override_identity_menu.lua",
  ["o_playercolor"] = "port/o_playercolor.lua",
  ["o_responsivegates"] = "port/o_responsivegates.lua",
  ["o_restore_arabian_engineer_speech"] = "port/o_restore_arabian_engineer_speech.lua",
  ["o_seed_modification_possibility_title"] = "port/o_seed_modification_possibility_title.lua",
  ["o_shfy"] = "port/o_shfy.lua",
  ["o_stop_player_keep_rotation"] = "port/o_stop_player_keep_rotation.lua",
  ["o_xtreme"] = "port/o_xtreme.lua",
  ["u_arabwall"] = "port/u_arabwall.lua",
  ["u_arabxbow"] = "port/u_arabxbow.lua",
  ["u_fireballistafix"] = "port/u_fireballistafix.lua",
  ["u_fix_applefarm_blocking"] = "port/u_fix_applefarm_blocking.lua",
  ["u_fix_lord_animation_stuck_movement"] = "port/u_fix_lord_animation_stuck_movement.lua",
  ["u_laddermen"] = "port/u_laddermen.lua",
  ["u_spearmen"] = "port/u_spearmen.lua",
  ["u_spearmen_run"] = "port/u_spearmen_run.lua",
  ["u_tanner_fix"] = "port/u_tanner_fix.lua",
}

local function anyChildTrue(t)
  for k, v in pairs(t) do
    if k.enabled and k.enabled == true then
      return true
    end
  end
  return false
end

return {

    enable = function(self, config)
    
        log(DEBUG, "loading ucp changes")

        local features = {}
        
        for change, opts in pairs(config) do
          -- Only load a change if anything of that change is enabled
          if (opts.enabled and opts.enabled == true) or anyChildTrue(opts) then
            if changes[change] ~= nil then
                local f = io.open(changes[change], 'r')
                if f ~= nil then 
                  io.close(f) 
                  features[change] = require(changes[change])
                else
                  log(ERROR, "Error loading '" .. changes[change] .. "'. No such file")
                end  
              else
                log(ERROR, "A change was requested '" .. change .. "' for which no file exists")           
            end
          end
        end
        
        for name, change in pairs(features) do
          log(DEBUG, "initializing: " .. name)
          change:init(config[name])
        end
        
        for name, change in pairs(features) do
          log(DEBUG, "enabling: " .. name)
          change:enable(config[name])
        end

    end,

    disable = function(self, config)
        return false, "not implemented"
    end,

}



