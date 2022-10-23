local entity_manager = require("control.entity_manager")
local force_manager = require("control.force_manager")
local gui = require("control.gui")

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function floats_equal(f1, f2) 
    return math.abs(f1 - f2) < 0.0000001
end

local function colors_equal(c1, c2) 
    return floats_equal(c1.r, c2.r) and floats_equal(c1.g, c2.g) and floats_equal(c1.b, c2.b) and floats_equal(c1.a, c2.a) 
end

local function check_luaforce_color_apis_exist()
    -- determine whether the luaForce.color / luaForce.custom_color APIs are available
    local base_mod_version = game.active_mods["base"]
    if not base_mod_version then
        base_mod_version = ""
    end
    local expected_prefix = "1.1."
    -- not starting with 1.1. so we just assume the new API exists since this is obviously some newer version
    if starts_with(base_mod_version, expected_prefix) == false then
        global.luaforce_color_apis_present = true
    else
        -- extract the 'patch' version number as a string
        local remaining_version_str = string.sub(base_mod_version, #expected_prefix+1)
        -- make sure what we extracted doesn't have any more dots. It shouldn't but just in case version format changes later...
        --   If this is something we don't understand, just assume the new API is present!
        if string.find(remaining_version_str, "%.") or #remaining_version_str == 0 then
            global.luaforce_color_apis_present = true
        else
            -- if version >= 1.1.64, then new API is present!
            if tonumber(remaining_version_str) >= 64 then
                global.luaforce_color_apis_present = true
            else
                global.luaforce_color_apis_present = false
            end
        end
    end
end

local function init_player(player)
    if not global.tc_player_state then
        global.tc_player_state = {}
    end
    if global.tc_player_state[player.index] == nil then
        global.tc_player_state[player.index] = {
            toggled = false,
            dirty = 0,
            last_surface_index = -1,
            last_bounding_box = {{-1, -1}, {-1, -1}},
            color = player.color
        }
    end
    if player.connected == true then
        gui.update_all()

        -- this call creates the alternative force for this player if it doesn't already exist
        force_manager.fetch_alternative_force(player.force)
    end
end

local function revert_what_we_can(base_force, alternative_force)
    local safe_to_revert_all_entities = true
    for _, player in pairs(game.players) do
        if player.connected then
            if player.force.name == alternative_force.name then
                safe_to_revert_all_entities = false
            end
        end
    end
    if safe_to_revert_all_entities then
        entity_manager.find_and_revert_all_entities(base_force, alternative_force)
    else
        entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)
    end
end

local function reset_player(player)
    if global.tc_player_state[player.index] ~= nil then
        if global.tc_player_state[player.index].toggled then
            global.tc_player_state[player.index].toggled = false
            force_manager.restore_player_original_force(player)
            gui.update_all()
            local base_force = force_manager.fetch_base_force(player.force)
            local alternative_force = force_manager.fetch_alternative_force(player.force)
            revert_what_we_can(base_force, alternative_force)
        end
    end
end

local function reset_stale_players()
    for _, player in pairs(game.players) do
        if player.connected ~= true then
            reset_player(player)
        end
    end
end

local function on_mod_init()
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        global.tc_player_state = {}
    end
    global.globally_disabled = false
    global.tc_debug = false
    global.recreate_forces = false
    global.current_mod_state_version = 2
    global.luaforce_color_apis_present = false
    check_luaforce_color_apis_exist()
    if global.tc_debug == true then
        global.tc_renders = {}
    end
    for _, player in pairs(game.players) do
        init_player(player)
    end
    force_manager.read_and_lock_force_colors()
end

local function on_player_joined(event)
    if global.globally_disabled then
        return
    end
    init_player(game.players[event.player_index])
end

local function on_player_left(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    reset_player(game.players[event.player_index])
end

local function on_research_started(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        return
    end
    force_manager.notify_research_started(event)
end

local function on_research_finished(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        return
    end
    force_manager.notify_research_finished(event)
end

local function on_player_changed_position(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player.force)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player.force)
    entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)
    entity_manager.find_and_convert_player_range_construction_entities(player, base_force, alternative_force)
end

local function on_player_changed_force(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    local player = game.players[event.player_index]
    local new_force = player.force
    local old_force = event.force

    local new_base_force = force_manager.fetch_base_force(new_force)
    local new_alternative_force = force_manager.fetch_alternative_force(new_force)
    local old_base_force = force_manager.fetch_base_force(old_force)
    local old_alternative_force = force_manager.fetch_alternative_force(old_force)

    if new_base_force.name ~= old_base_force.name or new_alternative_force.name ~= old_alternative_force.name then
        revert_what_we_can(old_base_force, old_alternative_force)
        -- reset state of feature for all players to 'off'
        for _, player in pairs(game.players) do
            reset_player(player)
        end
        force_manager.read_and_lock_force_colors()
    end
end

local function on_toggle(player)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[player.index] or not player.character then
        return
    end

    local base_force = entity_manager.force_manager.fetch_base_force(player.force)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player.force)
    if not global.tc_player_state[player.index].toggled then
        force_manager.switch_player_to_alternative_force(player)
        global.tc_player_state[player.index].toggled = true
        entity_manager.find_and_convert_player_range_construction_entities(player, base_force, alternative_force)
    else
        force_manager.restore_player_original_force(player)
        global.tc_player_state[player.index].toggled = false
        revert_what_we_can(base_force, alternative_force)
    end
end

local function on_global_disable(player)
    if global.globally_disabled then
        return
    end

    if not player.admin then
        player.print({"disable.global-disable-you-not-admin"})
        return
    end
    player.print({"disable.global-disable-starting"})

    for _, player in pairs(game.players) do
        reset_player(player)
    end
    entity_manager.garbage_collect()
    force_manager.garbage_collect(true)
    global.globally_disabled = true

    for _, player in pairs(game.players) do
        if player.connected == true then
            player.print({"disable.global-disable-complete", player.name})
        end
    end
end

local function do_recreate_alt_forces() 
    for _, player in pairs(game.players) do
        reset_player(player)
    end
    entity_manager.garbage_collect()
    force_manager.garbage_collect(true)
    global.tc_player_state = {}
    for _, player in pairs(game.players) do
        init_player(player)
    end
    global.recreate_forces = false
end

local function garbage_collect(event)
    if global.globally_disabled then
        return
    end

    reset_stale_players()
    entity_manager.garbage_collect()
    force_manager.garbage_collect(false)
    
    -- players may have changed their colors. Detect and handle that now...
    if global.luaforce_color_apis_present == true then
        local colors_need_fixing = false
        for _, player in pairs(game.players) do
            if not colors_equal(player.color, global.tc_player_state[player.index].color) then
                colors_need_fixing = true
                break
            end
        end
        
        if colors_need_fixing == true then
            -- reset state of feature for all players to 'off'
            -- necessary so we can read the 'default' force colors
            for _, player in pairs(game.players) do
                reset_player(player)
                global.tc_player_state[player.index].color = player.color
            end

            force_manager.read_and_lock_force_colors()
        end
    end
end

local function on_configuration_changed(configurationChangedData)
    if global.globally_disabled then
        return
    end

    check_luaforce_color_apis_exist()

    -- if a mod version upgrade has signaled that our alternative forces are somehow in a bad state and need re-creating
    if global.recreate_forces == true then
        do_recreate_alt_forces()
    else
        if global.luaforce_color_apis_present == true then
            -- reset state of feature for all players to 'off'
            -- necessary so we can read the 'default' force colors
            for _, player in pairs(game.players) do
                reset_player(player)
                global.tc_player_state[player.index].color = player.color
            end

            force_manager.read_and_lock_force_colors()
        end
    end
end

local function on_player_removed_from_save(player_index) 
    global.tc_player_state[player_index] = nil
    if global.luaforce_color_apis_present == true then
        -- reset state of feature for all players to 'off'
        -- necessary so we can read the 'default' force colors
        for _, player in pairs(game.players) do
            reset_player(player)
        end

        force_manager.read_and_lock_force_colors()
    end
end

script.on_init(on_mod_init)
script.on_event(defines.events.on_player_removed, on_player_removed_from_save)
script.on_event(defines.events.on_player_joined_game, on_player_joined)
script.on_event(defines.events.on_player_left_game, on_player_left)
script.on_event(defines.events.on_research_started, on_research_started)
script.on_event(defines.events.on_research_finished, on_research_finished)
script.on_event(defines.events.on_player_changed_position, on_player_changed_position)
script.on_event(defines.events.on_player_changed_force, on_player_changed_force)
script.on_event(defines.events.on_pre_player_died, on_player_left)
script.on_nth_tick(7200, garbage_collect) -- every 2 minutes-ish
script.on_configuration_changed(on_configuration_changed)
entity_manager.init(force_manager)
gui.register_events(on_toggle, on_global_disable)
